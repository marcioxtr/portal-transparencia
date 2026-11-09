import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/vidro.dart';
import 'menu.dart';
import 'tema.dart';

/// Casca: fundo com profundidade, menu lateral e barra inferior flutuante de
/// vidro. Cada aba mantém sua pilha (StatefulShellRoute).
class Casca extends StatelessWidget {
  const Casca({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _abas = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Painel'),
    (Icons.search_rounded, Icons.search_rounded, 'Buscar'),
    (Icons.description_outlined, Icons.description_rounded, 'Contratos'),
    (Icons.account_balance_outlined, Icons.account_balance_rounded, 'Emendas'),
    (Icons.folder_outlined, Icons.folder_rounded, 'Documentos'),
  ];

  @override
  Widget build(BuildContext context) {
    return FundoVidro(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const MenuLateral(),
        extendBody: true,
        body: shell,
        bottomNavigationBar: _BarraVidro(
          indice: shell.currentIndex,
          abas: _abas,
          aoSelecionar: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
    );
  }
}

class _BarraVidro extends StatelessWidget {
  const _BarraVidro({required this.indice, required this.abas, required this.aoSelecionar});
  final int indice;
  final List<(IconData, IconData, String)> abas;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    final v = Vidro.of(context);
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: v.desfoque, sigmaY: v.desfoque),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: v.superficieForte,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: v.borda),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth / abas.length;
                return Stack(
                  children: [
                    // Indicador deslizante
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      left: w * indice + 6,
                      top: 6,
                      bottom: 6,
                      width: w - 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Cores.primaria.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Cores.primaria.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (i, aba) in abas.indexed)
                          Expanded(
                            child: InkWell(
                              onTap: () => aoSelecionar(i),
                              borderRadius: BorderRadius.circular(24),
                              child: Semantics(
                                selected: i == indice,
                                button: true,
                                label: aba.$3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: i == indice ? 1.12 : 1,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        i == indice ? aba.$2 : aba.$1,
                                        color: i == indice ? Colors.white : tt.bodyMedium?.color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      aba.$3,
                                      style: tt.labelSmall?.copyWith(
                                        color: i == indice ? Colors.white : tt.bodyMedium?.color,
                                        fontWeight: i == indice ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
