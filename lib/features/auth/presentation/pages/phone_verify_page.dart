import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';

enum PhoneVerifyReason {
  /// Phone chosen as the sign-in method.
  signIn,

  /// A Google/Apple user who has reached checkout for the first time (§5.2).
  /// The copy changes here — this person did not come to verify a phone, they
  /// came to buy something, so the screen has to justify interrupting them.
  checkoutGate,

  /// Regaining access to an existing account (§1). Mechanically identical to
  /// signing in with a phone; kept distinct so the copy can acknowledge that
  /// this person is locked out rather than arriving fresh.
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
            // Back where they came from — usually checkout, so the purchase
            // they started can finish without re-navigating.
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
            padding: const EdgeInsets.all(24),
            children: [
              if (_isGate) ...[
                Text(
                  context.l10n.phoneGateTitle,
                  style: context.texts.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.phoneGateBody,
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 24),
              ],

              TextField(
                controller: _phone,
                enabled: !awaitingCode,
                keyboardType: TextInputType.phone,
                // Phone numbers stay LTR even in an RTL layout — a
                // right-to-left phone number is unreadable.
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: context.l10n.phoneNumber,
                  hintText: '+964 7XX XXX XXXX',
                  border: const OutlineInputBorder(),
                ),
              ),

              if (awaitingCode) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  maxLength: 6,
                  // Lets the OS offer the code straight from the SMS.
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.sixDigitCode,
                    border: const OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(OtpRequested(_phone.text.trim())),
                    child: Text(context.l10n.sendNewCode),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.isBusy ? null : () => _submit(context, state),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: state.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        awaitingCode
                            ? context.l10n.verifyAndContinue
                            : context.l10n.sendCode,
                      ),
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
          // The distinction that matters: at the checkout gate we LINK the
          // number to the existing Google/Apple account. Signing in with it
          // instead would create a second account and orphan their cart.
          linkToExisting: _isGate,
        ),
      );
    } else {
      bloc.add(OtpRequested(_phone.text.trim()));
    }
  }
}
