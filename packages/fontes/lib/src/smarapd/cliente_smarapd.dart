import 'dart:convert';

import '../http/cliente_http.dart';
import 'endpoints.dart';

/// Filtro de uma visão dinâmica (`POST modulovisao/filter`).
/// Shape extraído do bundle do portal; ver `docs/api/smarapd-pai.md`.
class FiltroVisao {
  const FiltroVisao({
    required this.chaveModulo,
    required this.nomeVisao,
    this.exercicio,
    this.periodicidade,
    this.periodo,
    this.pagina = 1,
    this.quantidadeRegistros = 20,
    this.filtros = const [],
    this.ordenacao = const [],
  });

  final String chaveModulo;
  final String nomeVisao;
  final int? exercicio;
  final String? periodicidade;
  final String? periodo;
  final int pagina;
  final int quantidadeRegistros;
  final List<CampoFiltro> filtros;
  final List<Map<String, Object?>> ordenacao;

  Map<String, Object?> toJson() => {
        'ChaveModulo': chaveModulo,
        'NomeVisao': nomeVisao,
        'Filtros': filtros.map((f) => f.toJson()).toList(),
        'Periodicidade': periodicidade,
        'Periodo': periodo,
        'Exercicio': exercicio,
        'Pagina': pagina,
        'QuantidadeRegistros': quantidadeRegistros,
        'Ordenacao': ordenacao,
        'FiltroRedirecionaVisao': null,
      };
}

class CampoFiltro {
  const CampoFiltro({required this.campo, required this.valor, this.tipoValor});
  final String campo;
  final String valor;
  final String? tipoValor;
  Map<String, Object?> toJson() =>
      {'Campo': campo, 'Valor': valor, 'TipoValor': tipoValor};
}

/// Resultado paginado de uma visão dinâmica.
class ResultadoVisao {
  const ResultadoVisao({
    required this.quantidadePaginas,
    required this.quantidadeRegistros,
    required this.valores,
  });

  factory ResultadoVisao.fromJson(Map<String, Object?> j) => ResultadoVisao(
        quantidadePaginas: (j['QuantidadePaginas'] as num?)?.toInt() ?? 0,
        quantidadeRegistros: (j['QuantidadeRegistros'] as num?)?.toInt() ?? 0,
        valores:
            ((j['Valores'] as List?) ?? const []).cast<Map<String, Object?>>(),
      );

  final int quantidadePaginas;
  final int quantidadeRegistros;

  /// Linhas como mapas `coluna → valor`. As colunas vêm de
  /// [ClienteSmarapd.configuracaoVisao]; a tipagem forte virá quando
  /// houver amostras reais em `docs/api/samples/`.
  final List<Map<String, Object?>> valores;
}

/// Cliente da API do SmarAPD PAI (Transparência 2026+).
///
/// **Estado**: endpoints confirmados no bundle; formatos de resposta ainda não
/// capturados em produção — os métodos devolvem JSON cru (`Map`/`List`) até
/// termos amostras. Ver pendências em `docs/api/smarapd-pai.md`.
///
/// A API identifica o município pela origem da requisição; sem `Referer`
/// responde `400 "Não foi possível obter a origem da requisição."`. Enviamos
/// o `Referer` do próprio portal, exatamente como o SPA oficial faz.
class ClienteSmarapd {
  ClienteSmarapd({
    required ClienteHttp http,
    Uri? host,
  })  : _http = http,
        host = host ??
            Uri.parse('https://transparencia-saojoaodaboavista.smarapd.com.br');

  final ClienteHttp _http;
  final Uri host;

  Map<String, String> get _headers => {
        'Accept': 'application/json, text/plain, */*',
        'Referer': '$host/',
      };

  Uri _dados(String caminho) =>
      host.resolve('${SmarapdEndpoints.prefixoDados}/$caminho');

  Uri urlArquivo(String caminho) =>
      host.resolve('${SmarapdEndpoints.prefixoArquivos}/$caminho');

  Future<Object?> getJson(String caminho) async {
    final uri = _dados(caminho);
    final resp = await _http.get(uri, headers: _headers);
    if (resp.statusCode != 200) throw HttpStatusException(uri, resp.statusCode);
    return jsonDecode(utf8.decode(resp.bodyBytes));
  }

  Future<Object?> postJson(String caminho, Object body) async {
    final uri = _dados(caminho);
    final resp = await _http.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) throw HttpStatusException(uri, resp.statusCode);
    return jsonDecode(utf8.decode(resp.bodyBytes));
  }

  // ── Bootstrap ──────────────────────────────────────────────────────────
  Future<Object?> cliente() => getJson(SmarapdEndpoints.cliente);
  Future<Object?> menuPortal() => getJson(SmarapdEndpoints.menuPortal);
  Future<Object?> exercicios() => getJson(SmarapdEndpoints.exercicio);
  Future<Object?> home(int ano) => getJson(SmarapdEndpoints.home(ano));

  // ── Visões dinâmicas ───────────────────────────────────────────────────
  Future<Object?> configuracaoVisao(String modulo, String visao) =>
      getJson(SmarapdEndpoints.visaoConfiguracao(modulo, visao));

  Future<ResultadoVisao> filtrar(FiltroVisao filtro) async {
    final j = await postJson(SmarapdEndpoints.visaoFilter, filtro.toJson());
    return ResultadoVisao.fromJson((j as Map).cast<String, Object?>());
  }

  Future<Object?> totalizadoras(FiltroVisao filtro) =>
      postJson(SmarapdEndpoints.visaoTotalizadoras, filtro.toJson());

  // ── Busca / dados abertos / institucional ──────────────────────────────
  Future<Object?> buscarDocumentos({
    required String termo,
    String? chaveModulo,
    DateTime? inicio,
    DateTime? fim,
  }) =>
      postJson(SmarapdEndpoints.busca, {
        'Termo': termo,
        'Periodo': null,
        'Inicio': inicio == null ? null : _iso(inicio),
        'Fim': fim == null ? null : _iso(fim),
        'ChaveModulo': chaveModulo,
      });

  Future<Object?> dadosAbertos() => getJson(SmarapdEndpoints.dadosAbertos);
  Future<Object?> estruturaOrganizacional() =>
      getJson(SmarapdEndpoints.estruturaOrganizacional);
  Future<Object?> faq() => getJson(SmarapdEndpoints.faq);
  Future<Object?> glossario() => getJson(SmarapdEndpoints.glossario);
  Future<Object?> esicExercicios() => getJson(SmarapdEndpoints.esicExercicios);
  Future<Object?> esicVisoes(int ano) =>
      getJson(SmarapdEndpoints.esicVisoes(ano));

  static String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
