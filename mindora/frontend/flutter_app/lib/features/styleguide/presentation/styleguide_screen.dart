import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_radius.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/widgets.dart';

class StyleguideScreen extends StatefulWidget {
  const StyleguideScreen({super.key});

  @override
  State<StyleguideScreen> createState() => _StyleguideScreenState();
}

class _StyleguideScreenState extends State<StyleguideScreen> {
  int _tabIndex = 0;
  bool _toggle = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(theme.brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () {
              // The app's theme mode is system-driven; for the styleguide we
              // simply show the current theme. Real switching is done at OS level.
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _section('Brand', [
            Text(AppConfig.appName, style: theme.textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(AppConfig.appTagline, style: theme.textTheme.bodyMedium),
          ]),

          _section('Color Tokens', [
            _swatchRow('Brand', [
              AppPalette.brand400,
              AppPalette.brand500,
              AppPalette.brand600,
              AppPalette.brand700,
            ]),
            _swatchRow('Accent', [
              AppPalette.accent400,
              AppPalette.accent500,
              AppPalette.accent600,
            ]),
            _swatchRow('Semantic', [
              AppPalette.success,
              AppPalette.warning,
              AppPalette.danger,
              AppPalette.info,
            ]),
            _swatchRow('Neutral', [
              AppPalette.neutral100,
              AppPalette.neutral300,
              AppPalette.neutral500,
              AppPalette.neutral700,
              AppPalette.neutral900,
            ]),
          ]),

          _section('Typography', [
            _textSample('displaySmall', theme.textTheme.displaySmall),
            _textSample('headlineMedium', theme.textTheme.headlineMedium),
            _textSample('titleLarge', theme.textTheme.titleLarge),
            _textSample('bodyLarge', theme.textTheme.bodyLarge),
            _textSample('bodyMedium', theme.textTheme.bodyMedium),
            _textSample('labelLarge', theme.textTheme.labelLarge),
            _textSample('labelSmall', theme.textTheme.labelSmall),
          ]),

          _section('Buttons', [
            const AppButton(label: 'Primary', onPressed: _noop),
            const SizedBox(height: AppSpacing.md),
            const AppButton(
              label: 'Secondary',
              variant: AppButtonVariant.secondary,
              onPressed: _noop,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppButton(
              label: 'Ghost',
              variant: AppButtonVariant.ghost,
              onPressed: _noop,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppButton(
              label: 'Danger',
              variant: AppButtonVariant.danger,
              onPressed: _noop,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppButton(
              label: 'With icon',
              icon: Icons.auto_awesome,
              onPressed: _noop,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppButton(label: 'Loading', loading: true, onPressed: null),
          ]),

          _section('Chips', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppChip(label: 'Neutral'),
                AppChip(label: 'Primary', tone: AppChipTone.primary),
                AppChip(label: 'Success', tone: AppChipTone.success),
                AppChip(label: 'Warning', tone: AppChipTone.warning),
                AppChip(label: 'Danger', tone: AppChipTone.danger),
                AppChip(label: 'Info', tone: AppChipTone.info, icon: Icons.info_outline),
                AppChip(label: 'Selected', tone: AppChipTone.primary, selected: true),
              ],
            ),
          ]),

          _section('Badges', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppBadge(label: 'NEW'),
                AppBadge(label: 'PASSED', tone: AppBadgeTone.success),
                AppBadge(label: 'DUE', tone: AppBadgeTone.warning),
                AppBadge(label: 'OVERDUE', tone: AppBadgeTone.danger),
                AppBadge(label: 'INFO', tone: AppBadgeTone.info),
                AppBadge(label: 'ARCHIVED', tone: AppBadgeTone.neutral),
              ],
            ),
          ]),

          _section('Text Fields', [
            const AppTextField(
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.alternate_email,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppTextField(
              label: 'Password',
              hint: 'At least 8 characters',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppTextField(
              label: 'With error',
              hint: 'Enter a value',
              errorText: 'This field is required',
            ),
          ]),

          _section('List Tiles', [
            AppSurface(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  AppListTile(
                    title: 'Study plan',
                    subtitle: 'Mathematics · 42 days',
                    leadingIcon: Icons.calendar_today_outlined,
                    showChevron: true,
                    onTap: _noop,
                  ),
                  AppDivider(),
                  AppListTile(
                    title: 'Course documents',
                    subtitle: '12 files',
                    leadingIcon: Icons.folder_outlined,
                    showChevron: true,
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ]),

          _section('Toggle', [
            AppToggle(
              title: 'Study reminders',
              subtitle: 'Receive daily reminders',
              value: _toggle,
              onChanged: (v) => setState(() => _toggle = v),
            ),
          ]),

          _section('Tabs', [
            AppTabs(
              tabs: const ['Week', 'Month', 'Year'],
              index: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
          ]),

          _section('Progress', [
            const AppProgressBar(value: 0.62, label: 'Exam readiness'),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: AppProgressRing(
                value: 0.81,
                size: 96,
                centerLabel: Text('81%',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
          ]),

          _section('Skeleton Loading', [
            const AppSkeletonCard(),
          ]),

          _section('Surfaces', [
            const AppSurface(
              child: Text('A standard AppSurface with rounded corners and a soft shadow.'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSurface(
              padding: const EdgeInsets.all(AppSpacing.xl),
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              child: const Text('A tinted AppSurface — used for primary CTAs.'),
            ),
          ]),

          _section('Dialogs & Sheets', [
            AppButton(
              label: 'Open dialog',
              variant: AppButtonVariant.secondary,
              onPressed: () => AppDialog.show(
                context,
                title: 'Delete session?',
                message: 'This will remove the session from your plan. This action cannot be undone.',
                confirmLabel: 'Delete',
                destructive: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Open bottom sheet',
              variant: AppButtonVariant.secondary,
              onPressed: () => AppBottomSheet.show(
                context: context,
                title: 'Quick actions',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppListTile(
                      title: 'Start a study session',
                      leadingIcon: Icons.play_arrow_outlined,
                      onTap: () => Navigator.pop(context),
                    ),
                    AppListTile(
                      title: 'Take a quick quiz',
                      leadingIcon: Icons.quiz_outlined,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          _section('Empty State', [
            const SizedBox(
              height: 320,
              child: AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Nothing here yet',
                message: 'Once content exists, it will appear right here.',
              ),
            ),
          ]),

          _section('Radius Scale', [
            Row(
              children: [
                _radiusBox('sm', AppRadius.sm),
                _radiusBox('md', AppRadius.md),
                _radiusBox('lg', AppRadius.lg),
                _radiusBox('xl', AppRadius.xl),
              ],
            ),
          ]),

          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }

  static void _noop() {}

  Widget _section(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _swatchRow(String label, List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final c in colors)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textSample(String label, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
          Expanded(child: Text('The quick brown fox', style: style)),
        ],
      ),
    );
  }

  Widget _radiusBox(String label, double radius) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
