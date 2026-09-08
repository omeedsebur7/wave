import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/l10n_extension.dart'; // FIXED: Added l10n_extension import
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';

abstract final class WaveSignInSheet {
  static Future<bool> show({
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    final result = await WaveSheet.show<bool>(
      context: context,
      title: context.l10n.signInTitle, // FIXED: Used context.l10n
      builder: (_) => _SignInBody(onSuccess: onSuccess),
    );
    return result ?? false;
  }
}

class _SignInBody extends StatefulWidget {
  const _SignInBody({this.onSuccess});
  final VoidCallback? onSuccess;

  @override
  State<_SignInBody> createState() => _SignInBodyState();
}

class _SignInBodyState extends State<_SignInBody> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _acceptedTerms = false;
  bool _confirmedAge = false;
  _PendingAction? _pending;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _consentGiven => _acceptedTerms && _confirmedAge;

  void _captureConsentIfNeeded(BuildContext context) {
    context.read<AuthBloc>().add(
          ConsentCaptured(
            acceptedTerms: _acceptedTerms,
            confirmedAge: _confirmedAge,
          ),
        );
  }

  void _requestGoogle(BuildContext context) {
    if (!_consentGiven) return;
    _captureConsentIfNeeded(context);
    setState(() => _pending = _PendingAction.google);
    context.read<AuthBloc>().add(const GoogleSignInRequested());
  }

  void _requestApple(BuildContext context) {
    if (!_consentGiven) return;
    _captureConsentIfNeeded(context);
    setState(() => _pending = _PendingAction.apple);
    context.read<AuthBloc>().add(const AppleSignInRequested());
  }

  void _requestOtp(BuildContext context) {
    if (!_consentGiven) return;
    final digits = _phoneController.text.trim();
    if (digits.isEmpty) return;
    _captureConsentIfNeeded(context);
    setState(() => _pending = _PendingAction.otp);
    context.read<AuthBloc>().add(OtpRequested('+964$digits'));
  }

  void _submitCode(BuildContext context) {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    context.read<AuthBloc>().add(
          OtpSubmitted(code, linkToExisting: false),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (prev, next) =>
          next.status == AuthStatus.signedIn && prev.status != AuthStatus.signedIn,
      listener: (context, state) {
        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        return switch (state.otpStage) {
          OtpStage.awaitingCode ||
          OtpStage.verifying ||
          OtpStage.verified =>
            _OtpEntryView(
              codeController: _codeController,
              state: state,
              onSubmit: () => _submitCode(context),
              onChangeNumber: () => context
                  .read<AuthBloc>()
                  .add(const OtpResetRequested()),
            ),
          OtpStage.idle || OtpStage.sending => _PhoneEntryView(
              phoneController: _phoneController,
              state: state,
              pending: _pending,
              acceptedTerms: _acceptedTerms,
              confirmedAge: _confirmedAge,
              onAcceptedTermsChanged: (v) =>
                  setState(() => _acceptedTerms = v ?? false),
              onConfirmedAgeChanged: (v) =>
                  setState(() => _confirmedAge = v ?? false),
              onSubmitPhone: () => _requestOtp(context),
              onGoogle: () => _requestGoogle(context),
              onApple: () => _requestApple(context),
            ),
        };
      },
    );
  }
}

enum _PendingAction { google, apple, otp }

class _PhoneEntryView extends StatelessWidget {
  const _PhoneEntryView({
    required this.phoneController,
    required this.state,
    required this.pending,
    required this.acceptedTerms,
    required this.confirmedAge,
    required this.onAcceptedTermsChanged,
    required this.onConfirmedAgeChanged,
    required this.onSubmitPhone,
    required this.onGoogle,
    required this.onApple,
  });

