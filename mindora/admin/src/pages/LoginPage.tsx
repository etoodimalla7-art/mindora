import React, { useState } from "react";
import { KeyRound, Lock, Mail, RefreshCw, ShieldCheck } from "lucide-react";
import { useAuth } from "../lib/auth";
import { useI18n } from "../i18n";

export function LoginPage() {
  const { startAdminLogin, verifyTwoFactor, resendTwoFactor } = useAuth();
  const { dict, locale, setLocale } = useI18n();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [challengeToken, setChallengeToken] = useState<string | null>(null);
  const [challengeEmail, setChallengeEmail] = useState("");
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  const handleStep1 = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    setInfo(null);
    try {
      const chal = await startAdminLogin(email.trim(), password);
      setChallengeToken(chal.challengeToken);
      setChallengeEmail(chal.email);
      setInfo(chal.message);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  const handleStep2 = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!challengeToken) return;
    setBusy(true);
    setError(null);
    try {
      await verifyTwoFactor(challengeToken, code.trim());
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  const handleResend = async () => {
    if (!challengeToken) return;
    setBusy(true);
    setError(null);
    try {
      await resendTwoFactor(challengeToken);
      setInfo(dict.auth.codeSent);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      className="min-h-screen flex items-center justify-center p-4"
      style={{ backgroundColor: "var(--bg-base)", color: "var(--text-primary)" }}
    >
      <div
        className="w-full max-w-md rounded-2xl border p-6 sm:p-8 shadow-xl"
        style={{
          backgroundColor: "var(--bg-surface)",
          borderColor: "var(--border-subtle)",
        }}
      >
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center"
              style={{ backgroundColor: "var(--brand-soft)", color: "var(--brand)" }}
            >
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-lg font-bold">{dict.appName}</h1>
              <p className="text-xs" style={{ color: "var(--text-secondary)" }}>
                {dict.auth.title}
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setLocale(locale === "fr" ? "en" : "fr")}
            className="px-2.5 py-1 rounded-lg text-xs font-semibold border cursor-pointer"
            style={{
              backgroundColor: "var(--bg-elevated)",
              borderColor: "var(--border-subtle)",
              color: "var(--text-primary)",
            }}
          >
            {locale.toUpperCase()}
          </button>
        </div>

        <p className="text-sm mb-6" style={{ color: "var(--text-secondary)" }}>
          {challengeToken ? dict.auth.twoFactorSubtitle : dict.auth.subtitle}
        </p>

        {error && (
          <div
            role="alert"
            className="mb-4 p-3 rounded-xl text-sm border"
            style={{
              backgroundColor: "var(--danger-soft)",
              borderColor: "var(--danger)",
              color: "var(--danger)",
            }}
          >
            {error}
          </div>
        )}

        {info && (
          <div
            className="mb-4 p-3 rounded-xl text-sm border"
            style={{
              backgroundColor: "var(--info-soft)",
              borderColor: "var(--info)",
              color: "var(--info)",
            }}
          >
            {info}
          </div>
        )}

        {!challengeToken ? (
          <form onSubmit={handleStep1} className="space-y-4">
            <div>
              <label
                htmlFor="admin-email"
                className="block text-xs font-semibold mb-1.5"
                style={{ color: "var(--text-secondary)" }}
              >
                {dict.auth.email}
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 absolute left-3 top-3" style={{ color: "var(--text-muted)" }} />
                <input
                  id="admin-email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-9 pr-3 py-2.5 rounded-xl border text-sm outline-none"
                  style={{
                    backgroundColor: "var(--bg-elevated)",
                    borderColor: "var(--border-subtle)",
                    color: "var(--text-primary)",
                  }}
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="admin-password"
                className="block text-xs font-semibold mb-1.5"
                style={{ color: "var(--text-secondary)" }}
              >
                {dict.auth.password}
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 absolute left-3 top-3" style={{ color: "var(--text-muted)" }} />
                <input
                  id="admin-password"
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-9 pr-3 py-2.5 rounded-xl border text-sm outline-none"
                  style={{
                    backgroundColor: "var(--bg-elevated)",
                    borderColor: "var(--border-subtle)",
                    color: "var(--text-primary)",
                  }}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={busy}
              className="w-full py-2.5 px-4 rounded-xl text-sm font-semibold cursor-pointer transition-opacity disabled:opacity-60"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              {busy ? dict.auth.signingIn : dict.auth.signIn}
            </button>
          </form>
        ) : (
          <form onSubmit={handleStep2} className="space-y-4">
            <div className="text-xs font-mono-code" style={{ color: "var(--text-muted)" }}>
              {challengeEmail}
            </div>
            <div>
              <label
                htmlFor="admin-2fa-code"
                className="block text-xs font-semibold mb-1.5"
                style={{ color: "var(--text-secondary)" }}
              >
                {dict.auth.codeLabel}
              </label>
              <div className="relative">
                <KeyRound className="w-4 h-4 absolute left-3 top-3" style={{ color: "var(--text-muted)" }} />
                <input
                  id="admin-2fa-code"
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]{6}"
                  maxLength={6}
                  required
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
                  placeholder="000000"
                  className="w-full pl-9 pr-3 py-2.5 rounded-xl border text-base tracking-widest font-mono-code outline-none"
                  style={{
                    backgroundColor: "var(--bg-elevated)",
                    borderColor: "var(--border-subtle)",
                    color: "var(--text-primary)",
                  }}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={busy || code.length !== 6}
              className="w-full py-2.5 px-4 rounded-xl text-sm font-semibold cursor-pointer disabled:opacity-60"
              style={{ backgroundColor: "var(--brand)", color: "var(--text-primary)" }}
            >
              {busy ? dict.auth.verifying : dict.auth.verifyCode}
            </button>

            <div className="flex items-center justify-between pt-2">
              <button
                type="button"
                onClick={handleResend}
                disabled={busy}
                className="inline-flex items-center gap-1.5 text-xs font-medium cursor-pointer"
                style={{ color: "var(--brand)" }}
              >
                <RefreshCw className="w-3.5 h-3.5" />
                {dict.auth.resendCode}
              </button>
              <button
                type="button"
                onClick={() => {
                  setChallengeToken(null);
                  setCode("");
                  setError(null);
                }}
                className="text-xs cursor-pointer"
                style={{ color: "var(--text-secondary)" }}
              >
                {dict.auth.backToLogin}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
