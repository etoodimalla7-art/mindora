import React, { useEffect, useRef, useState } from 'react';
import {
  AlertCircle,
  BookOpen,
  History,
  ImagePlus,
  Lightbulb,
  Mic,
  MicOff,
  Plus,
  Send,
  Sparkles,
  Volume2,
  X,
} from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';
import { t } from '../../lib/i18n';
import {
  buildStyleInstructionText,
  classifyMessageIntent,
  detectStyleUpdates,
  evaluateSafeMath,
  retrieveCourseContext,
} from '../../lib/mindoraEngine';
import type { ChatMessage, Conversation } from '../../types/mindora';

const EXAMPLE_PROMPTS = [
  'Explain the integrating factor method for first-order differential equations step by step.',
  'What does my course material say about wave superposition and coherence?',
  'Give me 3 practice questions on integration by parts.',
  'sqrt(144) + 8*3',
];

export const AiTutorScreen: React.FC = () => {
  const {
    user,
    language,
    documents,
    conversations,
    activeConversationId,
    setActiveConversationId,
    createConversation,
    updateConversation,
    pendingAiPrompt,
    clearPendingAiPrompt,
  } = useMindora();

  const [input, setInput] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showHistory, setShowHistory] = useState(false);
  const [socraticOverride, setSocraticOverride] = useState<boolean | null>(null);
  const [pendingImage, setPendingImage] = useState<{
    dataUrl: string;
    base64: string;
    mimeType: string;
    name: string;
  } | null>(null);
  const [listening, setListening] = useState(false);
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const activeConv: Conversation =
    conversations.find((c) => c.id === activeConversationId) ??
    conversations[0] ?? {
      id: 'conv-fallback',
      title: 'New AI Tutor Session',
      stylePreferences: {},
      messages: [],
      updatedAt: new Date().toISOString(),
    };

  const socraticActive =
    socraticOverride !== null ? socraticOverride : Boolean(activeConv.stylePreferences.socratic);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' });
  }, [activeConv.messages.length, sending]);

  const sendMessage = async (overrideText?: string) => {
    const rawText = (overrideText ?? input).trim();
    if (!rawText && !pendingImage) return;
    setError(null);

    const styleUpdates = detectStyleUpdates(rawText);
    if (socraticOverride !== null) {
      styleUpdates.socratic = socraticOverride;
    }
    const nextPrefs = { ...activeConv.stylePreferences, ...styleUpdates };

    const userMsg: ChatMessage = {
      id: `msg-u-${Date.now()}`,
      role: 'user',
      content: rawText || 'Please solve the exercise in this image.',
      createdAt: new Date().toISOString(),
      imageDataUrl: pendingImage?.dataUrl,
    };

    const nextTitle =
      activeConv.messages.length === 0 && rawText
        ? rawText.slice(0, 42) + (rawText.length > 42 ? '...' : '')
        : activeConv.title;

    const updatedWithUser: Conversation = {
      ...activeConv,
      title: nextTitle,
      stylePreferences: nextPrefs,
      messages: [...activeConv.messages, userMsg],
      updatedAt: new Date().toISOString(),
    };

    const attachedImage = pendingImage;
    if (!overrideText) setInput('');
    setPendingImage(null);
    updateConversation(updatedWithUser);

    const intent = attachedImage ? 'question' : classifyMessageIntent(rawText);

    if (intent === 'greeting') {
      const greetingReply: ChatMessage = {
        id: `msg-a-${Date.now()}`,
        role: 'assistant',
        content:
          language === 'fr'
            ? 'Bonjour ! Je suis votre tuteur MINDORA. Posez-moi une question sur vos cours, envoyez une photo d’exercice ou demandez un quiz.'
            : 'Hello! I am your MINDORA AI tutor. Ask me about your uploaded courses, upload an exercise photo, or ask for step-by-step practice.',
        createdAt: new Date().toISOString(),
        source: 'greeting',
        toolsUsed: ['intent_router'],
      };
      updateConversation({
        ...updatedWithUser,
        messages: [...updatedWithUser.messages, greetingReply],
        updatedAt: new Date().toISOString(),
      });
      return;
    }

    if (intent === 'calculator') {
      const result = evaluateSafeMath(rawText);
      if (result !== null) {
        const calcReply: ChatMessage = {
          id: `msg-a-${Date.now()}`,
          role: 'assistant',
          content: `**Result:** \`${rawText} = ${result}\``,
          createdAt: new Date().toISOString(),
          source: 'calculator',
          toolsUsed: ['calculator'],
        };
        updateConversation({
          ...updatedWithUser,
          messages: [...updatedWithUser.messages, calcReply],
          updatedAt: new Date().toISOString(),
        });
        return;
      }
    }

    setSending(true);
    try {
      const approvedDocs = documents.filter((d) => d.status === 'approved');
      const { contextText, citedDocuments } = retrieveCourseContext(rawText, approvedDocs);
      const styleInstructions = buildStyleInstructionText(nextPrefs);

      const res = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: rawText,
          history: activeConv.messages.map((m) => ({ role: m.role, content: m.content })),
          courseContext: contextText,
          styleInstructions,
          language,
          educationProfile: user?.educationProfile ?? null,
          imageBase64: attachedImage?.base64 ?? null,
          imageMimeType: attachedImage?.mimeType ?? null,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'AI Tutor request failed.');
      }

      const assistantMsg: ChatMessage = {
        id: `msg-a-${Date.now()}`,
        role: 'assistant',
        content: data.reply,
        createdAt: new Date().toISOString(),
        source: citedDocuments.length > 0 ? 'course_material' : 'general_knowledge',
        citedDocuments,
        toolsUsed: [
          ...(citedDocuments.length > 0 ? ['course_rag'] : ['general_knowledge']),
          ...(attachedImage ? ['vision'] : []),
          ...(nextPrefs.socratic ? ['socratic_mode'] : []),
        ],
      };

      updateConversation({
        ...updatedWithUser,
        messages: [...updatedWithUser.messages, assistantMsg],
        updatedAt: new Date().toISOString(),
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to reach AI Tutor.');
    } finally {
      setSending(false);
    }
  };

  useEffect(() => {
    if (pendingAiPrompt) {
      const prompt = pendingAiPrompt;
      clearPendingAiPrompt();
      void sendMessage(prompt);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pendingAiPrompt]);

  const handleImagePick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      setError('Image is too large (maximum 5 MB).');
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = String(reader.result || '');
      const base64 = dataUrl.split(',')[1] || '';
      setPendingImage({
        dataUrl,
        base64,
        mimeType: file.type || 'image/png',
        name: file.name,
      });
    };
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  const toggleVoiceInput = () => {
    type SpeechRecognitionInstance = {
      lang: string;
      interimResults: boolean;
      onresult: ((event: { results: ArrayLike<ArrayLike<{ transcript: string }>> }) => void) | null;
      onerror: (() => void) | null;
      onend: (() => void) | null;
      start: () => void;
    };
    const win = window as unknown as {
      SpeechRecognition?: new () => SpeechRecognitionInstance;
      webkitSpeechRecognition?: new () => SpeechRecognitionInstance;
    };
    const SpeechRecognitionCtor = win.SpeechRecognition || win.webkitSpeechRecognition;

    if (!SpeechRecognitionCtor) {
      setError('Voice input is not supported in this browser.');
      return;
    }

    if (listening) {
      setListening(false);
      return;
    }

    const recognition = new SpeechRecognitionCtor();
    recognition.lang = language === 'fr' ? 'fr-FR' : 'en-US';
    recognition.interimResults = false;
    recognition.onresult = (event: { results: ArrayLike<ArrayLike<{ transcript: string }>> }) => {
      const transcript = event.results[0]?.[0]?.transcript;
      if (transcript) {
        setInput((prev) => (prev ? `${prev} ${transcript}` : transcript));
      }
      setListening(false);
    };
    recognition.onerror = () => setListening(false);
    recognition.onend = () => setListening(false);
    setListening(true);
    recognition.start();
  };

  const speakText = (text: string) => {
    if (!('speechSynthesis' in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = language === 'fr' ? 'fr-FR' : 'en-US';
    window.speechSynthesis.speak(utterance);
  };

  return (
    <div className="flex flex-col h-[calc(100vh-8.5rem)] md:h-[calc(100vh-7rem)] bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl overflow-hidden">
      {/* Toolbar */}
      <div className="px-4 py-3 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2 min-w-0">
          <button
            type="button"
            onClick={() => setShowHistory((v) => !v)}
            className="p-2 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300"
            title="Conversations"
          >
            <History className="w-4 h-4" />
          </button>
          <div className="min-w-0">
            <h1 className="font-display text-sm sm:text-base font-semibold text-slate-900 dark:text-white truncate">
              {activeConv.title}
            </h1>
            <div className="text-xs text-slate-500 dark:text-slate-400">
              {activeConv.stylePreferences.depth
                ? `Style: ${activeConv.stylePreferences.depth}`
                : 'Grounded in your approved course notes'}
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={() => setSocraticOverride(!socraticActive)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium border flex items-center gap-1.5 transition-colors whitespace-nowrap ${
              socraticActive
                ? 'border-amber-500 bg-amber-50 text-amber-800 dark:bg-amber-500/15 dark:text-amber-300'
                : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300'
            }`}
          >
            <Lightbulb className="w-3.5 h-3.5" />
            <span>{t(language, 'socraticMode')}</span>
          </button>
          <button
            type="button"
            onClick={() => {
              setSocraticOverride(null);
              createConversation();
            }}
            className="px-3 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-xs font-medium text-slate-800 dark:text-slate-200 flex items-center gap-1 whitespace-nowrap"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>New chat</span>
          </button>
        </div>
      </div>

      <div className="flex-1 flex min-h-0 relative">
        {/* Conversation History Drawer */}
        {showHistory && (
          <div className="w-64 border-r border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 p-3 overflow-y-auto shrink-0 space-y-1">
            <div className="text-xs font-semibold text-slate-500 dark:text-slate-400 px-2 pb-1">
              Recent sessions
            </div>
            {conversations.map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() => {
                  setActiveConversationId(c.id);
                  setShowHistory(false);
                }}
                className={`w-full text-left px-3 py-2 rounded-lg text-xs truncate transition-colors ${
                  c.id === activeConv.id
                    ? 'bg-indigo-100 text-indigo-800 dark:bg-indigo-500/20 dark:text-indigo-200 font-semibold'
                    : 'text-slate-700 dark:text-slate-300 hover:bg-slate-200/60 dark:hover:bg-slate-800'
                }`}
              >
                {c.title}
              </button>
            ))}
          </div>
        )}

        {/* Messages Viewport */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4">
          {activeConv.messages.length === 0 ? (
            <div className="max-w-xl mx-auto py-8 text-center space-y-5">
              <div className="w-12 h-12 rounded-2xl bg-indigo-50 dark:bg-indigo-500/15 text-indigo-600 dark:text-indigo-400 flex items-center justify-center mx-auto">
                <Sparkles className="w-6 h-6" />
              </div>
              <div>
                <h2 className="font-display text-xl font-bold text-slate-900 dark:text-white">
                  Ask me anything
                </h2>
                <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">
                  I search your uploaded course materials first, solve arithmetic expressions accurately, and can read photos of handwritten or textbook exercises.
                </p>
              </div>
              <div className="space-y-2 text-left">
                {EXAMPLE_PROMPTS.map((ex) => (
                  <button
                    key={ex}
                    type="button"
                    onClick={() => setInput(ex)}
                    className="w-full p-3.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 hover:border-indigo-300 dark:hover:border-indigo-700 text-sm text-slate-800 dark:text-slate-200 flex items-center justify-between gap-2 transition-colors"
                  >
                    <span>{ex}</span>
                    <Sparkles className="w-4 h-4 text-indigo-500 shrink-0" />
                  </button>
                ))}
              </div>
            </div>
          ) : (
            activeConv.messages.map((msg) => {
              const isUser = msg.role === 'user';
              return (
                <div key={msg.id} className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[85%] sm:max-w-[75%] rounded-2xl px-4 py-3 text-sm space-y-2 ${
                      isUser
                        ? 'bg-indigo-600 text-white'
                        : 'bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100'
                    }`}
                  >
                    {msg.imageDataUrl && (
                      <img
                        src={msg.imageDataUrl}
                        alt="Attached exercise"
                        className="max-h-56 rounded-xl object-contain border border-white/20"
                      />
                    )}
                    <div className="whitespace-pre-wrap leading-relaxed">{msg.content}</div>
                    {!isUser && (
                      <div className="pt-1 flex flex-wrap items-center justify-between gap-3 text-xs text-slate-500 dark:text-slate-400 border-t border-slate-200/70 dark:border-slate-700/70">
                        <div className="flex items-center gap-1.5">
                          <BookOpen className="w-3.5 h-3.5" />
                          <span>
                            {msg.source === 'course_material'
                              ? `${t(language, 'fromCourseMaterial')}: ${(msg.citedDocuments || []).join(', ')}`
                              : msg.source === 'calculator'
                              ? t(language, 'calculatorResult')
                              : msg.source === 'greeting'
                              ? 'MINDORA Tutor'
                              : t(language, 'generalKnowledge')}
                          </span>
                        </div>
                        <button
                          type="button"
                          onClick={() => speakText(msg.content)}
                          className="inline-flex items-center gap-1 hover:text-indigo-600 dark:hover:text-indigo-400"
                          title="Read aloud"
                        >
                          <Volume2 className="w-3.5 h-3.5" />
                          <span>Listen</span>
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              );
            })
          )}

          {sending && (
            <div className="flex justify-start">
              <div className="bg-slate-100 dark:bg-slate-800 rounded-2xl px-4 py-3 text-sm text-slate-500 dark:text-slate-400">
                Thinking...
              </div>
            </div>
          )}
        </div>
      </div>

      {error && (
        <div className="mx-4 mb-2 p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 text-xs text-rose-700 dark:text-rose-300 flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
          <button type="button" onClick={() => setError(null)} className="p-1">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {pendingImage && (
        <div className="mx-4 mb-2 p-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <img src={pendingImage.dataUrl} alt={pendingImage.name} className="w-12 h-12 rounded-lg object-cover" />
            <div className="text-xs">
              <div className="font-medium text-slate-900 dark:text-white">{pendingImage.name}</div>
              <div className="text-slate-500 dark:text-slate-400">Exercise photo ready to send</div>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setPendingImage(null)}
            className="p-1.5 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Composer */}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          void sendMessage();
        }}
        className="p-3 border-t border-slate-200 dark:border-slate-800 flex items-center gap-2"
      >
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          onChange={handleImagePick}
          className="hidden"
        />
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          disabled={sending}
          title="Attach exercise photo"
          className="p-2.5 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
        >
          <ImagePlus className="w-5 h-5" />
        </button>

        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask anything, or about your course..."
          className="flex-1 px-3.5 py-2.5 rounded-xl bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-700 text-sm"
        />

        <button
          type="button"
          onClick={toggleVoiceInput}
          title="Voice input"
          className={`p-2.5 rounded-xl transition-colors ${
            listening
              ? 'bg-rose-100 text-rose-600 dark:bg-rose-500/20 dark:text-rose-300'
              : 'text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
          }`}
        >
          {listening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
        </button>

        <button
          type="submit"
          disabled={sending || (!input.trim() && !pendingImage)}
          className="p-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-40 text-white transition-colors"
          aria-label="Send message"
        >
          <Send className="w-5 h-5" />
        </button>
      </form>
    </div>
  );
};
