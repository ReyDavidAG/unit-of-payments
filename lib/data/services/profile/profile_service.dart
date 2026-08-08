import '../../models/profile/profile_model.dart';
import '../supabase/supabase_service.dart';

class ProfileService {
  const ProfileService._();

  static const String _table = 'profiles';

  /// The signup trigger creates the row, but an account made before that
  /// trigger existed would have none. Returning null lets the caller fall back
  /// to defaults instead of erroring on a screen the user just opened.
  static Future<ProfileModel?> fetch() async {
    final Map<String, dynamic>? row = await SupabaseService.client
        .from(_table)
        .select()
        .maybeSingle();
    return row == null ? null : ProfileModel.fromJson(row);
  }

  static Future<ProfileModel> save(ProfileModel profile) async {
    final Map<String, dynamic> row = await SupabaseService.client
        .from(_table)
        .update(profile.toUpdate())
        .eq('id', profile.id)
        .select()
        .single();
    return ProfileModel.fromJson(row);
  }
}
