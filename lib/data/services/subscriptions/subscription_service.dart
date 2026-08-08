import '../../models/subscriptions/debtor_model.dart';
import '../../models/subscriptions/subscription_model.dart';
import '../supabase/supabase_service.dart';

/// Reads go through `v_subscriptions`, which computes next_charge_date and
/// monthly_amount in Postgres. Writes go to the table underneath it.
class SubscriptionService {
  const SubscriptionService._();

  static const String _view = 'v_subscriptions';
  static const String _upcomingView = 'v_upcoming';
  static const String _table = 'subscriptions';

  static Future<List<SubscriptionModel>> fetchActive() async {
    final List<Map<String, dynamic>> rows = await SupabaseService.client
        .from(_view)
        .select()
        .order('next_charge_date');
    return rows.map(SubscriptionModel.fromJson).toList();
  }

  /// Charges due in the next 30 days, filtered and ordered by Postgres.
  static Future<List<SubscriptionModel>> fetchUpcoming() async {
    final List<Map<String, dynamic>> rows = await SupabaseService.client
        .from(_upcomingView)
        .select();
    return rows.map(SubscriptionModel.fromJson).toList();
  }

  /// Who owes the user money, grouped and summed by Postgres.
  static Future<List<DebtorModel>> fetchDebtors() async {
    final List<Map<String, dynamic>> rows = await SupabaseService.client
        .from('v_debtors')
        .select()
        .order('outstanding', ascending: false);
    return rows.map(DebtorModel.fromJson).toList();
  }

  /// Inserts against the table, then reads the row back from the view so the
  /// computed columns come from Postgres rather than a second implementation
  /// of the same date maths in Dart.
  static Future<SubscriptionModel> create(SubscriptionModel item) async {
    final Map<String, dynamic> inserted = await SupabaseService.client
        .from(_table)
        .insert(item.toWrite())
        .select('id')
        .single();
    return _fetchOne(inserted['id'] as String);
  }

  static Future<SubscriptionModel> update(SubscriptionModel item) async {
    await SupabaseService.client
        .from(_table)
        .update(item.toWrite())
        .eq('id', item.id);
    return _fetchOne(item.id);
  }

  /// Soft delete. The view filters on `active`, so the row leaves the list
  /// while its notification history keeps pointing at something real.
  static Future<void> setActive(String id, {required bool active}) =>
      SupabaseService.client
          .from(_table)
          .update({'active': active})
          .eq('id', id);

  static Future<SubscriptionModel> _fetchOne(String id) async {
    final Map<String, dynamic> row = await SupabaseService.client
        .from(_view)
        .select()
        .eq('id', id)
        .single();
    return SubscriptionModel.fromJson(row);
  }
}
