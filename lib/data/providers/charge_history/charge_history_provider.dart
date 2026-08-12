import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/charge_history/charge_history_entry.dart';
import '../../services/charge_history/charge_history_service.dart';

/// One-shot fetch of the past-charges view. Re-fetched when invalidated
/// by the parent screen (pull-to-refresh or a back-from-edit).
final FutureProvider<List<ChargeHistoryEntry>> chargeHistoryProvider =
    FutureProvider<List<ChargeHistoryEntry>>((ref) async {
      return ChargeHistoryService.fetchAll();
    });
