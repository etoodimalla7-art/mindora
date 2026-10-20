import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/widgets.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/routes.dart';
import '../../../l10n/app_strings.dart';
import '../../auth/presentation/auth_controller.dart';

// =============================================================
// Draft state
// =============================================================

class OnboardingDraft {
  const OnboardingDraft({
    this.languageCode = 'en',
    this.countryCode = 'CM',
    this.educationSystem,
    this.level,
    this.program,
    this.subjects = const [],
    this.goal,
    this.targetExamDate,
    this.studyWindows = const [],
    this.explanationStyle,
    this.allowNotifications = true,
  });

  final String languageCode;
  final String countryCode;
  final String? educationSystem;
  final String? level;
  final String? program;
  final List<String> subjects;
  final String? goal;
  final DateTime? targetExamDate;
  final List<String> studyWindows;
  final String? explanationStyle;
  final bool allowNotifications;

  OnboardingDraft copyWith({
    String? languageCode,
    String? countryCode,
    String? educationSystem,
    String? level,
    String? program,
    List<String>? subjects,
    String? goal,
    DateTime? targetExamDate,
    List<String>? studyWindows,
    String? explanationStyle,
    bool? allowNotifications,
  }) =>
      OnboardingDraft(
        languageCode: languageCode ?? this.languageCode,
        countryCode: countryCode ?? this.countryCode,
        educationSystem: educationSystem ?? this.educationSystem,
        level: level ?? this.level,
        program: program ?? this.program,
        subjects: subjects ?? this.subjects,
        goal: goal ?? this.goal,
        targetExamDate: targetExamDate ?? this.targetExamDate,
        studyWindows: studyWindows ?? this.studyWindows,
        explanationStyle: explanationStyle ?? this.explanationStyle,
        allowNotifications: allowNotifications ?? this.allowNotifications,
      );
}

class OnboardingController extends StateNotifier<OnboardingDraft> {
  OnboardingController() : super(const OnboardingDraft());
  void update(OnboardingDraft draft) => state = draft;
}

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingDraft>(
  (_) => OnboardingController(),
);

// =============================================================
// Step catalogue
// =============================================================

enum _Step {
  language,
  country,
  educationSystem,
  level,
  program,
  subjects,
  goal,
  examDate,
  studyTimes,
  notifications,
  personalize,
  done,
}

extension on _Step {
  String title(AppStrings s) => switch (this) {
        _Step.language => s.stepLanguage,
        _Step.country => s.stepCountry,
        _Step.educationSystem => s.stepEducationSystem,
        _Step.level => s.stepLevel,
        _Step.program => s.stepProgram,
        _Step.subjects => s.stepSubjects,
        _Step.goal => s.stepGoal,
        _Step.examDate => s.stepExamDate,
        _Step.studyTimes => s.stepStudyTimes,
        _Step.notifications => s.stepNotifications,
        _Step.personalize => s.stepPersonalize,
        _Step.done => s.stepDone,
      };

  String subtitle(AppStrings s) => switch (this) {
        _Step.language => s.stepLanguageSub,
        _Step.country => s.stepCountrySub,
        _Step.educationSystem => s.stepEducationSystemSub,
        _Step.level => s.stepLevelSub,
        _Step.program => s.stepProgramSub,
        _Step.subjects => s.stepSubjectsSub,
        _Step.goal => s.stepGoalSub,
        _Step.examDate => s.stepExamDateSub,
        _Step.studyTimes => s.stepStudyTimesSub,
        _Step.notifications => s.stepNotificationsSub,
        _Step.personalize => s.stepPersonalizeSub,
        _Step.done => s.stepDoneSub,
      };
}

