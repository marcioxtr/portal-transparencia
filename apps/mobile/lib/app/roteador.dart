import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/busca/busca_page.dart';
import '../features/cobrar/cobrar_page.dart';
import '../features/contratos/contrato_detalhe_page.dart';
import '../features/contratos/contratos_page.dart';
import '../features/documentos/documentos_page.dart';
import '../features/documentos/pasta_page.dart';
import '../features/emendas/emenda_detalhe_page.dart';
import '../features/emendas/emendas_page.dart';
import '../features/glossario/glossario_page.dart';
import '../features/painel/painel_page.dart';
import '../features/sobre/sobre_page.dart';
import '../widgets/vidro.dart';
import 'casca.dart';

/// Rotas do app. Nomes em português e estáveis: são usados em deep links,
/// favoritos e na config remota.
abstract final class Rotas {
  static const inicio = '/';
  static const buscar = '/buscar';
  static const contratos = '/contratos';
  static String contrato(int id) => '/contratos/$id';
  static const emendas = '/emendas';
  static String emenda(String slug) => '/emendas/$slug';
  static const documentos = '/documentos';
  static String pasta(String id) => '/documentos/$id';
  static const glossario = '/glossario';
  static const cobrar = '/cobrar';
  static const sobre = '/sobre';
}

/// Transição suave (fade + leve deslize) para páginas fora das abas.
CustomTransitionPage<void> _suave(GoRouterState s, Widget child) => CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, anim, __, child) {
        final curva = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curva,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curva),
            child: child,
          ),
        );
      },
    );

final roteadorProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Rotas.inicio,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Casca(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Rotas.inicio, builder: (_, __) => const PainelPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Rotas.buscar, builder: (_, __) => const BuscaPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rotas.contratos,
              builder: (_, __) => const ContratosPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (_, s) => _suave(
                    s,
                    ContratoDetalhePage(id: int.parse(s.pathParameters['id']!)),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rotas.emendas,
              builder: (_, __) => const EmendasPage(),
              routes: [
                GoRoute(
                  path: ':slug',
                  pageBuilder: (_, s) => _suave(s, EmendaDetalhePage(slug: s.pathParameters['slug']!)),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rotas.documentos,
              builder: (_, __) => const DocumentosPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (_, s) => _suave(s, PastaPage(idPasta: s.pathParameters['id']!)),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: Rotas.glossario,
        pageBuilder: (_, s) => _suave(s, const FundoVidro(child: GlossarioPage())),
      ),
      GoRoute(
        path: Rotas.cobrar,
        pageBuilder: (_, s) => _suave(s, FundoVidro(child: CobrarPage(textoInicial: s.extra as String?))),
      ),
      GoRoute(
        path: Rotas.sobre,
        pageBuilder: (_, s) => _suave(s, const FundoVidro(child: SobrePage())),
      ),
    ],
    errorBuilder: (context, state) => FundoVidro(
      child: Scaffold(
        appBar: AppBar(title: const Text('Página não encontrada')),
        body: Center(child: Text(state.error?.toString() ?? '')),
      ),
    ),
  );
});
