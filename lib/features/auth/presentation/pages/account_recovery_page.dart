import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/auth/domain/repositories/auth_repository.dart';

class AccountRecoveryPage extends StatefulWidget {
  const AccountRecoveryPage({super.key});

  @override
  State<AccountRecoveryPage> createState() => _AccountRecoveryPageState();
}

class _AccountRecoveryPageState extends State<AccountRecoveryPage> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _recoverByPhone() async {
    final number = _phone.text.trim();
    if (number.isEmpty) return;

    setState(() => _busy = true);
    final result = await getIt<AuthRepository>().startPhoneRecovery(number);
    if (!mounted) return;
    setState(() => _busy = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(context, f)))),
      (_) => context.push('${Routes.phoneVerify}?reason=recovery'),
    );
  }

  Future<void> _recoverByEmail() async {
    final address = _email.text.trim();
    if (address.isEmpty) return;

    setState(() => _busy = true);
    await getIt<AuthRepository>().sendRecoveryEmail(address);
    if (!mounted) return;

    setState(() {
      _busy = false;
      _emailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.recoverAccount)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(WaveSpacing.x24), // FIXED
        children: [
          Text(context.l10n.recoverByPhone, style: context.texts.title), // FIXED
          const SizedBox(height: WaveSpacing.x4), // FIXED
          Text(context.l10n.recoverByPhoneBody, style: context.texts.caption), // FIXED
          const SizedBox(height: WaveSpacing.x12), // FIXED
          WaveTextField( // FIXED: TextField -> WaveTextField
            controller: _phone,
            keyboardType: TextInputType.phone,
            forceLtr: true, // Phone numbers stay LTR even inside an RTL layout.
            label: context.l10n.phoneNumber,
            hint: '+964 7XX XXX XXXX',
          ),
          const SizedBox(height: WaveSpacing.x12), // FIXED
          WaveButton( // FIXED: FilledButton -> WaveButton
            onPressed: _busy ? null : _recoverByPhone,
            isLoading: _busy,
            expand: true,
            label: context.l10n.sendCode,
          ),

          const Divider(height: WaveSpacing.x48), // FIXED

          Text(context.l10n.recoverByEmail, style: context.texts.title), // FIXED
          const SizedBox(height: WaveSpacing.x4), // FIXED
          Text(context.l10n.recoverByEmailBody, style: context.texts.caption), // FIXED
          const SizedBox(height: WaveSpacing.x12), // FIXED
          WaveTextField( // FIXED
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            forceLtr: true,
            label: context.l10n.emailAddress,
          ),
          const SizedBox(height: WaveSpacing.x12), // FIXED
          WaveButton( // FIXED: OutlinedButton -> WaveButton secondary
            variant: WaveButtonVariant.secondary,
            onPressed: _busy || _emailSent ? null : _recoverByEmail,
            isLoading: _busy && !_emailSent,
            expand: true,
            label: context.l10n.sendRecoveryEmail,
          ),

          if (_emailSent) ...[
            const SizedBox(height: WaveSpacing.x12), // FIXED
            Text(
              context.l10n.recoveryEmailSent,
              style: context.texts.caption.copyWith( // FIXED
                color: context.waveColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
