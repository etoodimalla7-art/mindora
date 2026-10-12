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
