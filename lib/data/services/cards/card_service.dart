import '../../models/cards/card_model.dart';
import '../supabase/supabase_service.dart';

/// Card queries. No user_id filter anywhere: RLS scopes every row to the
/// session, and adding a client-side filter would only hide that fact.
class CardService {
  const CardService._();

  static const String _table = 'cards';

  static Future<List<CardModel>> fetchActive() async {
    final List<Map<String, dynamic>> rows = await SupabaseService.client
        .from(_table)
        .select()
        .eq('archived', false)
        .order('alias');
    return rows.map(CardModel.fromJson).toList();
  }

  static Future<CardModel> create(CardModel card) async {
    final Map<String, dynamic> row = await SupabaseService.client
        .from(_table)
        .insert(card.toInsert())
        .select()
        .single();
    return CardModel.fromJson(row);
  }

  static Future<CardModel> update(CardModel card) async {
    final Map<String, dynamic> row = await SupabaseService.client
        .from(_table)
        .update(card.toInsert())
        .eq('id', card.id)
        .select()
        .single();
    return CardModel.fromJson(row);
  }

  /// Archives instead of deleting. A hard delete would null out card_id on
  /// every subscription that pointed here, and undo could not bring those back.
  static Future<void> setArchived(String id, {required bool archived}) =>
      SupabaseService.client
          .from(_table)
          .update({'archived': archived})
          .eq('id', id);
}
