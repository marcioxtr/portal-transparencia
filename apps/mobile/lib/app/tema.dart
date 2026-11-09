import 'package:flutter/material.dart';

/// Paleta derivada do logo: seis pessoas-peça, seis cores.
abstract final class Cores {
  static const vermelho = Color(0xFFE63946);
  static const laranja = Color(0xFFF4A261);
  static const amarelo = Color(0xFFF9C74F);
  static const verde = Color(0xFF2A9D8F);
  static const azul = Color(0xFF4361EE);
  static const roxo = Color(0xFF7B2CBF);

  /// Cor principal da interface (confiança, dados públicos).
  static const primaria = azul;

  static const pecas = [vermelho, laranja, amarelo, verde, azul, roxo];
}

ThemeData temaClaro() => _tema(Brightness.light);
ThemeData temaEscuro() => _tema(Brightness.dark);

ThemeData _tema(Brightness b) {
  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.primaria,
    brightness: b,
  );
  return ThemeData(
    colorScheme: esquema,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: esquema.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
