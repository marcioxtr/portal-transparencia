import '../http/cliente_http.dart';
import '../modelos/modelos.dart';
import 'arvore_parser.dart';
import 'catalogo_pastas.dart';

/// Fonte: arquivos legados (Transparência até 2022) no file-browser eCrie.
///
/// Documentação: `docs/api/site-prefeitura.md` (seção 3).
class FonteEcrie {
  FonteEcrie({
    required ClienteHttp http,
    this.idCliente = 41,
    Uri? host,
  })  : _http = http,
        _host = host ?? Uri.parse('https://ecrie.com.br');

  final ClienteHttp _http;

  /// Id da prefeitura no CMS eCrie (São João da Boa Vista = 41).
  final int idCliente;
  final Uri _host;

  Uri get baseArquivos => _host.replace(path: '/home/_arq/$idCliente/');

  Uri urlPasta(String pasta) => _host.replace(
        path: '/home/_arq/$idCliente/Default.aspx',
        queryParameters: {'pasta': pasta},
      );

  /// Baixa e parseia a árvore completa de uma pasta do catálogo.
  Future<NoArquivo> arvore(PastaLegado pasta) => arvoreDePasta(pasta.pasta);

  /// Baixa e parseia a árvore completa de uma pasta arbitrária.
  Future<NoArquivo> arvoreDePasta(String pasta) async {
    final uri = urlPasta(pasta);
    final resp = await _http.get(uri);
    if (resp.statusCode != 200) throw HttpStatusException(uri, resp.statusCode);
    return ArvoreEcrieParser(baseArquivos: baseArquivos)
        .parse(resp.body, pastaRaiz: pasta);
  }
}
