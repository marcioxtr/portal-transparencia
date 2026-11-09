import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Paleta da marca: seis pessoas-peça, seis cores (ver docs/brand/README.md).
abstract final class Cores {
  static const rosa = Color(0xFFFF3B5C);
  static const laranja = Color(0xFFFF8C1A);
  static const amarelo = Color(0xFFFFD60A);
  static const verde = Color(0xFF3DDC84);
  static const azulCeu = Color(0xFF00B4FF);
  static const violeta = Color(0xFF8A4DFF);

  /// Cor principal da interface.
  static const primaria = Color(0xFF4361EE);

  static const pecas = [rosa, laranja, amarelo, verde, azulCeu, violeta];

  /// Semântica financeira — estável em claro e escuro.
  static const receita = verde;
  static const despesa = rosa;
  static const pago = azulCeu;

  /// Cor para a i-ésima série de um gráfico.
  static Color serie(int i) => pecas[i % pecas.length];
}

/// Tokens do visual "vidro": superfícies translúcidas sobre um fundo com
/// profundidade. Lidos via `Vidro.of(context)`.
class Vidro extends ThemeExtension<Vidro> {
  const Vidro({
    required this.superficie,
    required this.superficieForte,
    required this.borda,
    required this.brilho,
    required this.fundoA,
    required this.fundoB,
    required this.desfoque,
  });

  final Color superficie;
  final Color superficieForte;
  final Color borda;
  final Color brilho;
  final Color fundoA;
  final Color fundoB;
  final double desfoque;

  static const claro = Vidro(
    superficie: Color(0x99FFFFFF),
    superficieForte: Color(0xCCFFFFFF),
    borda: Color(0x80FFFFFF),
    brilho: Color(0xB3FFFFFF),
    fundoA: Color(0xFFEEF1FF),
    fundoB: Color(0xFFF7F8FC),
    desfoque: 24,
  );

  static const escuro = Vidro(
    superficie: Color(0x1FFFFFFF),
    superficieForte: Color(0x33FFFFFF),
    borda: Color(0x40FFFFFF),
    brilho: Color(0x26FFFFFF),
    fundoA: Color(0xFF0B1026),
    fundoB: Color(0xFF1B1540),
    desfoque: 28,
  );

  static Vidro of(BuildContext c) => Theme.of(c).extension<Vidro>()!;

  @override
  Vidro copyWith({
    Color? superficie,
    Color? superficieForte,
    Color? borda,
    Color? brilho,
    Color? fundoA,
    Color? fundoB,
    double? desfoque,
  }) =>
      Vidro(
        superficie: superficie ?? this.superficie,
        superficieForte: superficieForte ?? this.superficieForte,
        borda: borda ?? this.borda,
        brilho: brilho ?? this.brilho,
        fundoA: fundoA ?? this.fundoA,
        fundoB: fundoB ?? this.fundoB,
        desfoque: desfoque ?? this.desfoque,
      );

  @override
  Vidro lerp(Vidro? other, double t) {
    if (other == null) return this;
    return Vidro(
      superficie: Color.lerp(superficie, other.superficie, t)!,
      superficieForte: Color.lerp(superficieForte, other.superficieForte, t)!,
      borda: Color.lerp(borda, other.borda, t)!,
      brilho: Color.lerp(brilho, other.brilho, t)!,
      fundoA: Color.lerp(fundoA, other.fundoA, t)!,
      fundoB: Color.lerp(fundoB, other.fundoB, t)!,
      desfoque: desfoque + (other.desfoque - desfoque) * t,
    );
  }
}

ThemeData temaClaro() => _tema(Brightness.light, Vidro.claro);
ThemeData temaEscuro() => _tema(Brightness.dark, Vidro.escuro);

ThemeData _tema(Brightness b, Vidro vidro) {
  final escuro = b == Brightness.dark;
  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.primaria,
    brightness: b,
    surface: Colors.transparent,
  ).copyWith(
    surface: escuro ? const Color(0xFF0E1230) : const Color(0xFFF4F6FF),
  );
  final base = ThemeData(colorScheme: esquema, useMaterial3: true);
  final texto = base.textTheme.apply(
    bodyColor: escuro ? const Color(0xFFF2F3F8) : const Color(0xFF14172B),
    displayColor: escuro ? Colors.white : const Color(0xFF0E1230),
  );

  return base.copyWith(
    extensions: [vidro],
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: texto.copyWith(
      headlineMedium: texto.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineSmall: texto.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: texto.bodyLarge?.color,
      titleTextStyle: texto.titleLarge,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(color: vidro.borda, space: 1),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: vidro.superficie,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: vidro.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: vidro.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Cores.primaria, width: 1.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: vidro.superficie,
      side: BorderSide(color: vidro.borda),
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: escuro ? const Color(0xF2151A3A) : const Color(0xF5FFFFFF),
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: escuro ? const Color(0xF0101433) : const Color(0xF5F7F8FF),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
