import '../http/cliente_http.dart';
import '../modelos/modelos.dart';
import 'contratos_parser.dart';
import 'emendas_parser.dart';
import 'seletores.dart';

/// Fonte: site da Prefeitura (CMS eCrie). Contratos e emendas parlamentares.
///
/// Documentação: `docs/api/site-prefeitura.md`.
class FontePrefeitura {
  FontePrefeitura({
    required ClienteHttp http,
    Uri? baseUrl,
    SeletoresPrefeitura seletores = SeletoresPrefeitura.padrao,
  })  : _http = http,
        baseUrl = baseUrl ?? Uri.parse('https://www.saojoao.sp.gov.br'),
        _contratos = ContratosParser(seletores: seletores),
        _emendas = EmendasParser(seletores: seletores);

  final ClienteHttp _http;
  final Uri baseUrl;
  final ContratosParser _contratos;
  final EmendasParser _emendas;

  // ── Contratos ──────────────────────────────────────────────────────────

  Uri urlContratos({
    int pagina = 1,
    String? numero,
    int? ano,
    String? tipo,
    String? objeto,
    String? razaoSocial,
  }) {
    final q = <String, String>{
      if (numero != null && numero.isNotEmpty) 'numero': numero,
      if (ano != null) 'ano': '$ano',
      if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
      if (objeto != null && objeto.isNotEmpty) 'objeto': objeto,
      if (razaoSocial != null && razaoSocial.isNotEmpty)
        'razaoSocial': razaoSocial,
      if (pagina > 1) 'pagina': '$pagina',
    };
    return baseUrl.replace(
      path: '/contratos',
      queryParameters: q.isEmpty ? null : q,
    );
  }

  Uri urlContrato(int id) => baseUrl.replace(path: '/contratos/$id');

  Future<Pagina<ContratoResumo>> listarContratos({
    int pagina = 1,
    String? numero,
    int? ano,
    String? tipo,
    String? objeto,
    String? razaoSocial,
  }) async {
    final uri = urlContratos(
      pagina: pagina,
      numero: numero,
      ano: ano,
      tipo: tipo,
      objeto: objeto,
      razaoSocial: razaoSocial,
    );
    final resp = await _http.get(uri);
    _checar(resp.statusCode, uri);
    return _contratos.parseLista(resp.body, paginaAtual: pagina);
  }

  Future<Contrato> obterContrato(int id) async {
    final uri = urlContrato(id);
    final resp = await _http.get(uri);
    _checar(resp.statusCode, uri);
    return _contratos.parseDetalhe(resp.body, id: id);
  }

  // ── Emendas ────────────────────────────────────────────────────────────

  Uri urlEmendas({
    int pagina = 1,
    String? titulo,
    String? descricao,
    String? dataBr,
  }) {
    final q = <String, String>{
      if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      if (dataBr != null && dataBr.isNotEmpty) 'data': dataBr,
      if (pagina > 1) 'pagina': '$pagina',
    };
    return baseUrl.replace(
      path: '/transparencia/emendas-parlamentares',
      queryParameters: q.isEmpty ? null : q,
    );
  }

  Uri urlEmenda(String slug) =>
      baseUrl.replace(path: '/transparencia/emendas-parlamentares/$slug');

  Future<Pagina<EmendaResumo>> listarEmendas({
    int pagina = 1,
    String? titulo,
    String? descricao,
    String? dataBr,
  }) async {
    final uri = urlEmendas(
      pagina: pagina,
      titulo: titulo,
      descricao: descricao,
      dataBr: dataBr,
    );
    final resp = await _http.get(uri);
    _checar(resp.statusCode, uri);
    return _emendas.parseLista(resp.body, paginaAtual: pagina);
  }

  Future<Emenda> obterEmenda(String slug) async {
    final uri = urlEmenda(slug);
    final resp = await _http.get(uri);
    _checar(resp.statusCode, uri);
    return _emendas.parseDetalhe(resp.body, slug: slug);
  }

  void _checar(int status, Uri uri) {
    if (status != 200) throw HttpStatusException(uri, status);
  }
}
