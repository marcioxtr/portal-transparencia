import 'package:html/parser.dart' as html;

import '../modelos/modelos.dart';
import '../util/parse_br.dart';
import 'contratos_parser.dart' show ancestralItem, extrairCampos;
import 'seletores.dart';

/// Parser puro de `/transparencia/emendas-parlamentares` e do detalhe.
class EmendasParser {
  const EmendasParser({this.seletores = SeletoresPrefeitura.padrao});
  final SeletoresPrefeitura seletores;

  static final _slugNaUrl = RegExp(r'/emendas-parlamentares/([^/?#]+)');
  static final _total = RegExp(r'total de\s+(\d+)');

  Pagina<EmendaResumo> parseLista(String htmlTexto, {int paginaAtual = 1}) {
    final doc = html.parse(htmlTexto);
    final itens = <EmendaResumo>[];

    for (final link in doc.querySelectorAll(seletores.listaLink)) {
      final m = _slugNaUrl.firstMatch(link.attributes['href'] ?? '');
      if (m == null) continue;
      final item = ancestralItem(link);
      final publicado = item
          ?.querySelectorAll(seletores.listaPublicado)
          .map((e) => e.text)
          .firstWhere((t) => t.contains('Publicado'), orElse: () => '');
      itens.add(EmendaResumo(
        slug: m.group(1)!,
        titulo: limparEspacos(link.text),
        publicadoEm: parseDataBr(publicado),
      ));
    }

    final pag = parsePaginacao(
      doc.querySelector(seletores.paginacao)?.attributes['aria-label'],
    );
    final totalM = _total.firstMatch(doc.body?.text ?? '');
    return Pagina(
      itens: itens,
      paginaAtual: pag?.$1 ?? paginaAtual,
      totalPaginas: pag?.$2 ?? (itens.isEmpty ? 0 : paginaAtual),
      totalRegistros: totalM == null ? null : int.parse(totalM.group(1)!),
    );
  }

  Emenda parseDetalhe(String htmlTexto, {required String slug}) {
    final doc = html.parse(htmlTexto);
    final titulo =
        limparEspacos(doc.querySelector(seletores.detalheTitulo)?.text ?? '');
    final corpo = doc.querySelector(seletores.detalheCorpo) ?? doc.body!;
    final campos = extrairCampos(corpo, seletores);
    String? pega(String chave) => campos.remove(chave);

    return Emenda(
      slug: slug,
      titulo: titulo,
      numero: pega('numero_da_emenda'),
      origemRecurso: pega('origem_do_recurso'),
      tipo: pega('tipo_de_emenda'),
      autoria: pega('autoria'),
      formaRepasse: pega('forma_de_repasse'),
      valorCentavos: parseReaisEmCentavos(pega('valor_da_emenda')),
      objetivo: pega('objetivo_finalidade'),
      funcaoGoverno: pega('funcao_de_governo'),
      beneficiario: pega('beneficiario'),
      camposExtras: campos,
    );
  }
}
