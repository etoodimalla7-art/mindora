import 'package:flutter/widgets.dart';

/// Minimal, dependency-free localization.
/// Every user-visible string in the app resolves through here.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('en'));

  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  static const supportedLocales = <Locale>[Locale('en'), Locale('fr')];

  bool get isFr => locale.languageCode == 'fr';

  String _t(String en, String fr) => isFr ? fr : en;

  // Generic
  String get continueLabel => _t('Continue', 'Continuer');
  String get skip => _t('Skip', 'Passer');
  String get back => _t('Back', 'Retour');
  String get next => _t('Next', 'Suivant');
  String get getStarted => _t('Get started', 'Commencer');
  String get finish => _t('Finish', 'Terminer');
  String get save => _t('Save', 'Enregistrer');
  String get cancel => _t('Cancel', 'Annuler');
  String get optional => _t('Optional', 'Facultatif');
  String get required => _t('Required', 'Requis');

  // Splash / brand
  String get tagline => _t('Learn smarter. Prepare better.', 'Apprenez mieux. Préparez-vous mieux.');

  // Onboarding pages (carousel)
  String get carousel1Title => _t('Study with an AI tutor', 'Étudiez avec un tuteur IA');
  String get carousel1Body => _t(
        'Ask questions, upload courses, and get explanations tuned to your level.',
        'Posez des questions, importez vos cours et recevez des explications adaptées à votre niveau.',
      );
  String get carousel2Title => _t('Plan for your exams', 'Planifiez vos examens');
  String get carousel2Body => _t(
        'Tell us your exam date and subjects. We build the roadmap for you.',
        'Indiquez la date de votre examen et vos matières. Nous construisons la feuille de route.',
      );
  String get carousel3Title => _t('See your readiness', 'Suivez votre préparation');
  String get carousel3Body => _t(
        'Track topic mastery and know exactly what to study next.',
        'Suivez votre maîtrise des sujets et sachez exactement quoi étudier ensuite.',
      );

  // Wizard steps
  String get stepAccount => _t('Create your account', 'Créez votre compte');
  String get stepAccountSub => _t(
        'This lets us save your plan and progress.',
        'Cela nous permet d\'enregistrer votre plan et vos progrès.',
      );
  String get stepLanguage => _t('Choose your language', 'Choisissez votre langue');
  String get stepLanguageSub => _t(
        'You can change this later in settings.',
        'Vous pourrez le modifier plus tard dans les paramètres.',
      );
  String get stepCountry => _t('Where do you study?', 'Où étudiez-vous ?');
  String get stepCountrySub => _t(
        'We use this to match your education system.',
        'Nous utilisons cela pour adapter votre système éducatif.',
      );
  String get stepEducationSystem => _t('Education system', 'Système éducatif');
  String get stepEducationSystemSub => _t(
        'Select the system you are enrolled in.',
        'Sélectionnez le système dans lequel vous êtes inscrit.',
      );
  String get stepLevel => _t('Education level', 'Niveau d\'études');
  String get stepLevelSub => _t(
        'This helps us calibrate explanations.',
        'Cela nous aide à calibrer les explications.',
      );
  String get stepProgram => _t('Program / class', 'Filière / classe');
  String get stepProgramSub => _t('Example: Science, Arts, Computer Engineering.',
                                 'Exemple : Sciences, Arts, Génie Informatique.');
  String get stepSubjects => _t('Your subjects', 'Vos matières');
  String get stepSubjectsSub => _t(
        'Pick the subjects you will be examined on.',
        'Sélectionnez les matières sur lesquelles vous serez évalué.',
      );
  String get stepGoal => _t('What is your goal?', 'Quel est votre objectif ?');
  String get stepGoalSub => _t(
        'Choose what you want to achieve.',
        'Choisissez ce que vous voulez accomplir.',
      );
  String get stepExamDate => _t('Target examination date', 'Date cible de l\'examen');
  String get stepExamDateSub => _t(
        'We count down to this and pace your plan.',
        'Nous comptons à rebours et rythmons votre plan.',
      );
  String get stepStudyTimes => _t('When do you prefer to study?', 'Quand préférez-vous étudier ?');
  String get stepStudyTimesSub => _t(
        'We schedule sessions inside these windows.',
        'Nous planifions les sessions dans ces plages.',
      );
  String get stepNotifications => _t('Enable reminders', 'Activer les rappels');
  String get stepNotificationsSub => _t(
        'Study reminders help you stay consistent.',
        'Les rappels vous aident à rester régulier.',
      );
  String get stepPersonalize => _t('Personalize your tutor', 'Personnalisez votre tuteur');
  String get stepPersonalizeSub => _t(
        'Choose your preferred explanation style.',
        'Choisissez votre style d\'explication préféré.',
      );
  String get stepDone => _t('You\'re all set', 'Tout est prêt');
  String get stepDoneSub => _t(
        'Your personalized dashboard is ready.',
        'Votre tableau de bord personnalisé est prêt.',
      );

  // Home
  String get goodMorning => _t('Good morning', 'Bonjour');
  String get goodAfternoon => _t('Good afternoon', 'Bon après-midi');
  String get goodEvening => _t('Good evening', 'Bonsoir');
  String get welcomeHome => _t('Welcome', 'Bienvenue');
  String get getStartedCard => _t('Get started', 'Commencer');
  String get getStartedBody => _t(
        'Tell us your exam and subjects. We will build a personalized study plan.',
        'Indiquez votre examen et vos matières. Nous créerons un plan d\'étude personnalisé.',
      );
  String get createPlan => _t('Create my study plan', 'Créer mon plan d\'étude');
  String get todaysFocus => _t('Today\'s focus', 'Focus du jour');
  String get nothingScheduled => _t('Nothing scheduled yet', 'Rien de planifié');
  String get nothingScheduledBody => _t(
        'Once you create a study plan, your daily sessions will appear here.',
        'Une fois votre plan créé, vos sessions quotidiennes apparaîtront ici.',
      );

  // Nav
  String get navHome => _t('Home', 'Accueil');
  String get navAi => _t('AI', 'IA');
  String get navPlanner => _t('Planner', 'Planificateur');
  String get navLearn => _t('Learn', 'Apprendre');
  String get navProfile => _t('Profile', 'Profil');

  // C1 — Library & Downloads
  String get libraryTitle => _t('Document library', 'Bibliothèque de documents');
  String get librarySubtitle => _t(
        'Browse approved study notes, guides, and exam sheets',
        'Parcourez les cours, fiches et annales validés',
      );
  String get searchDocumentsHint =>
      _t('Search by title or topic...', 'Rechercher par titre ou thème...');
  String get allSubjects => _t('All subjects', 'Toutes matières');
  String get allLevels => _t('All levels', 'Tous niveaux');
  String get allLanguages => _t('All languages', 'Toutes langues');
  String get noDocumentsTitle => _t('No documents found', 'Aucun document trouvé');
  String get noDocumentsBody => _t(
        'Try adjusting your filters or contribute the first resource.',
        'Ajustez vos filtres ou contribuez avec la première ressource.',
      );
  String get retry => _t('Retry', 'Réessayer');
  String get resetFilters => _t('Reset filters', 'Réinitialiser les filtres');
  String get documentDetailTitle => _t('Document', 'Document');
  String get myDownloadsTitle => _t('My downloads', 'Mes téléchargements');
  String get myDownloadsSubtitle => _t(
        'Access documents saved locally on your device',
        'Accédez aux documents enregistrés sur votre appareil',
      );
  String get noDownloadsTitle =>
      _t('No local downloads yet', 'Aucun téléchargement local');
  String get noDownloadsBody => _t(
        'Download documents from the library to read them offline anytime.',
        'Téléchargez des documents depuis la bibliothèque pour y accéder hors ligne.',
      );
  String get downloadCta => _t('Download', 'Télécharger');
  String get downloadingLabel => _t('Downloading...', 'Téléchargement...');
  String get downloadedBadge => _t('Downloaded', 'Téléchargé');
  String get freeForOwner =>
      _t('Free (your contribution)', 'Gratuit (votre contribution)');
  String downloadCostLabel(int cost) => _t(
        '$cost credit required',
        '$cost crédit requis',
      );
  String get insufficientCreditsMsg => _t(
        'Not enough credits. Contribute a document or upgrade your plan.',
        'Crédits insuffisants. Contribuez un document ou passez à un forfait.',
      );
  String get downloadSavedSuccess => _t(
        'Document downloaded and saved locally.',
        'Document téléchargé et enregistré localement.',
      );
  String get removeLocalDownload => _t('Remove local copy', 'Supprimer la copie locale');
  String get subjectLabel => _t('Subject', 'Matière');
  String get levelLabel => _t('Level', 'Niveau');
  String get languageLabel => _t('Language', 'Langue');
  String get fileSizeLabel => _t('File size', 'Taille');
  String get pagesLabel => _t('Pages', 'Pages');
  String get downloadsCountLabel => _t('Downloads', 'Téléchargements');
  String get aiSummaryLabel => _t('Summary', 'Résumé');
  String get keywordsLabel => _t('Keywords', 'Mots-clés');

  // C2 — AI Tutor & SSE Chat
  String get newConversation => _t('New conversation', 'Nouvelle conversation');
  String get conversationsHistory =>
      _t('Conversation history', 'Historique des conversations');
  String get noConversationsYet =>
      _t('No conversations yet.\nStart chatting!', 'Aucune conversation.\nPosez votre première question !');
  String get askAnythingHint =>
      _t('Ask anything, or about your course...', 'Posez une question sur votre cours...');
  String get sourcesFromDocs =>
      _t('Sources from your documents', 'Sources tirées de vos documents');
  String get reportIssue => _t('Report issue', 'Signaler un problème');
  String get reportIssueTitle =>
      _t('Report an AI response', 'Signaler un problème sur cette réponse');
  String get reportIssueSubtitle => _t(
        'Help us improve tutor accuracy and safety.',
        'Aidez-nous à améliorer la précision et la qualité du tuteur.',
      );
  String get reportDetailsHint =>
      _t('Optional details...', 'Détails supplémentaires (facultatif)...');
  String get sendReport => _t('Send report', 'Envoyer le signalement');
  String get reportSubmitted =>
      _t('Report sent. Thank you!', 'Signalement envoyé. Merci !');
  String get reportReasonInaccurate =>
      _t('Inaccurate answer', 'Réponse inexacte');
  String get reportReasonIncomplete =>
      _t('Incomplete explanation', 'Explication incomplète');
  String get reportReasonOffTopic =>
      _t('Off-topic or wrong language', 'Hors sujet ou mauvaise langue');
  String get reportReasonOther => _t('Other issue', 'Autre problème');
  String get stopGeneration => _t('Stop response', 'Arrêter la génération');

  // C3 — Mock Exams
  String get mockExamsTitle => _t('Mock exams', 'Examens blancs');
  String get createMockExamTitle => _t('Create mock exam', 'Nouvel examen blanc');
  String get questionModeLabel => _t('Question format', 'Format des questions');
  String get modeMcq => _t('MCQ', 'QCM');
  String get modeTrueFalse => _t('True / False', 'Vrai / Faux');
  String get modeMixed => _t('Mixed', 'Mixte');
  String get lockAnswer => _t('Lock answer', 'Verrouiller');
  String get answerLocked => _t('Locked', 'Verrouillée');
  String get previousLabel => _t('Previous', 'Précédent');
  String get resultsTitle => _t('Results', 'Résultats');
  String get performanceByTopic =>
      _t('Performance by topic', 'Performance par thème');
  String get detailedCorrections =>
      _t('Detailed corrections', 'Corrections détaillées');
  String get yourAnswerLabel => _t('Your answer', 'Votre réponse');
  String get correctLabel => _t('Correct', 'Réponse correcte');
  String get skippedLabel => _t('(skipped)', '(ignorée)');
  String get backToExams => _t('Back to exams', 'Retour aux examens');
  String get newExamLabel => _t('New exam', 'Nouvel examen');
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
