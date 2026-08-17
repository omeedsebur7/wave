import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/auth/domain/repositories/auth_repository.dart';

/// Account recovery (§1).
///
/// Two paths, because accounts arrive by two routes. Someone who signed up with
/// a phone number recovers by OTP to that number — proving control of it is
/// proof enough. Someone who used Google or Apple and has since changed phone
/// recovers through their email provider instead.
///
/// Neither path ever confirms whether an account exists. A screen that said "no
/// account with that number" would be a free tool for working out which numbers
/// are registered here.
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

    // Always reports success, whether or not the address is registered.
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
        padding: const EdgeInsets.all(24),
        children: [
          Text(context.l10n.recoverByPhone, style: context.texts.titleMedium),
          const SizedBox(height: 4),
          Text(context.l10n.recoverByPhoneBody, style: context.texts.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            // Phone numbers stay LTR even inside an RTL layout.
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: context.l10n.phoneNumber,
              hintText: '+964 7XX XXX XXXX',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _recoverByPhone,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            child: Text(context.l10n.sendCode),
          ),

          const Divider(height: 48),

          Text(context.l10n.recoverByEmail, style: context.texts.titleMedium),
          const SizedBox(height: 4),
          Text(context.l10n.recoverByEmailBody, style: context.texts.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: context.l10n.emailAddress,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy || _emailSent ? null : _recoverByEmail,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
            child: Text(context.l10n.sendRecoveryEmail),
          ),

          if (_emailSent) ...[
            const SizedBox(height: 12),
            Text(
              // Deliberately not "we sent you an email" — that phrasing would
              // confirm the address is registered.
              context.l10n.recoveryEmailSent,
              style: context.texts.bodySmall?.copyWith(
                color: context.waveColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
