import '../../models/notifications/notification_log_model.dart';
import '../supabase/supabase_service.dart';

class NotificationLogService {
  const NotificationLogService._();

  static const String _table = 'notification_log';

  static Future<List<NotificationLogModel>> fetchRecent({
    int limit = 100,
  }) async {
    final List<Map<String, dynamic>> rows = await SupabaseService.client
        .from(_table)
        .select()
        .order('charge_date', ascending: false)
        .limit(limit);
    return rows.map(NotificationLogModel.fromJson).toList();
  }

  /// Idempotent by construction: the notif_once constraint owns deduplication,
  /// so the client can reschedule everything on every launch without keeping
  /// track of what it already wrote.
  static Future<void> record(List<NotificationLogModel> entries) async {
    if (entries.isEmpty) {
      return;
    }
    await SupabaseService.client
        .from(_table)
        .upsert(
          entries.map((entry) => entry.toInsert()).toList(),
          onConflict: 'subscription_id,charge_date',
          ignoreDuplicates: true,
        );
  }

  /// Marks everything whose moment has passed. Cheap because the partial index
  /// on (user_id, charge_date) where delivered_at is null covers exactly this.
  static Future<void> markDelivered(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await SupabaseService.client
        .from(_table)
        .update({'delivered_at': DateTime.now().toUtc().toIso8601String()})
        .inFilter('id', ids);
  }
}
