import express from 'express';
import type { Request, Response } from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { GoogleGenAI, Type } from '@google/genai';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3000;
const HOST = '0.0.0.0';

function getGeminiClient(): GoogleGenAI | null {
  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) return null;
  return new GoogleGenAI({
    apiKey,
    httpOptions: {
      headers: {
        'User-Agent': 'aistudio-build',
      },
    },
  });
}

function extractErrorDetails(err: unknown): { status: number; message: string } {
  const raw = err instanceof Error ? err.message : String(err);
  if (raw.includes('API_KEY_INVALID') || raw.includes('400')) {
    return {
      status: 400,
      message: 'The configured Gemini API key appears invalid. Please check Settings > Secrets.',
    };
  }
  if (raw.includes('PERMISSION_DENIED') || raw.includes('403')) {
    return {
      status: 403,
      message: 'Gemini API permission denied. Please verify your API key in Settings > Secrets.',
    };
  }
  if (raw.includes('RESOURCE_EXHAUSTED') || raw.includes('429')) {
    return {
      status: 429,
      message: 'AI rate limit reached. Please wait a moment and try again.',
    };
  }
  return {
    status: 502,
    message: raw || 'Unable to reach AI tutor service.',
  };
}

async function createServer() {
  const app = express();
  app.use(express.json({ limit: '15mb' }));

  app.get('/api/health', (_req: Request, res: Response) => {
    res.json({
      status: 'ok',
      service: 'mindora-api',
      aiConfigured: Boolean(process.env.GEMINI_API_KEY?.trim()),
    });
  });

  app.post('/api/ai/chat', async (req: Request, res: Response) => {
    try {
      const {
        message,
        history = [],
        courseContext = '',
        styleInstructions = '',
        language = 'en',
        educationProfile = null,
        imageBase64 = null,
        imageMimeType = null,
      } = req.body ?? {};

      if ((!message || typeof message !== 'string' || !message.trim()) && !imageBase64) {
        res.status(400).json({ error: 'Please enter a message or attach an exercise image.' });
        return;
      }

      if (typeof message === 'string' && message.length > 4000) {
        res.status(400).json({ error: 'Message exceeds the 4,000-character limit.' });
        return;
      }

      const ai = getGeminiClient();
      if (!ai) {
        res.status(503).json({
          error:
            'AI service is not configured with a GEMINI_API_KEY in Settings > Secrets. Add your key to enable live AI tutoring.',
        });
        return;
      }

      const profileSummary = educationProfile
        ? `Student profile: Country=${educationProfile.country || 'N/A'}, System=${educationProfile.educationSystem || 'N/A'}, Level=${educationProfile.level || 'N/A'}, Program=${educationProfile.program || 'N/A'}, Goal=${educationProfile.goal || 'Exam preparation'}.`
        : '';

      const langInstruction =
        language === 'fr'
          ? 'Respond primarily in French unless the student asks in English.'
          : 'Respond clearly in English unless the student asks in French.';

      const groundingInstruction = courseContext
        ? `Relevant course excerpts from the student's uploaded materials are provided below. Ground your explanation in these materials first and cite the document title when used. Do not fabricate citations.\n\n--- STUDENT COURSE EXCERPTS ---\n${courseContext}\n--- END EXCERPTS ---`
        : 'No matching excerpts were found in the student’s uploaded course library. Answer using clear, accurate general academic knowledge and briefly note that this comes from general knowledge rather than their uploaded notes.';

      const systemInstruction = [
        'You are MINDORA, a calm, rigorous, encouraging AI exam-preparation tutor.',
        langInstruction,
        profileSummary,
        styleInstructions,
        groundingInstruction,
      ]
        .filter(Boolean)
        .join('\n\n');

      const recentHistory = Array.isArray(history)
        ? history.slice(-8).map((item: { role?: string; content?: string }) => ({
            role: item.role === 'assistant' ? 'model' : 'user',
            parts: [{ text: String(item.content || '') }],
          }))
        : [];

      const userParts: Array<{ text: string } | { inlineData: { mimeType: string; data: string } }> = [];
      if (imageBase64 && imageMimeType) {
        userParts.push({
          inlineData: {
            mimeType: String(imageMimeType),
            data: String(imageBase64),
          },
        });
      }
      userParts.push({
        text:
          typeof message === 'string' && message.trim()
            ? message.trim()
            : 'Please read the exercise in this image and guide me through solving it.',
      });

      const contents = [
        ...recentHistory,
        {
          role: 'user',
          parts: userParts,
        },
      ];

      const response = await ai.models.generateContent({
        model: 'gemini-4-hydrogen',
        contents,
        config: {
          systemInstruction,
        },
      });

      const reply = response.text?.trim();
      if (!reply) {
        res.status(502).json({ error: 'The AI tutor returned an empty response. Please try again.' });
        return;
      }

      res.json({ reply });
    } catch (err) {
      const { status, message } = extractErrorDetails(err);
      res.status(status).json({ error: message });
    }
  });

  app.post('/api/ai/generate-study', async (req: Request, res: Response) => {
    try {
      const { mode, subject, sourceText, count = 5, difficulty = 'medium', language = 'en' } = req.body ?? {};
      const ai = getGeminiClient();
      if (!ai) {
        res.status(503).json({
          error: 'GEMINI_API_KEY is not configured in Settings > Secrets.',
        });
        return;
      }

      const safeCount = Math.min(Math.max(Number(count) || 5, 2), 12);
      const lang = language === 'fr' ? 'French' : 'English';

      if (mode === 'flashcards') {
        const response = await ai.models.generateContent({
          model: 'gemini-4-hydrogen',
          contents: `Create ${safeCount} high-yield exam study flashcards in ${lang} for the subject "${subject}". Base them strictly on the provided material if present.\n\nMaterial:\n${String(sourceText || '').slice(0, 8000)}`,
          config: {
            responseMimeType: 'application/json',
            responseSchema: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  front: { type: Type.STRING, description: 'Clear question or term on the front of the card.' },
                  back: { type: Type.STRING, description: 'Concise, accurate answer or definition on the back.' },
                },
                required: ['front', 'back'],
              },
            },
          },
        });
        const items = JSON.parse(response.text || '[]');
        res.json({ items });
        return;
      }

      const response = await ai.models.generateContent({
        model: 'gemini-4-hydrogen',
        contents: `Create ${safeCount} ${difficulty}-difficulty multiple-choice exam questions in ${lang} for the subject "${subject}". Each question must have 4 options, 1 correct index (0-3), and a brief explanation.\n\nMaterial:\n${String(sourceText || '').slice(0, 8000)}`,
        config: {
          responseMimeType: 'application/json',
          responseSchema: {
            type: Type.ARRAY,
            items: {
              type: Type.OBJECT,
              properties: {
                prompt: { type: Type.STRING },
                options: {
                  type: Type.ARRAY,
                  items: { type: Type.STRING },
                },
                correctIndex: { type: Type.INTEGER },
                explanation: { type: Type.STRING },
              },
              required: ['prompt', 'options', 'correctIndex', 'explanation'],
            },
          },
        },
      });
      const items = JSON.parse(response.text || '[]');
      res.json({ items });
    } catch (err) {
      const { status, message } = extractErrorDetails(err);
      res.status(status).json({ error: message });
    }
  });

  if (process.env.NODE_ENV !== 'production') {
    const { createServer: createViteServer } = await import('vite');
    const vite = await createViteServer({
      server: { middlewareMode: true, hmr: false },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distDir = path.resolve(__dirname, 'dist');
    app.use(express.static(distDir));
    app.get('*', (_req: Request, res: Response) => {
      res.sendFile(path.join(distDir, 'index.html'));
    });
  }

  app.listen(PORT, HOST, () => {
    console.log(`MINDORA server listening on http://${HOST}:${PORT}`);
  });
}

createServer().catch((err) => {
  console.error('Failed to start MINDORA server:', err);
  process.exit(1);
});
