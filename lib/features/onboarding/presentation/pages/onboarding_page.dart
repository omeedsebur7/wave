import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/features/onboarding/data/onboarding_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _icons = [
    Icons.play_circle_fill,
    Icons.verified,
    Icons.storefront,
  ];

  List<({String title, String body})> _slides(BuildContext context) => [
        (title: context.l10n.onboardingTitle1, body: context.l10n.onboardingBody1),
        (title: context.l10n.onboardingTitle2, body: context.l10n.onboardingBody2),
        (title: context.l10n.onboardingTitle3, body: context.l10n.onboardingBody3),
      ];

  bool get _isLastSlide => _index == _icons.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final service = getIt<OnboardingService>();
    await service.markSeen();
    await service.markPrimed(PrimedPermission.notifications);

    if (!mounted) return;
    context.go(Routes.reels);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final slides = _slides(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: WaveButton( // FIXED: TextButton -> WaveButton
                variant: WaveButtonVariant.tertiary,
                size: WaveButtonSize.sm,
                label: context.l10n.skip,
                onPressed: _finish,
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: slides.length,
                itemBuilder: (context, i) {
                  final slide = slides[i];
                  return Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: WaveSpacing.x32), // FIXED
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icons[i], size: 72, color: c.primary), // FIXED
                        const SizedBox(height: WaveSpacing.x32), // FIXED
                        Text(
                          slide.title,
                          style: context.texts.display, // FIXED
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: WaveSpacing.x12), // FIXED
                        Text(
                          slide.body,
                          style: context.texts.body, // FIXED
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Semantics(
              label: context.l10n.stepOfTotal(_index + 1, slides.length),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsetsDirectional.all(WaveSpacing.x4), // FIXED
                        width: i == _index ? WaveSpacing.x20 : WaveSpacing.x8, // FIXED
                        height: WaveSpacing.x8, // FIXED
                        decoration: BoxDecoration(
                          color: i == _index ? c.primary : c.border,
                          borderRadius: BorderRadius.circular(4), // FIXED
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsetsDirectional.all(WaveSpacing.x24), // FIXED
              child: SizedBox(
                width: double.infinity,
                child: WaveButton( // FIXED: FilledButton -> WaveButton
                  expand: true,
                  label: _isLastSlide ? context.l10n.startBrowsing : context.l10n.next,
                  onPressed: () {
                    if (_isLastSlide) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
