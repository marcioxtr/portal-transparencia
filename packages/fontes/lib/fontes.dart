/// Adaptadores para as fontes públicas de dados do Portal da Transparência
/// de São João da Boa Vista/SP.
///
/// Cada fonte vive em seu próprio namespace e expõe entidades de domínio
/// neutras ao fornecedor (ver `src/modelos`). Parsers são puros (recebem
/// `String`, devolvem objetos) para serem testáveis com fixtures.
library;

export 'src/http/cliente_http.dart';
export 'src/modelos/modelos.dart';
export 'src/prefeitura/fonte_prefeitura.dart';
export 'src/prefeitura/contratos_parser.dart';
export 'src/prefeitura/emendas_parser.dart';
export 'src/prefeitura/seletores.dart';
export 'src/ecrie/fonte_ecrie.dart';
export 'src/ecrie/arvore_parser.dart';
export 'src/ecrie/catalogo_pastas.dart';
export 'src/smarapd/cliente_smarapd.dart';
export 'src/smarapd/endpoints.dart';
export 'src/util/parse_br.dart';
