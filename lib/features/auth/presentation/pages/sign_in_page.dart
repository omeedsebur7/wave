import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_colors.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';

/// Sign-in (§1).
///
/// Apple Sign-In is not optional on iOS: App Store review rejects apps offering
/// Google Sign-In without it. It's conditional on platform rather than always
/// shown, because an Apple button on Android just confuses people.
///
/// The Terms/Privacy acceptance and minimum-age confirmation are captured here
/// as an explicit checkbox rather than an implicit "by continuing you agree"
/// line. Implicit consent is weaker legally and, more practically, means we
/// have no record of a version the user accepted (§7).
class SignInPage extends StatefulWidget {
  const SignInPage({this.returnTo, super.key});

  final String? returnTo;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _acceptedTerms = false;
  bool _confirmedAge = false;

  bool get _canProceed => _acceptedTerms && _confirmedAge;

  /// Reported on every change rather than only on submit, so the consent is
  /// already buffered by the time a provider sheet returns — which on iOS can
  /// be after this widget has been disposed.
  void _reportConsent(BuildContext context) {
    context.read<AuthBloc>().add(
          ConsentCaptured(
            acceptedTerms: _acceptedTerms,
            confirmedAge: _confirmedAge,
          ),
        );
  }

  bool get _showAppleButton =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.status != b.status || a.failure != b.failure,
      listener: (context, state) {
        if (state.status == AuthStatus.signedIn) {
          // Straight back to whatever they were trying to do — usually
          // checkout. Dropping them on the feed after signing in mid-purchase
          // is how a sale gets lost.
          context.go(widget.returnTo ?? Routes.reels);
        }
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failureText(context, state.failure!))),
          );
        }
      },
      builder: (context, state) => Scaffold(
        // Always dark, regardless of theme.
        //
        // The mark is a glow rendered on black — its halo is part of the
        // artwork, not a background effect. On a light surface the glow blends
        // into the page and the logo reads as a washed-out smear. Rather than
        // ship a second logo that is not the brand, sign-in keeps the black the
        // splash screen just handed it, so the two are continuous.
        backgroundColor: WaveColors.dark().background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.waves, size: 56, color: c.primary),
              const SizedBox(height: 16),
              Text(context.l10n.appName, style: context.texts.displayLarge),
              const SizedBox(height: 8),
              // The mark, above the tagline. Height-constrained rather than

              // width-constrained: the logo is twice as wide as it is tall, and

              // sizing by width makes it tower over the copy on a narrow phone.

              Image.asset(

                'assets/brand/logo.png',

                height: 88,

                // Decorative — the tagline underneath already says what this is, and

                // a screen reader announcing "WAVE logo, WAVE, watch and buy what you

                // see" is three ways of saying one thing.

                excludeFromSemantics: true,

              ),

              const SizedBox(height: 20),
              Text(
                context.l10n.appTagline,
                style: context.texts.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              _Consent(
                value: _acceptedTerms,
                onChanged: (v) {
                  setState(() => _acceptedTerms = v ?? false);
                  _reportConsent(context);
                },
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(context.l10n.agreeToTerms, style: context.texts.bodySmall),
                    _InlineLink(
                      label: context.l10n.termsOfService,
                      onTap: () => context.push('/legal/terms'),
                    ),
                    Text(context.l10n.andConnector, style: context.texts.bodySmall),
                    _InlineLink(
                      label: context.l10n.privacyPolicy,
                      onTap: () => context.push('/legal/privacy'),
                    ),
                  ],
                ),
              ),
              _Consent(
                value: _confirmedAge,
                onChanged: (v) {
                  setState(() => _confirmedAge = v ?? false);
                  _reportConsent(context);
                },
                child: Text(
                  context.l10n.ageConfirmation,
                  style: context.texts.bodySmall,
                ),
              ),

              const SizedBox(height: 16),

              _ProviderButton(
                icon: Icons.g_mobiledata,
                label: context.l10n.continueWithGoogle,
                enabled: _canProceed && !state.isBusy,
                onTap: () => context
                    .read<AuthBloc>()
                    .add(const GoogleSignInRequested()),
              ),
              if (_showAppleButton) ...[
                const SizedBox(height: 10),
                _ProviderButton(
                  icon: Icons.apple,
                  label: context.l10n.continueWithApple,
                  enabled: _canProceed && !state.isBusy,
                  onTap: () => context
                      .read<AuthBloc>()
                      .add(const AppleSignInRequested()),
                ),
              ],
              const SizedBox(height: 10),
              _ProviderButton(
                icon: Icons.phone_iphone,
                label: context.l10n.continueWithPhone,
                enabled: _canProceed && !state.isBusy,
                onTap: () => context.push(Routes.phoneVerify),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(Routes.accountRecovery),
                child: Text(context.l10n.forgotAccess),
              ),
              TextButton(
                // Guest browsing needs no consent checkbox — nothing is
                // collected and no account is created until they act.
                onPressed: () => context
                    .read<AuthBloc>()
                    .add(const GuestSessionRequested()),
                child: Text(context.l10n.continueAsGuest),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.guestExplainer,
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Consent extends StatelessWidget {
  const _Consent({
    required this.value,
    required this.onChanged,
    required this.child,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: child),
      ],
    );
  }
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: context.texts.bodySmall?.copyWith(
          color: context.waveColors.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
          ),
        ),
      ),
    );
  }
}
