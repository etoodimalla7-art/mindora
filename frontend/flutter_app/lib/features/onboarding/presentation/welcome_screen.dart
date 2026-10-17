import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/feedback_service.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/design/widgets/brand_logo.dart';
import '../../../core/router/routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.school_outlined,
      title: 'Bienvenue sur MINDORA',
      description:
          'Ton tuteur personnel pour réussir tes examens. GCE, BEPC, Bac, HND, Licence — peu importe, on t\'accompagne.',
    ),
    _OnboardingData(
      icon: Icons.psychology_outlined,
      title: 'IA Tuteur Intelligent',
      description:
          'Pose tes questions, upload tes cours, et reçois des explications personnalisées en quelques secondes.',
    ),
    _OnboardingData(
      icon: Icons.trending_up,
      title: 'Suis ta Progression',
      description:
          'Mock exams, flashcards, streaks — tout ce qu\'il faut pour arriver prêt le jour J.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FeedbackService.instance.tap();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _skip() {
    FeedbackService.instance.light();
    _goToLogin();
  }

  void _goToLogin() {
    FeedbackService.instance.success();
    context.go(AppRoutes.onboarding); // Wizard 12 étapes existant
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo + skip
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandLogo(size: 36, showWordmark: true, wordmarkSize: 18),
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _WelcomePage(data: _pages[i]),
              ),
            ),

            // Dots + CTA
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'Suivant'
                            : 'Commencer',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in gradient circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.20),
                  primary.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Icon(data.icon, size: 72, color: primary),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
          const SizedBox(height: AppSpacing.xxl),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: AppSpacing.lg),

          Text(
            data.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
