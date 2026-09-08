import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_button.dart';

@Deprecated('Legacy enum. Use WaveState subclasses.')
enum WaveViewState { loading, content, empty, error, offline }

sealed class WaveState {
  const WaveState();
}

final class WaveContent extends WaveState {
  const WaveContent();
}

final class WaveLoading extends WaveState {
  const WaveLoading(this.skeleton);
  final Widget skeleton;
}

final class WaveEmpty extends WaveState {
  const WaveEmpty({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
}

enum WaveFailureKind {
  noConnection,
  serverError,
  paymentDeclined,
  outOfStock,
  locationDenied,
  sessionExpired,
  notFound,
  rateLimited, 
}

final class WaveFailure extends WaveState {
  const WaveFailure(this.kind, {this.onRetry, this.detail});
  
  final WaveFailureKind kind;
  final VoidCallback? onRetry;
  final String? detail;
}

class WaveStateView extends StatelessWidget {
  const WaveStateView({
    required Object state,
    required this.content,
    this.emptyTitle = 'No data',
    this.emptyMessage = '',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.onErrorRetry,
    super.key,
  }) : _stateObj = state;

  final Object _stateObj;
  final Widget content;
  
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final VoidCallback? onErrorRetry;

  @override
  Widget build(BuildContext context) {
    final resolvedState = switch (_stateObj) {
      final WaveState s => s,
      _ => _mapLegacyEnumToState(_stateObj),
    };

    return switch (resolvedState) {
      WaveContent() => content,
      WaveLoading(:final skeleton) => _Deferred(child: skeleton),
      WaveEmpty(
        :final icon,
        :final title,
        :final body,
        :final actionLabel,
        :final onAction,
      ) =>
        _Message(
          icon: icon,
          title: title,
          body: body,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      WaveFailure(:final kind, :final onRetry, :final detail) =>
        _Failure(kind: kind, onRetry: onRetry, detail: detail),
    };
  }

  WaveState _mapLegacyEnumToState(Object legacy) {
    final str = legacy.toString();
    if (str.contains('loading')) {
      return const WaveLoading(Center(child: CircularProgressIndicator()));
    }
    if (str.contains('content')) {
      return const WaveContent();
    }
    if (str.contains('empty')) {
      return WaveEmpty(
        icon: emptyIcon,
        title: emptyTitle,
        body: emptyMessage,
        actionLabel: emptyActionLabel ?? 'OK',
        onAction: onEmptyAction ?? () {},
      );
    }
    if (str.contains('error') || str.contains('offline')) {
      return WaveFailure(
        str.contains('offline') ? WaveFailureKind.noConnection : WaveFailureKind.serverError,
        onRetry: onErrorRetry,
      );
    }
    return const WaveContent();
  }
}

class _Deferred extends StatefulWidget {
  const _Deferred({required this.child});
  final Widget child;

  @override
  State<_Deferred> createState() => _DeferredState();
}

class _DeferredState extends State<_Deferred> {
  static const _threshold = Duration(milliseconds: 250);

  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_threshold, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _visible ? widget.child : const SizedBox.shrink();
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: s.x32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: s.x48, color: c.textTertiary),
            SizedBox(height: s.x20),
            Text(title, style: t.title, textAlign: TextAlign.center),
            SizedBox(height: s.x8),
            Text(
              body,
              style: t.body.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: s.x24),
            WaveButton(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.kind, this.onRetry, this.detail});

  final WaveFailureKind kind;
  final VoidCallback? onRetry;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String fallbackBody) = switch (kind) {
      WaveFailureKind.noConnection => (
          Icons.wifi_off_outlined,
          'No Connection',
          'Please check your internet connection and try again.',
        ),
      WaveFailureKind.serverError => (
          Icons.cloud_off_outlined,
          'Server Error',
          'We are experiencing technical difficulties.',
        ),
      WaveFailureKind.paymentDeclined => (
          Icons.credit_card_off_outlined,
          'Payment Declined',
          'Your payment could not be processed.',
        ),
      WaveFailureKind.outOfStock => (
          Icons.inventory_2_outlined,
          'Out of Stock',
          'This item is currently out of stock.',
        ),
      WaveFailureKind.locationDenied => (
          Icons.location_off_outlined,
          'Location Denied',
          'Please enable location services.',
        ),
      WaveFailureKind.sessionExpired => (
          Icons.lock_clock_outlined,
          'Session Expired',
          'Please log in again.',
        ),
      WaveFailureKind.notFound => (
          Icons.search_off_outlined,
          'ئەم بەرهەمە نەدۆزرایەوە',
          'لەوانەیە ئەم بەرهەمە سڕابێتەوە یان فرۆشرابێت.',
        ),
      WaveFailureKind.rateLimited => (
          Icons.hourglass_empty_outlined,
          'زۆر خێرایت!',
          'تکایە کەمێک بوەستە و دووبارە هەوڵ بدەرەوە.',
        ),
    };

    return _Message(
      icon: icon,
      title: title,
      body: detail ?? fallbackBody,
      actionLabel: 'Retry',
      onAction: onRetry ?? () {},
    );
  }
}
