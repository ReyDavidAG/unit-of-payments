import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/notifications/notification_log_model.dart';
import '../../../data/services/notifications/local_notification_service.dart';

/// Answers "are reminders actually working on this phone", which nothing else
/// in the app can: a reminder fires days from now, with the app closed.
///
/// Debug builds only, reached by long-pressing the Avisos title. It is a
/// diagnostic, not a feature — delete it once the answer stops being in doubt.
class NotificationDebugView extends StatefulWidget {
  const NotificationDebugView({required this.log, super.key});

  /// The history the screen already has. Read rather than recomputed: these
  /// rows are what the last sync actually scheduled, which is the question.
  final List<NotificationLogModel> log;

  static Future<void> show(
    BuildContext context, {
    required List<NotificationLogModel> log,
  }) => showDialog<void>(
    context: context,
    builder: (_) => NotificationDebugView(log: log),
  );

  @override
  State<NotificationDebugView> createState() => _NotificationDebugViewState();
}

class _NotificationDebugViewState extends State<NotificationDebugView> {
  bool? _enabled;
  int _pending = 0;
  bool _loading = true;
  String? _probe;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final bool? enabled = await LocalNotificationService.isEnabled();
    final int pending = await LocalNotificationService.pendingCount();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _pending = pending;
        _loading = false;
      });
    }
  }

  Future<void> _probeNow() async {
    await LocalNotificationService.probe(const Duration(minutes: 1));
    if (mounted) {
      // Coming back re-runs the sync, and the sync cancels everything pending
      // before rescheduling — including the second probe.
      setState(
        () => _probe =
            'La 1 debe llegar ya. La 2 tarda hasta unos minutos: las alarmas '
            'son inexactas a propósito. Sal de la app y no vuelvas a entrar '
            'hasta que llegue.',
      );
    }
  }

  /// The soonest reminder still ahead of us. The OS hands back ids and text but
  /// never a fire time, so the log is the only place this exists.
  NotificationLogModel? get _next {
    final DateTime now = DateTime.now();
    final List<NotificationLogModel> ahead =
        widget.log.where((e) => e.scheduledFor.isAfter(now)).toList()
          ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return ahead.isEmpty ? null : ahead.first;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NotificationLogModel? next = _next;

    return AlertDialog(
      title: const Text('Diagnóstico de avisos'),
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(
                  label: 'Permiso del sistema',
                  value: switch (_enabled) {
                    true => 'Concedido',
                    false => 'Apagado — actívalo en Ajustes',
                    null => 'El sistema no contesta',
                  },
                  ok: _enabled ?? false,
                ),
                _Line(
                  label: 'Avisos en cola',
                  value: '$_pending',
                  ok: _pending > 0,
                ),
                _Line(
                  label: 'Próximo',
                  value: next == null
                      ? 'Ninguno que programar'
                      : '${next.title} · '
                            '${MoneyHelper.shortDate(next.scheduledFor)} '
                            'a las ${next.scheduledFor.hour}:00',
                  ok: next != null,
                ),
                if (_probe != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_probe!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _probeNow,
          child: const Text('Probar'),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, required this.ok});

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: ok ? theme.success : theme.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