  final TextEditingController phoneController;
  final AuthState state;
  final _PendingAction? pending;
  final bool acceptedTerms;
  final bool confirmedAge;
  final ValueChanged<bool?> onAcceptedTermsChanged;
  final ValueChanged<bool?> onConfirmedAgeChanged;
  final VoidCallback onSubmitPhone;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final l = context.l10n; // FIXED: Used context.l10n
    final consentGiven = acceptedTerms && confirmedAge;
    final sending = state.otpStage == OtpStage.sending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: s.controlLg,
              padding: EdgeInsetsDirectional.symmetric(horizontal: s.x16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: c.borderInput),
                borderRadius: BorderRadius.circular(context.surfaces.radiusButton),
              ),
              child: Text('+964', style: t.bodyStrong),
            ),
            SizedBox(width: s.x8),
            Expanded(
              child: WaveTextField(
                label: l.phoneNumber,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                forceLtr: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        SizedBox(height: s.x16),
        if (state.failure != null) ...[
          _InlineError(failure: state.failure!),
          SizedBox(height: s.x12),
        ],
        _ConsentRow(
          value: acceptedTerms,
          onChanged: onAcceptedTermsChanged,
          label: l.acceptTerms,
        ),
        _ConsentRow(
          value: confirmedAge,
          onChanged: onConfirmedAgeChanged,
          label: l.confirmAge,
        ),
        SizedBox(height: s.x16),
        WaveButton(
          label: l.sendCode,
          expand: true,
          isLoading: sending && pending == _PendingAction.otp,
          onPressed: consentGiven && !state.isBusy ? onSubmitPhone : null,
        ),
        SizedBox(height: s.x16),
        Row(
          children: [
            Expanded(child: Divider(color: c.divider)),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: s.x12),
              child: Text(l.orContinueWith, style: t.caption),
            ),
            Expanded(child: Divider(color: c.divider)),
          ],
        ),
        SizedBox(height: s.x16),
        Row(
          children: [
            Expanded(
              child: WaveButton(
                label: 'Google',
                variant: WaveButtonVariant.secondary,
                icon: Icons.g_mobiledata,
                isLoading: state.isBusy && pending == _PendingAction.google,
                onPressed: consentGiven && !state.isBusy ? onGoogle : null,
              ),
            ),
            SizedBox(width: s.x12),
            Expanded(
              child: WaveButton(
                label: 'Apple',
                variant: WaveButtonVariant.secondary,
                icon: Icons.apple,
                isLoading: state.isBusy && pending == _PendingAction.apple,
                onPressed: consentGiven && !state.isBusy ? onApple : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OtpEntryView extends StatelessWidget {
  const _OtpEntryView({
    required this.codeController,
    required this.state,
    required this.onSubmit,
    required this.onChangeNumber,
  });

  final TextEditingController codeController;
  final AuthState state;
  final VoidCallback onSubmit;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final l = context.l10n; // FIXED: Used context.l10n
    final verifying = state.otpStage == OtpStage.verifying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.enterCodeSentToPhone, style: context.texts.body),
        SizedBox(height: s.x16),
        WaveTextField(
          label: l.verificationCode,
          controller: codeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          forceLtr: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: s.x12),
        if (state.failure != null) ...[
          _InlineError(failure: state.failure!),
          SizedBox(height: s.x12),
        ],
        WaveButton(
          label: l.verify,
          expand: true,
          isLoading: verifying,
          onPressed: verifying ? null : onSubmit,
        ),
        SizedBox(height: s.x8),
        WaveButton(
          label: l.changePhoneNumber,
          variant: WaveButtonVariant.tertiary,
          expand: true,
          onPressed: verifying ? null : onChangeNumber,
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.texts;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: context.spacing.x4),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: onChanged),
            SizedBox(width: context.spacing.x8),
            Expanded(child: Text(label, style: t.caption)),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;
    return Container(
      padding: EdgeInsetsDirectional.all(s.x12),
      decoration: BoxDecoration(
        color: c.errorSubtle,
        borderRadius: BorderRadius.circular(context.surfaces.radiusButton),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.error, size: s.x20),
          SizedBox(width: s.x8),
          Expanded(
            child: Text(
              failureText(context, failure),
              style: context.texts.caption.copyWith(color: c.error),
            ),
          ),
        ],
      ),
    );
  }
}
