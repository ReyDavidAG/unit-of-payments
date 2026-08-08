import 'package:flutter_riverpod/legacy.dart';

/// Currently selected tab in the shell. 0 = Resumen, 1 = Suscripciones,
/// 2 = Tarjetas, 3 = Avisos.
final StateProvider<int> shellIndexProvider = StateProvider<int>((ref) => 0);
