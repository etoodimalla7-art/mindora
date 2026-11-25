export const en = {
  brand: "MINDORA",
  tagline: "AI Academic Tutor · Cameroon & Africa",
  nav: {
    home: "Home",
    features: "Features",
    pricing: "Pricing",
    help: "Help",
    contact: "Contact",
    downloadApk: "Download APK",
    admin: "Admin Portal",
    privacy: "Privacy",
    terms: "Terms",
  },
  hero: {
    badge: "GCE O/A-Level · BEPC · Probatoire · Baccalauréat · HND/BTS · Bachelor",
    title: "Go from “I don't know what to study” to an exact roadmap for exam mastery.",
    subtitle:
      "MINDORA unifies a Socratic AI tutor grounded in your own notes, official PDF past papers, SM-2 spaced-repetition flashcards, timed mock exams, and live study groups.",
    downloadCta: "Download Android APK",
    playStoreCta: "Google Play (Coming Soon)",
    playStoreNote: "Google Play Store and App Store listings are in review — official v1.0 Android APK is live right now.",
    exploreCta: "Explore modules",
  },
  stats: [
    { value: "9", label: "Supported exams (GCE to Master)" },
    { value: "FR / EN", label: "100% bilingual curriculum & UI" },
    { value: "SM-2", label: "Science-backed spaced repetition" },
    { value: "Offline", label: "Past papers & study cache offline" },
  ],
  features: {
    title: "Everything built for top exam results",
    subtitle: "Engineered to global EdTech benchmarks and tailored for Cameroonian and Pan-African exam boards.",
    items: [
      {
        title: "Socratic AI Tutor & Vision",
        desc: "Ask by text, voice, or exercise photo: your tutor cites your own course materials and guides you step-by-step.",
      },
      {
        title: "Official Past Papers Vault",
        desc: "Download GCE, BEPC, Probatoire, Baccalauréat, and HND/BTS PDFs with tracked progress.",
      },
      {
        title: "Server-Graded Mock Exams",
        desc: "Timed exam simulations with rigorous server-side grading, post-submit explanations, and topic analytics.",
      },
      {
        title: "Adaptive SM-2 Flashcards",
        desc: "Long-term memory scheduling powered by the SM-2 algorithm calibrated to your recall ratings.",
      },
      {
        title: "Smart Revision Planner",
        desc: "Daily study sessions automatically prioritized by exam countdown and subject mastery.",
      },
      {
        title: "Study Groups & Peer Help",
        desc: "Subject rooms and real-time direct messaging to revise collaboratively.",
      },
    ],
  },
  pricing: {
    title: "Simple, student-friendly pricing",
    subtitle: "Start free and unlock unlimited AI tutoring and mock exams via Mobile Money or card on Flutterwave.",
    freeTitle: "Free — Starter",
    freePrice: "0 XAF",
    freePeriod: "/ month",
    freeFeatures: [
      "Smart revision planner access",
      "Public past papers browsing",
      "10 starter AI credits included",
      "SM-2 flashcards & study groups",
    ],
    proCta: "Activate in Android App",
    popularBadge: "Popular",
    fallbackPlans: [
      {
        code: "monthly_pro",
        name: "MINDORA Pro Monthly",
        price_xaf: 2500,
        duration_days: 30,
        features: [
          "Unlimited AI Tutor & Vision",
          "Unlimited timed mock exams & detailed corrections",
          "Unlimited offline PDF past paper downloads",
          "Priority student support",
        ],
      },
      {
        code: "annual_pro",
        name: "MINDORA Pro Annual",
        price_xaf: 20000,
        duration_days: 365,
        features: [
          "Full Pro access for 12 months",
          "Save over 33% across the academic year",
          "Early access to HND & University question banks",
          "Excellence analytics & priority queue",
        ],
      },
    ],
  },
  help: {
    title: "Help Center & APK Installation",
    subtitle: "Quick answers to install MINDORA on Android and organize your exam preparation.",
    faqs: [
      {
        q: "How do I install the MINDORA Android APK?",
        a: "Tap “Download APK”, open app-debug.apk from your Downloads folder, and allow installation from your browser when prompted by Android.",
      },
      {
        q: "Does MINDORA support both English and French systems?",
        a: "Yes. Switch effortlessly between English and French to study GCE O/A-Level, HND, or Francophone BEPC, Probatoire, and Baccalauréat tracks.",
      },
      {
        q: "Can I study with an unstable internet connection?",
        a: "Yes. Synced study sessions, past papers, and flashcards are cached locally on Android and synchronize once back online.",
      },
      {
        q: "How is my personal data protected?",
        a: "Tokens are encrypted on-device, exam grading runs server-side, and you can export or schedule account deletion anytime from Profile.",
      },
    ],
  },
  privacy: {
    title: "Privacy Policy",
    updated: "Last updated: November 2026",
    sections: [
      {
        heading: "1. Data we collect",
        body: "We only store data essential for your study experience: email, name, education system, level, uploaded course materials, and practice performance.",
      },
      {
        heading: "2. Security & encryption",
        body: "Passwords are securely hashed, transport uses HTTPS/TLS, and administrator accounts enforce mandatory two-factor authentication (2FA).",
      },
      {
        heading: "3. Your rights (Export & Deletion)",
        body: "From the mobile Profile screen, you can export a full JSON archive of your data or request complete account deletion.",
      },
    ],
  },
  terms: {
    title: "Terms of Service",
    updated: "Last updated: November 2026",
    sections: [
      {
        heading: "1. Service scope",
        body: "MINDORA provides academic study tools, revision scheduling, and practice assessments strictly for personal educational use.",
      },
      {
        heading: "2. Shared materials",
        body: "User-submitted study documents undergo moderation prior to public indexing to uphold academic quality.",
      },
      {
        heading: "3. Subscriptions & billing",
        body: "Paid plans are processed securely via Flutterwave and activated immediately upon payment verification.",
      },
    ],
  },
  contact: {
    title: "Contact the MINDORA Team",
    subtitle: "Questions about your school, technical support, or partnerships? Reach us directly.",
    name: "Full name",
    email: "Email address",
    category: "Topic",
    subject: "Subject",
    message: "Your message",
    send: "Send message",
    sending: "Sending...",
    successPrefix: "Message logged under support ticket #",
    categories: [
      { value: "general", label: "General inquiry" },
      { value: "technical", label: "Technical / APK support" },
      { value: "school", label: "School partnership" },
      { value: "billing", label: "Billing & subscriptions" },
    ],
  },
  footer: {
    rights: "© 2026 MINDORA. EdTech platform built for academic excellence.",
    apkVersion: "Direct Android Build",
  },
} as const;
