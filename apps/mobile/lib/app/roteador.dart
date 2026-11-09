import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/busca/busca_page.dart';
import '../features/camara/camara_page.dart';
import '../features/camara/vereador_page.dart';
import '../features/mapa_site/mapa_site_page.dart';
import '../features/pessoal/pessoal_page.dart';
import '../features/cidade/avisos_page.dart';
import '../features/cidade/cidade_page.dart';
import '../features/cidade/conselhos_page.dart';
import '../features/cidade/licitacoes_page.dart';
import '../features/cidade/noticias_page.dart';
import '../features/cidade/servicos_page.dart';
import '../features/cobrar/cobrar_page.dart';
import '../features/contratos/contrato_detalhe_page.dart';
import '../features/contratos/contratos_page.dart';
import '../features/documentos/documentos_page.dart';
import '../features/documentos/pasta_page.dart';
import '../features/emendas/emenda_detalhe_page.dart';
import '../features/emendas/emendas_page.dart';
import '../features/glossario/glossario_page.dart';
import '../features/indicadores/comparar_page.dart';
import '../features/indicadores/mudancas_page.dart';
import '../features/indicadores/semaforo_page.dart';
import '../features/indicadores/vizinhos_page.dart';
import '../features/obras/obra_detalhe_page.dart';
import '../features/obras/obras_page.dart';
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

  // Obras públicas (dados/obras.json)
  static const obras = '/obras';
  static String obra(String slug) => '/obras/$slug';

  // Câmara Municipal (dados/camara.json + SAPL ao vivo)
  static const camara = '/camara';
  static String vereador(int id) => '/camara/vereador/$id';

  // Cidade: avisos, notícias, serviços, conselhos (dados/avisos|noticias|servicos.json)
  static const cidade = '/cidade';
  static const avisos = '/cidade/avisos';
  static const noticias = '/cidade/noticias';
  static const servicos = '/cidade/servicos';
  static const conselhos = '/cidade/conselhos';
  static const licitacoes = '/licitacoes';

  // Indicadores (dados/indicadores.json)
  static const comparar = '/comparar';
  static const indicadores = '/indicadores';
  static const mudancas = '/mudancas';
  static const vizinhos = '/vizinhos';

  // Pessoal e salários (dados/pessoal.json) · Mapa do site (dados/mapa_site.json)
  static const pessoal = '/pessoal';
  static const mapaSite = '/mapa-do-site';
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

/// Rota inicial pode ser sobrescrita em tempo de build
/// (`--dart-define=ROTA_INICIAL=/obras`) — usado em testes de tela e capturas.
const _rotaInicial = String.fromEnvironment('ROTA_INICIAL', defaultValue: Rotas.inicio);

/// Rota inicial do app. Testes sobrescrevem com `rotaInicialProvider.overrideWithValue`.
final rotaInicialProvider = Provider<String>((_) => _rotaInicial);

final roteadorProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ref.watch(rotaInicialProvider),
    // Deep links `transparenciasjbv://obras/slug` chegam com esquema e host;
    // convertemos para o caminho interno `/obras/slug`.
    redirect: (_, state) {
      final u = state.uri;
      if (u.scheme == 'transparenciasjbv') {
        final caminho = '/${u.host}${u.path}'.replaceAll(RegExp(r'/+'), '/');
        return u.hasQuery ? '$caminho?${u.query}' : caminho;
      }
      return null;
    },
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
        path: Rotas.obras,
        pageBuilder: (_, s) => _suave(s, const FundoVidro(child: ObrasPage())),
        routes: [
          GoRoute(
            path: ':slug',
            pageBuilder: (_, s) => _suave(s, FundoVidro(child: ObraDetalhePage(slug: s.pathParameters['slug']!))),
          ),
        ],
      ),
      GoRoute(
        path: Rotas.camara,
        pageBuilder: (_, s) => _suave(s, const FundoVidro(child: CamaraPage())),
        routes: [
          GoRoute(
            path: 'vereador/:id',
            pageBuilder: (_, s) => _suave(s, FundoVidro(child: VereadorPage(id: int.parse(s.pathParameters['id']!)))),
          ),
        ],
      ),
      GoRoute(path: Rotas.pessoal, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: PessoalPage()))),
      GoRoute(path: Rotas.mapaSite, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: MapaSitePage()))),
      GoRoute(path: Rotas.cidade, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: CidadePage()))),
      GoRoute(path: Rotas.avisos, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: AvisosPage()))),
      GoRoute(
        path: Rotas.noticias,
        pageBuilder: (_, s) => _suave(
          s,
          FundoVidro(
            child: NoticiasPage(
              departamento: s.uri.queryParameters['departamento'],
              busca: s.uri.queryParameters['busca'],
            ),
          ),
        ),
      ),
      GoRoute(path: Rotas.servicos, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: ServicosPage()))),
      GoRoute(path: Rotas.conselhos, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: ConselhosPage()))),
      GoRoute(path: Rotas.licitacoes, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: LicitacoesPage()))),
      GoRoute(path: Rotas.comparar, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: CompararPage()))),
      GoRoute(path: Rotas.indicadores, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: SemaforoPage()))),
      GoRoute(path: Rotas.mudancas, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: MudancasPage()))),
      GoRoute(path: Rotas.vizinhos, pageBuilder: (_, s) => _suave(s, const FundoVidro(child: VizinhosPage()))),
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