// =============================================================
// Screen
// =============================================================

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {

  /// Filtre dynamique des étapes selon les réponses de l'utilisateur.
  List<_Step> get _visibleSteps {
    final draft = ref.read(onboardingProvider);
    return _Step.values.where((step) {
      // Skip "subjects" si niveau universitaire
      if (step == _Step.subjects) {
        final univLevels = ['hnd', 'master', 'bachelor', 'licence'];
        return !univLevels.contains(draft.level);
      }
      // Skip "program" si niveau GCE (matières fixes)
      if (step == _Step.program) {
        final gceLevels = ['gce_o', 'gce_a', 'ordinary_level', 'advanced_level'];
        return !gceLevels.contains(draft.level);
      }
      // Skip "examDate" si goal n'est pas un examen
      if (step == _Step.examDate) {
        return draft.goal == null || draft.goal == 'pass_exam';
      }
      return true;
    }).toList();
  }
  int _index = 0;
  bool _submitting = false;

  // Controllers for the account step. Kept at the screen level so the
  // Finish action can access the credentials the user typed.
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  void _next() async {
    if (_index < _visibleSteps.length - 1) {
      setState(() => _index++);
      return;
    }



    setState(() => _submitting = true);
    try {
      final draft = ref.read(onboardingProvider);

      // 1. Create the account.
      final auth = ref.read(authControllerProvider.notifier);
      final ok = await auth.register(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim().isEmpty ? null : _fullName.text.trim(),
        preferredLanguage: draft.languageCode,
        countryCode: draft.countryCode,
      );

      if (!ok) {
        final err = ref.read(authControllerProvider).error ?? 'Registration failed.';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }

      // 2. Save the education profile now that we have a token.
      await _submit(draft);

      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not save your preferences. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit(OnboardingDraft d) async {
    // Only hit the API if the user is authenticated. In Phase 3.x the wizard
    // will create the account first; for now we try and swallow the 401.
    final dio = ref.read(dioProvider);
    try {
      await dio.put('/users/me/education', data: {
        'education_system': d.educationSystem,
        'level': d.level,
        'program': d.program,
        'subjects': d.subjects,
        'goals': d.goal != null ? [d.goal] : <String>[],
        'study_preferences': {
          'studyWindows': d.studyWindows,
          'explanationStyle': d.explanationStyle,
          'notifications': d.allowNotifications,
        },
        'target_exam_date':
            d.targetExamDate?.toIso8601String().substring(0, 10),
      });
    } catch (_) {
      // User not signed in yet; ignore. Phase 3 wires the account creation.
    }
  }

  /// Skip toutes les étapes restantes et va à la dernière.
  void _skipToEnd() {
    setState(() => _index = _visibleSteps.length - 1);
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final step = _visibleSteps[_index];
    final progress = (_index + 1) / _visibleSteps.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_index > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: s.back,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  TextButton(
                    onPressed: _submitting ? null : _skipToEnd,
                    child: Text(s.skip),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 240),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(s.skip),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(step.title(s),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                step.subtitle(s),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: _buildStep(step)),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _index == _visibleSteps.length - 1 ? s.finish : s.continueLabel,
                loading: _submitting,
                onPressed: _submitting ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_Step step) => switch (step) {
        _Step.language => _StepLanguage(),
        _Step.country => _StepCountry(),
        _Step.educationSystem => _StepEducationSystem(),
        _Step.level => _StepLevel(),
        _Step.program => _StepProgram(),
        _Step.subjects => _StepSubjects(),
        _Step.goal => _StepGoal(),
        _Step.examDate => _StepExamDate(),
        _Step.studyTimes => _StepStudyTimes(),
        _Step.notifications => _StepNotifications(),
        _Step.personalize => _StepPersonalize(),
        _Step.done => _StepDone(),
      };
}

// =============================================================
// Reusable building blocks
// =============================================================

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.6),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceList extends ConsumerWidget {
  const _ChoiceList({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.multiSelect = false,
    this.selectedList = const [],
  });

  final List<(String value, String label, String? sub)> options;
  final String? selected;
  final void Function(String value) onSelected;
  final bool multiSelect;
  final List<String> selectedList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final (value, label, sub) = options[i];
        final isSelected = multiSelect
            ? selectedList.contains(value)
            : selected == value;

        return _Tile(
          title: label,
          subtitle: sub,
          selected: isSelected,
          onTap: () => onSelected(value),
        );
      },
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: EdgeInsets.zero, children: children);
}

