import 'package:flutter/material.dart';

enum AppThemeMode {
  system('Sistema', 'Sigue la configuración del teléfono'),
  light('Claro', 'Siempre en claro'),
  dark('Oscuro', 'Siempre en oscuro');

  const AppThemeMode(this.label, this.description);

  final String label;
  final String description;

  ThemeMode get flutterMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  /// Falls back rather than throwing: a value stored by a future build must
  /// not stop an older one from starting.
  static AppThemeMode fromName(String? name) => values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => AppThemeMode.system,
  );
}
