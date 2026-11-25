import React, { createContext, useContext, useMemo, useState } from "react";
import { fr } from "./fr";
import { en } from "./en";

export type Locale = "fr" | "en";
export type Dictionary = typeof fr;

interface I18nContextValue {
  locale: Locale;
  setLocale: (loc: Locale) => void;
  dict: Dictionary;
}

const I18nContext = createContext<I18nContextValue | null>(null);

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(() => {
    const saved = localStorage.getItem("mindora_admin_locale");
    return saved === "en" ? "en" : "fr";
  });

  const setLocale = (loc: Locale) => {
    setLocaleState(loc);
    localStorage.setItem("mindora_admin_locale", loc);
  };

  const value = useMemo<I18nContextValue>(
    () => ({
      locale,
      setLocale,
      dict: (locale === "en" ? en : fr) as Dictionary,
    }),
    [locale]
  );

  return React.createElement(I18nContext.Provider, { value }, children);
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error("useI18n must be used inside I18nProvider");
  return ctx;
}
