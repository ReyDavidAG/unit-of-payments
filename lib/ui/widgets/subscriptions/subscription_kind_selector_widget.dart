import 'package:flutter/material.dart';

import '../../../data/models/subscriptions/subscription_model.dart';

/// Picks between an open-ended subscription and a fixed-length installment
/// plan. The choice reshapes the rest of the form, so it sits at the top —
/// but as a compact context toggle under the title, not as a primary action.
class SubscriptionKindSelectorWidget extends StatelessWidget {
  const SubscriptionKindSelectorWidget({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ChargeKind value;
  final ValueChanged<ChargeKind> onChanged;

  @override
  Widget build(BuildContext context) {
    // No visualDensity or shrinkWrap here: together they collapsed the theme's
    // 48 dp minimum to a measured 32, under both platform floors.
    return SegmentedButton<ChargeKind>(
      showSelectedIcon: false,
      segments: [
        for (final ChargeKind kind in ChargeKind.values)
          ButtonSegment<ChargeKind>(value: kind, label: Text(kind.label)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