// =============================================================
// Individual steps
// =============================================================

class _StepLanguage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    final current = ref.watch(localeProvider);

    return _ChoiceList(
      options: const [
        ('en', 'English', 'Continue in English'),
        ('fr', 'Français', 'Continuer en français'),
      ],
      selected: current.languageCode,
      onSelected: (code) {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        ctrl.update(draft.copyWith(languageCode: code));
      },
    );
  }
}

class _StepCountry extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    return _ChoiceList(
      options: const [
        ('CM', 'Cameroon', 'Cameroun'),
        ('NG', 'Nigeria', null),
        ('GH', 'Ghana', null),
      ],
      selected: draft.countryCode,
      onSelected: (code) => ctrl.update(draft.copyWith(countryCode: code)),
    );
  }
}

class _StepEducationSystem extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    return _ChoiceList(
      options: const [
        ('GCE', 'GCE', 'Anglophone system'),
        ('FRANCOPHONE', 'Francophone', 'Système francophone'),
      ],
      selected: draft.educationSystem,
      onSelected: (v) => ctrl.update(draft.copyWith(educationSystem: v)),
    );
  }
}

class _StepLevel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    final isAnglophone = draft.educationSystem == 'anglophone';

    final options = isAnglophone
        ? const [
            ('gce_o', 'GCE Ordinary Level'),
            ('gce_a', 'GCE Advanced Level'),
            ('hnd', 'HND'),
            ('bachelor', 'Bachelor'),
            ('master', 'Master'),
          ]
        : const [
            ('bepc', 'BEPC'),
            ('probatoire', 'Probatoire'),
            ('bac', 'Baccalauréat'),
            ('bts', 'BTS'),
            ('licence', 'Licence'),
            ('master_fr', 'Master'),
          ];

    return _ChoiceList(
      options: options.map((o) => (o.$1, o.$2, '')).toList(),
      selected: draft.level,
      onSelected: (val) => ctrl.update(draft.copyWith(level: val)),
    );
  }
}

class _StepProgram extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StepProgram> createState() => _StepProgramState();
}

class _StepProgramState extends ConsumerState<_StepProgram> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: ref.read(onboardingProvider).program);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(children: [
      TextField(
        controller: _c,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Example: Science, Arts, Computer Engineering',
          prefixIcon: Icon(Icons.school_outlined),
        ),
        onChanged: (v) => ref
            .read(onboardingProvider.notifier)
            .update(ref.read(onboardingProvider).copyWith(program: v)),
      ),
    ]);
  }
}

class _StepSubjects extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StepSubjects> createState() => _StepSubjectsState();
}

class _StepSubjectsState extends ConsumerState<_StepSubjects> {
  final _customSubject = TextEditingController();
  bool _showCustomField = false;

