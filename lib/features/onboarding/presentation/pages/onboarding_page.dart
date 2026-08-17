import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/onboarding/data/onboarding_service.dart';

/// First-run walkthrough with permission priming (§1).
///
/// The critical detail: this screen NEVER triggers an OS permission dialog.
///
/// On iOS a denied permission cannot be re-requested in-app — only sent to
/// Settings, which almost nobody does. So the one prompt you get is spent at
/// the moment of genuine use ("you're about to record a Reel", "something just
/// sold"), where the reason is obvious and acceptance is far higher. What
/// happens here is only explanation, so the later prompt is expected rather
/// than a surprise.
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
    // Record that the notification rationale has been shown, so the real OS
    // prompt at first use does not repeat the explanation.
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
              child: TextButton(
                // Always skippable. Trapping someone in a walkthrough to reach
                // an app they already downloaded is a poor first impression.
                onPressed: _finish,
                child: Text(context.l10n.skip),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icons[i], size: 72, color: c.primary),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          style: context.texts.displayLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.body,
                          style: context.texts.bodyMedium,
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
                        margin: const EdgeInsets.all(4),
                        width: i == _index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? c.primary : c.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
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
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: Text(
                    _isLastSlide ? context.l10n.startBrowsing : context.l10n.next,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
