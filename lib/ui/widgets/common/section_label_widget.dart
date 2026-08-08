import 'package:flutter/material.dart';

/// Uppercase micro-label above a section. Reads from labelSmall so the tracking
/// stays in one place rather than being retyped per section.
class SectionLabelWidget extends StatelessWidget {
  const SectionLabelWidget(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelSmall);
}
