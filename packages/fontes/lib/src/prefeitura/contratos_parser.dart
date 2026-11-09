import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../modelos/modelos.dart';
import '../util/parse_br.dart';
import 'seletores.dart';

/// Parser puro das páginas `/contratos` e `/contratos/{id}`.
class ContratosParser {
  const ContratosParser({this.seletores = SeletoresPrefeitura.padrao});
  final SeletoresPrefeitura seletores;

  static final _idNaUrl = RegExp(r'/contratos/(\d+)');

  Pagina<ContratoResumo> parseLista(String htmlTexto, {int paginaAtual = 1}) {
    final doc = html.parse(htmlTexto);
    final itens = <ContratoResumo>[];

    for (final link in doc.querySelectorAll(seletores.listaLink)) {
      final href = link.attributes['href'] ?? '';
      final m = _idNaUrl.firstMatch(href);
      if (m == null) continue;
      final item = ancestralItem(link);
      final desc = item?.querySelector(seletores.listaDescricao)?.text ?? '';
      itens.add(ContratoResumo(
        id: int.parse(m.group(1)!),
        titulo: limparEspacos(link.text),
        objeto: limparEspacos(desc),
      ));
    }

    final pag = parsePaginacao(
      doc.querySelector(seletores.paginacao)?.attributes['aria-label'],
    );
    return Pagina(
      itens: itens,
      paginaAtual: pag?.$1 ?? paginaAtual,
      totalPaginas: pag?.$2 ?? (itens.isEmpty ? 0 : paginaAtual),
    );
  }

  Contrato parseDetalhe(String htmlTexto, {required int id}) {
    final doc = html.parse(htmlTexto);
    final titulo =
        limparEspacos(doc.querySelector(seletores.detalheTitulo)?.text ?? '');
    final objeto = limparEspacos(
      doc.querySelector(seletores.detalheDescricao)?.text ?? '',
    );
    final corpo = doc.querySelector(seletores.detalheCorpo) ?? doc.body!;
    final campos = extrairCampos(corpo, seletores);

    final docLink = corpo.querySelector(seletores.detalheDocumento);
    final urlDoc =
        docLink == null ? null : Uri.tryParse(docLink.attributes['href'] ?? '');

    String? pega(String chave) => campos.remove(chave);

    return Contrato(
      id: id,
      titulo: titulo,
      objeto: objeto,
      contratado: pega('contratado'),
      cpfCnpj: pega('cpf_cnpj'),
      licitacao: pega('licitacao'),
      valorCentavos: parseReaisEmCentavos(pega('valor')),
      ano: int.tryParse(pega('ano') ?? ''),
      dataAssinatura: parseDataBr(pega('data_da_assinatura')),
      dataInicio: parseDataBr(pega('data_de_inicio')),
      dataFim: parseDataBr(pega('data_de_fim')),
      urlDocumento: urlDoc,
      camposExtras: campos,
    );
  }
}

/// Sobe no DOM até o contêiner do item da lista (`li`/`article`).
Element? ancestralItem(Element e) {
  Element? atual = e.parent;
  while (atual != null) {
    final tag = atual.localName;
    if (tag == 'li' || tag == 'article') return atual;
    atual = atual.parent;
  }
  return null;
}

/// Extrai pares `<strong>Rótulo:</strong> valor` de um bloco em um mapa
/// `chave_normalizada → valor`. Compartilhado por contratos e emendas.
///
/// Funciona tanto com um `<p>` por campo (contratos) quanto com um único
/// `<p>` separado por `<br>` (emendas).
Map<String, String> extrairCampos(Element corpo, SeletoresPrefeitura sel) {
  final campos = <String, String>{};
  for (final p in corpo.querySelectorAll(sel.detalheCampo)) {
    // Divide o parágrafo em "linhas" pelos <br>.
    final linhas = <List<Node>>[[]];
    for (final n in p.nodes) {
      if (n is Element && n.localName == 'br') {
        linhas.add([]);
      } else {
        linhas.last.add(n);
      }
    }
    for (final linha in linhas) {
      Element? rotulo;
      final valor = StringBuffer();
      for (final n in linha) {
        if (rotulo == null &&
            n is Element &&
            n.localName == sel.detalheRotulo) {
          rotulo = n;
        } else if (n is Element) {
          valor.write(n.text);
        } else if (n is Text) {
          valor.write(n.data);
        }
      }
      if (rotulo == null) continue;
      final chave = chaveDeRotulo(rotulo.text);
      if (chave.isEmpty) continue;
      var v = limparEspacos(valor.toString());
      if (v.startsWith(':')) v = limparEspacos(v.substring(1));
      campos[chave] = v;
    }
  }
  return campos;
}
