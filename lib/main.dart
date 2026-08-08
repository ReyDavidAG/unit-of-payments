import 'package:flutter/material.dart';

import 'config/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unit of Payments',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}
