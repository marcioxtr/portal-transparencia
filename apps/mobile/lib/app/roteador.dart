import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/busca/busca_page.dart';
import '../features/contratos/contrato_detalhe_page.dart';
import '../features/contratos/contratos_page.dart';
import '../features/documentos/documentos_page.dart';
import '../features/documentos/pasta_page.dart';
import '../features/emendas/emenda_detalhe_page.dart';
import '../features/emendas/emendas_page.dart';
import '../features/inicio/inicio_page.dart';
import '../features/sobre/sobre_page.dart';
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
  static const sobre = '/sobre';
}

final roteadorProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Rotas.inicio,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Casca(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rotas.inicio,
              builder: (_, __) => const InicioPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rotas.buscar,
              builder: (_, __) => const BuscaPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Rotas.contratos,
              builder: (_, __) => const ContratosPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) => ContratoDetalhePage(
                    id: int.parse(s.pathParameters['id']!),
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
                  builder: (_, s) => EmendaDetalhePage(
                    slug: s.pathParameters['slug']!,
                  ),
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
                  builder: (_, s) => PastaPage(
                    idPasta: s.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: Rotas.sobre,
        builder: (_, __) => const SobrePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(child: Text(state.error?.toString() ?? '')),
    ),
  );
});
