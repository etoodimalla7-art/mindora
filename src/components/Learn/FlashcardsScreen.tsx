import React, { useMemo, useState } from 'react';
import { ArrowLeft, Layers, Plus, RotateCw, Sparkles } from 'lucide-react';
import { useMindora } from '../../context/MindoraContext';

export const FlashcardsScreen: React.FC = () => {
  const { decks, flashcards, documents, createFlashcardDeck, reviewFlashcard, setSubView } = useMindora();
  const [activeDeckId, setActiveDeckId] = useState<string | null>(null);
  const [cardIndex, setCardIndex] = useState(0);
  const [showBack, setShowBack] = useState(false);

  const [showCreate, setShowCreate] = useState(false);
  const [title, setTitle] = useState('');
  const [subject, setSubject] = useState('Mathematics');
  const [selectedDocId, setSelectedDocId] = useState(documents[0]?.id ?? '');
  const [customText, setCustomText] = useState('');
  const [useAi, setUseAi] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [genError, setGenError] = useState<string | null>(null);

  const activeCards = useMemo(() => {
    if (!activeDeckId) return [];
    return flashcards.filter((c) => c.deckId === activeDeckId);
  }, [flashcards, activeDeckId]);

  const currentCard = activeCards[cardIndex] ?? null;

  const handleCreateDeck = async (e: React.FormEvent) => {
    e.preventDefault();
    setGenError(null);
    const doc = documents.find((d) => d.id === selectedDocId);
    const sourceText = customText.trim() || (doc ? `${doc.description}\n${doc.contentText}` : '');

    if (useAi) {
      setGenerating(true);
      try {
        const res = await fetch('/api/ai/generate-study', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            mode: 'flashcards',
            subject,
            sourceText,
            count: 6,
          }),
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'AI generation failed.');
        createFlashcardDeck({
          title: title.trim() || `${subject} AI Flashcards`,
          subject,
          sourceText,
          cards: data.items,
        });
        setShowCreate(false);
        setTitle('');
        setCustomText('');
      } catch (err) {
        setGenError(err instanceof Error ? err.message : 'Unable to generate flashcards with AI.');
      } finally {
        setGenerating(false);
      }
      return;
    }

    createFlashcardDeck({
      title: title.trim() || `${subject} Study Deck`,
      subject,
      sourceText,
    });
    setShowCreate(false);
    setTitle('');
    setCustomText('');
  };

  if (activeDeckId) {
    const deck = decks.find((d) => d.id === activeDeckId);
    return (
      <div className="max-w-2xl mx-auto space-y-6">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => {
                setActiveDeckId(null);
                setCardIndex(0);
                setShowBack(false);
              }}
              className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              <ArrowLeft className="w-4 h-4" />
            </button>
            <div>
              <h1 className="font-display text-lg font-bold text-slate-900 dark:text-white">
                {deck?.title || 'Flashcard Review'}
              </h1>
              <div className="text-xs text-slate-500 dark:text-slate-400 font-mono tabular-nums">
                {activeCards.length > 0 ? `Card ${cardIndex + 1} of ${activeCards.length}` : '0 cards'}
              </div>
            </div>
          </div>
        </div>

        {!currentCard ? (
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-10 text-center space-y-3">
            <div className="font-display text-lg font-semibold text-slate-900 dark:text-white">
              Review queue complete
            </div>
            <button
              type="button"
              onClick={() => setActiveDeckId(null)}
              className="px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold"
            >
              Back to decks
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            <button
              type="button"
              onClick={() => setShowBack((v) => !v)}
              className="w-full min-h-[260px] bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-8 flex flex-col items-center justify-center text-center gap-4 hover:border-indigo-300 dark:hover:border-indigo-700 transition-colors"
            >
              <div className="text-xs font-semibold text-indigo-600 dark:text-indigo-400">
                {showBack ? 'Answer' : 'Question · Tap to flip'}
              </div>
              <div className="font-display text-xl font-semibold text-slate-900 dark:text-white max-w-lg">
                {showBack ? currentCard.back : currentCard.front}
              </div>
              <div className="text-xs text-slate-400 font-mono tabular-nums">
                Ease {currentCard.easeFactor} · Interval {currentCard.intervalDays}d
              </div>
            </button>

            {!showBack ? (
              <button
                type="button"
                onClick={() => setShowBack(true)}
                className="w-full py-3 rounded-xl border border-slate-300 dark:border-slate-700 text-sm font-semibold flex items-center justify-center gap-2 hover:bg-slate-50 dark:hover:bg-slate-800"
              >
                <RotateCw className="w-4 h-4" />
                <span>Reveal answer</span>
              </button>
            ) : (
              <div className="grid grid-cols-3 gap-3">
                {[
                  { label: 'Hard (1d)', quality: 1, cls: 'border-rose-300 text-rose-700 dark:border-rose-800 dark:text-rose-300 hover:bg-rose-50 dark:hover:bg-rose-950/30' },
                  { label: 'Good', quality: 3, cls: 'border-amber-300 text-amber-700 dark:border-amber-800 dark:text-amber-300 hover:bg-amber-50 dark:hover:bg-amber-950/30' },
                  { label: 'Easy', quality: 5, cls: 'bg-emerald-600 text-white hover:bg-emerald-700 border-emerald-600' },
                ].map((btn) => (
                  <button
                    key={btn.label}
                    type="button"
                    onClick={() => {
                      reviewFlashcard(currentCard.id, btn.quality);
                      if (cardIndex < activeCards.length - 1) {
                        setCardIndex((i) => i + 1);
                        setShowBack(false);
                      } else {
                        setActiveDeckId(null);
                        setCardIndex(0);
                        setShowBack(false);
                      }
                    }}
                    className={`py-3 px-4 rounded-xl border text-sm font-semibold transition-colors ${btn.cls}`}
                  >
                    {btn.label}
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setSubView({ type: 'none' })}
            className="p-2 rounded-lg border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <div>
            <h1 className="font-display text-2xl font-bold text-slate-900 dark:text-white">Flashcards</h1>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              SM-2 spaced repetition decks generated from your courses.
            </p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setShowCreate((v) => !v)}
          className="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold inline-flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          <span>Generate deck</span>
        </button>
      </div>

      {showCreate && (
        <form
          onSubmit={handleCreateDeck}
          className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 space-y-4"
        >
          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium mb-1">Deck title</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Wave Optics Definitions"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Subject</label>
              <input
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium mb-1">Source course document</label>
            <select
              value={selectedDocId}
              onChange={(e) => setSelectedDocId(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            >
              {documents.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.title} ({d.subject})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-medium mb-1">Or paste custom study notes (optional)</label>
            <textarea
              rows={3}
              value={customText}
              onChange={(e) => setCustomText(e.target.value)}
              placeholder="Paste definitions like 'Enthalpy is the total heat content of a system...'"
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-950 text-sm"
            />
          </div>

          <label className="flex items-center gap-2 text-xs font-medium text-slate-700 dark:text-slate-300 cursor-pointer">
            <input
              type="checkbox"
              checked={useAi}
              onChange={(e) => setUseAi(e.target.checked)}
              className="rounded border-slate-300 text-indigo-600"
            />
            <Sparkles className="w-3.5 h-3.5 text-indigo-500" />
            <span>Use Gemini AI generator (requires GEMINI_API_KEY; unchecked uses instant local definition extractor)</span>
          </label>

          {genError && <p className="text-xs text-rose-600 dark:text-rose-400">{genError}</p>}

          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setShowCreate(false)}
              className="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 text-sm"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={generating}
              className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold disabled:opacity-50"
            >
              {generating ? 'Generating...' : 'Create deck'}
            </button>
          </div>
        </form>
      )}

      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {decks.map((deck) => {
          const cards = flashcards.filter((c) => c.deckId === deck.id);
          const known = cards.filter((c) => c.lastState === 'known').length;
          return (
            <button
              key={deck.id}
              type="button"
              onClick={() => {
                setActiveDeckId(deck.id);
                setCardIndex(0);
                setShowBack(false);
              }}
              className="p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 text-left space-y-3 transition-colors"
            >
              <div className="flex items-center justify-between">
                <Layers className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                <span className="text-xs text-slate-500 dark:text-slate-400">{deck.subject}</span>
              </div>
              <div className="font-display font-semibold text-base text-slate-900 dark:text-white">
                {deck.title}
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400 font-mono tabular-nums">
                {cards.length} cards · {known} known
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};
