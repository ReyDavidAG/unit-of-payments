import '../../models/charge_history/charge_history_entry.dart';
import '../supabase/supabase_service.dart';

/// Reads the past-charges view. The view already filters out cancelled
/// subscriptions and today's not-yet-processed charges — the service is
/// a thin pass-through.
class ChargeHistoryService {
  const ChargeHistoryService._();

  static Future<List<ChargeHistoryEntry>> fetchAll() async {
    final List<dynamic> rows = await SupabaseService.client
        .from('v_charge_history')
        .select()
        .order('charge_date', ascending: false);
    return [
      for (final dynamic row in rows)
        ChargeHistoryEntry.fromJson(row as Map<String, dynamic>),
    ];
  }
}
