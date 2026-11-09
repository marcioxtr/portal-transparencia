import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fontes/fontes.dart';

/// Camada de dados: um `ClienteHttp` compartilhado e uma instância de cada
/// fonte. Os `FutureProvider`s abaixo funcionam como cache em memória
/// (stale-while-revalidate simples via `ref.invalidate`). Cache em disco
/// (drift) entra na Fase 1 — ver docs/03-arquitetura.md.

final clienteHttpProvider = Provider<ClienteHttp>((ref) {
  final c = ClienteHttp();
  ref.onDispose(c.close);
  return c;
});

final fontePrefeituraProvider = Provider<FontePrefeitura>(
  (ref) => FontePrefeitura(http: ref.watch(clienteHttpProvider)),
);

final fonteEcrieProvider = Provider<FonteEcrie>(
  (ref) => FonteEcrie(http: ref.watch(clienteHttpProvider)),
);

// ── Contratos ──────────────────────────────────────────────────────────────

/// Parâmetros de busca de contratos. Imutável e comparável para servir de
/// chave de cache no `family`.
class FiltroContratos {
  const FiltroContratos({
    this.pagina = 1,
    this.numero,
    this.ano,
    this.tipo,
    this.objeto,
    this.razaoSocial,
  });

  final int pagina;
  final String? numero;
  final int? ano;
  final String? tipo;
  final String? objeto;
  final String? razaoSocial;

  bool get temFiltro =>
      (numero?.isNotEmpty ?? false) ||
      ano != null ||
      (tipo?.isNotEmpty ?? false) ||
      (objeto?.isNotEmpty ?? false) ||
      (razaoSocial?.isNotEmpty ?? false);

  FiltroContratos copyWith({
    int? pagina,
    String? numero,
    int? ano,
    String? tipo,
    String? objeto,
    String? razaoSocial,
    bool limparAno = false,
    bool limparTipo = false,
  }) =>
      FiltroContratos(
        pagina: pagina ?? this.pagina,
        numero: numero ?? this.numero,
        ano: limparAno ? null : (ano ?? this.ano),
        tipo: limparTipo ? null : (tipo ?? this.tipo),
        objeto: objeto ?? this.objeto,
        razaoSocial: razaoSocial ?? this.razaoSocial,
      );

  @override
  bool operator ==(Object other) =>
      other is FiltroContratos &&
      other.pagina == pagina &&
      other.numero == numero &&
      other.ano == ano &&
      other.tipo == tipo &&
      other.objeto == objeto &&
      other.razaoSocial == razaoSocial;

  @override
  int get hashCode =>
      Object.hash(pagina, numero, ano, tipo, objeto, razaoSocial);
}

/// Filtro atual da aba Contratos (sobrevive à navegação para o detalhe).
class FiltroContratosNotifier extends Notifier<FiltroContratos> {
  @override
  FiltroContratos build() => const FiltroContratos();

  void definir(FiltroContratos f) => state = f;
  void pagina(int p) => state = state.copyWith(pagina: p);
  void limpar() => state = const FiltroContratos();
}

final filtroContratosProvider =
    NotifierProvider<FiltroContratosNotifier, FiltroContratos>(
  FiltroContratosNotifier.new,
);

final contratosProvider =
    FutureProvider.family<Pagina<ContratoResumo>, FiltroContratos>(
  (ref, f) {
    ref.keepAlive();
    return ref.watch(fontePrefeituraProvider).listarContratos(
          pagina: f.pagina,
          numero: f.numero,
          ano: f.ano,
          tipo: f.tipo,
          objeto: f.objeto,
          razaoSocial: f.razaoSocial,
        );
  },
);

final contratoProvider = FutureProvider.family<Contrato, int>((ref, id) {
  ref.keepAlive();
  return ref.watch(fontePrefeituraProvider).obterContrato(id);
});

// ── Emendas ────────────────────────────────────────────────────────────────

final emendasProvider = FutureProvider.family<Pagina<EmendaResumo>, int>(
  (ref, pagina) {
    ref.keepAlive();
    return ref.watch(fontePrefeituraProvider).listarEmendas(pagina: pagina);
  },
);

/// Todas as emendas (são ~100; vale carregar tudo para agrupar e buscar).
final todasEmendasProvider = FutureProvider<List<EmendaResumo>>((ref) async {
  ref.keepAlive();
  final fonte = ref.watch(fontePrefeituraProvider);
  final primeira = await fonte.listarEmendas();
  final itens = [...primeira.itens];
  for (var p = 2; p <= primeira.totalPaginas; p++) {
    itens.addAll((await fonte.listarEmendas(pagina: p)).itens);
  }
  return itens;
});

final emendaProvider = FutureProvider.family<Emenda, String>((ref, slug) {
  ref.keepAlive();
  return ref.watch(fontePrefeituraProvider).obterEmenda(slug);
});

// ── Documentos históricos (eCrie) ──────────────────────────────────────────

final arvoreLegadoProvider = FutureProvider.family<NoArquivo, String>(
  (ref, idPasta) {
    ref.keepAlive();
    final pasta = pastasLegado.firstWhere((p) => p.id == idPasta);
    return ref.watch(fonteEcrieProvider).arvore(pasta);
  },
);
