import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';

enum PhoneVerifyReason {
  signIn,
  checkoutGate,
  recovery,
}

class PhoneVerifyPage extends StatefulWidget {
  const PhoneVerifyPage({required this.reason, this.returnTo, super.key});

  final PhoneVerifyReason reason;
  final String? returnTo;

  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  bool get _isGate => widget.reason == PhoneVerifyReason.checkoutGate;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (widget.reason) {
            PhoneVerifyReason.checkoutGate => context.l10n.oneQuickStep,
            PhoneVerifyReason.recovery => context.l10n.recoverAccount,
            PhoneVerifyReason.signIn => context.l10n.signIn,
          },
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.otpStage == OtpStage.verified) {
            if (widget.returnTo != null) {
              context.go(widget.returnTo!);
            } else {
              context.pop();
            }
          }
          if (state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failureText(context, state.failure!))),
            );
          }
        },
        builder: (context, state) {
          final awaitingCode = state.otpStage == OtpStage.awaitingCode ||
              state.otpStage == OtpStage.verifying;

          return ListView(
            padding: const EdgeInsetsDirectional.all(WaveSpacing.x24),
            children: [
              if (_isGate) ...[
                Text(
                  context.l10n.phoneGateTitle,
                  style: context.texts.headline,
                ),
                const SizedBox(height: WaveSpacing.x8),
                Text(
                  context.l10n.phoneGateBody,
                  style: context.texts.caption,
                ),
                const SizedBox(height: WaveSpacing.x24),
              ],

              WaveTextField(
                controller: _phone,
                enabled: !awaitingCode,
                keyboardType: TextInputType.phone,
                label: context.l10n.phoneNumber,
                hint: '+964 7XX XXX XXXX',
                forceLtr: true,
              ),

              if (awaitingCode) ...[
                const SizedBox(height: WaveSpacing.x16),
                WaveTextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  forceLtr: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6), // Replaces maxLength
                  ],
                  label: context.l10n.sixDigitCode,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: WaveButton(
                    variant: WaveButtonVariant.tertiary,
                    size: WaveButtonSize.sm,
                    label: context.l10n.sendNewCode,
                    onPressed: state.isBusy
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(OtpRequested(_phone.text.trim())),
                  ),
                ),
              ],

              const SizedBox(height: WaveSpacing.x16),
              WaveButton(
                expand: true,
                isLoading: state.isBusy,
                label: awaitingCode
                    ? context.l10n.verifyAndContinue
                    : context.l10n.sendCode,
                onPressed: state.isBusy ? null : () => _submit(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submit(BuildContext context, AuthState state) {
    final bloc = context.read<AuthBloc>();

    if (state.otpStage == OtpStage.awaitingCode ||
        state.otpStage == OtpStage.verifying) {
      bloc.add(
        OtpSubmitted(
          _code.text.trim(),
          linkToExisting: _isGate,
        ),
      );
    } else {
      bloc.add(OtpRequested(_phone.text.trim()));
    }
  }
}