  @override
  void dispose() {
    _customSubject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    final current = List<String>.from(draft.subjects);

    return Column(
      children: [
        Expanded(
          child: _ChoiceList(
            options: const [
              ('mathematics', 'Mathematics', ''),
              ('physics', 'Physics', ''),
              ('chemistry', 'Chemistry', ''),
              ('biology', 'Biology', ''),
              ('computer_science', 'Computer Science', ''),
              ('economics', 'Economics', ''),
              ('accounting', 'Accounting', ''),
              ('english', 'English', ''),
              ('french', 'French', ''),
              ('history', 'History', ''),
              ('geography', 'Geography', ''),
            ],
            selected: null, // multiple
            onSelected: (val) {
              if (current.contains(val)) {
                current.remove(val);
              } else {
                current.add(val);
              }
              ctrl.update(draft.copyWith(subjects: current));
            },
            multiSelect: true,
            selectedList: current,
          ),
        ),
        const SizedBox(height: 8),
        if (_showCustomField)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customSubject,
                    decoration: const InputDecoration(
                      hintText: 'Type your subject',
                    ),
                    onSubmitted: (val) {
                      if (val.isNotEmpty) {
                        current.add(val);
                        ctrl.update(draft.copyWith(subjects: current));
                        _customSubject.clear();
                        setState(() => _showCustomField = false);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    if (_customSubject.text.isNotEmpty) {
                      current.add(_customSubject.text);
                      ctrl.update(draft.copyWith(subjects: current));
                      _customSubject.clear();
                      setState(() => _showCustomField = false);
                    }
                  },
                ),
              ],
            ),
          )
        else
          TextButton(
            onPressed: () => setState(() => _showCustomField = true),
            child: const Text('+ Other subject'),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StepGoal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    return _ChoiceList(
      options: const [
        ('pass_exam', 'Pass my examination', null),
        ('improve_grades', 'Improve my grades', null),
        ('learn_deeply', 'Learn deeply', null),
        ('short_revision', 'Quick revision', null),
      ],
      selected: draft.goal,
      onSelected: (v) => ctrl.update(draft.copyWith(goal: v)),
    );
  }
}

class _StepExamDate extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StepExamDate> createState() => _StepExamDateState();
}

class _StepExamDateState extends ConsumerState<_StepExamDate> {
  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    final date = draft.targetExamDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurface(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.event_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  date == null
                      ? 'No date selected yet'
                      : DateFormat.yMMMMd().format(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: date == null ? 'Pick a date' : 'Change date',
          icon: Icons.calendar_today_outlined,
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? now.add(const Duration(days: 90)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365 * 5)),
            );
            if (picked != null) ctrl.update(draft.copyWith(targetExamDate: picked));
          },
        ),
      ],
    );
  }
}

class _StepStudyTimes extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    final options = const [
      ('morning', 'Morning (6am–11am)', null),
      ('afternoon', 'Afternoon (11am–5pm)', null),
      ('evening', 'Evening (5pm–9pm)', null),
      ('night', 'Night (9pm–12am)', null),
    ];
    final selected = draft.studyWindows.toSet();

    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final (v, label, _) = options[i];
        final on = selected.contains(v);
        return _Tile(
          title: label,
          selected: on,
          onTap: () {
            final next = {...selected};
            on ? next.remove(v) : next.add(v);
            ctrl.update(draft.copyWith(studyWindows: next.toList()));
          },
        );
      },
    );
  }
}

class _StepNotifications extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    return Column(
      children: [
        SwitchListTile(
          value: draft.allowNotifications,
          onChanged: (v) => ctrl.update(draft.copyWith(allowNotifications: v)),
          title: const Text('Enable study reminders'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _StepPersonalize extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    return _ChoiceList(
      options: const [
        ('concise', 'Concise', 'Short, direct answers'),
        ('standard', 'Standard', 'Balanced explanations'),
        ('detailed', 'Detailed', 'Step-by-step depth'),
        ('socratic', 'Socratic', 'Guided questions'),
      ],
      selected: draft.explanationStyle,
      onSelected: (v) => ctrl.update(draft.copyWith(explanationStyle: v)),
    );
  }
}

class _StepDone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline,
                size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Your plan is ready.',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Finish to open your dashboard.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Account step — creates the user or routes to login
class _StepAccount extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StepAccount> createState() => _StepAccountState();
}

class _StepAccountState extends ConsumerState<_StepAccount> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final parent = context
        .findAncestorStateOfType<_OnboardingScreenState>()!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AppTextField(
          controller: parent._fullName,
          label: 'Full name',
          hint: 'Jane Doe',
          prefixIcon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: parent._email,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.alternate_email,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: parent._password,
          label: 'Password',
          hint: 'At least 8 characters',
          obscureText: _obscure,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Password must be at least 8 characters.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('I already have an account'),
          ),
        ),
      ],
    );
  }
}
