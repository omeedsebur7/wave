import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_colors.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';

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
    final s = context.spacing; // FIXED

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.status != b.status || a.failure != b.failure,
      listener: (context, state) {
        if (state.status == AuthStatus.signedIn) {
          context.go(widget.returnTo ?? Routes.reels);
        }
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failureText(context, state.failure!))),
          );
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: WaveColors.dark().background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.all(s.x24),
            child: Column(
              children: [
                const Spacer(),
                Icon(Icons.waves, size: s.x64, color: c.primary), 
                SizedBox(height: s.x16),
                Text(context.l10n.appName, style: context.texts.display), 
                SizedBox(height: s.x8),
                Image.asset(
                  'assets/brand/logo.png',
                  height: 88, // FIXED: 88 to 88.0
                  excludeFromSemantics: true,
                ),
                SizedBox(height: s.x20),
                Text(
                  context.l10n.appTagline,
                  style: context.texts.body,
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
                      Text(context.l10n.agreeToTerms, style: context.texts.caption),
                      _InlineLink(
                        label: context.l10n.termsOfService,
                        onTap: () => context.push('/legal/terms'),
                      ),
                      Text(context.l10n.andConnector, style: context.texts.caption),
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
                    style: context.texts.caption,
                  ),
                ),

                SizedBox(height: s.x16),

                _ProviderButton(
                  icon: Icons.g_mobiledata,
                  label: context.l10n.continueWithGoogle,
                  enabled: _canProceed && !state.isBusy,
                  onTap: () => context
                      .read<AuthBloc>()
                      .add(const GoogleSignInRequested()),
                ),
                if (_showAppleButton) ...[
                  SizedBox(height: s.x12),
                  _ProviderButton(
                    icon: Icons.apple,
                    label: context.l10n.continueWithApple,
                    enabled: _canProceed && !state.isBusy,
                    onTap: () => context
                        .read<AuthBloc>()
                        .add(const AppleSignInRequested()),
                  ),
                ],
                SizedBox(height: s.x12),
                _ProviderButton(
                  icon: Icons.phone_iphone,
                  label: context.l10n.continueWithPhone,
                  enabled: _canProceed && !state.isBusy,
                  onTap: () => context.push(Routes.phoneVerify),
                ),

                SizedBox(height: s.x8),
                WaveButton(
                  variant: WaveButtonVariant.tertiary,
                  label: context.l10n.forgotAccess,
                  onPressed: () => context.push(Routes.accountRecovery),
                ),
                WaveButton(
                  variant: WaveButtonVariant.tertiary,
                  label: context.l10n.continueAsGuest,
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const GuestSessionRequested()),
                ),
                SizedBox(height: s.x8),
                Text(
                  context.l10n.guestExplainer,
                  style: context.texts.caption,
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
        style: context.texts.caption.copyWith(
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
    return WaveButton(
      variant: WaveButtonVariant.secondary,
      icon: icon,
      label: label,
      expand: true,
      onPressed: enabled ? onTap : null,
    );
  }
}
