import 'package:html/parser.dart' as html;

import '../modelos/modelos.dart';

/// Parser da árvore de arquivos do file-browser eCrie
/// (`https://ecrie.com.br/home/_arq/{cliente}/Default.aspx?pasta=…`).
///
/// O HTML já vem com a árvore inteira. Em vez de depender da estrutura de
/// `<table>`/`<div>` do TreeView ASP.NET, reconstruímos a hierarquia a partir
/// dos **caminhos**: cada arquivo é `<a target="_blank" href="rel/path.pdf">` e
/// cada pasta aparece num `__doPostBack('tvArquivos','sF:*|*…*|*{cliente}*|*a*|*b')`.
class ArvoreEcrieParser {
  const ArvoreEcrieParser({required this.baseArquivos});

  /// Ex.: `https://ecrie.com.br/home/_arq/41/`
  final Uri baseArquivos;

  static final _postBack = RegExp(r"__doPostBack\('tvArquivos','(.*?)'\)");
  static final _soDigitos = RegExp(r'^\d+$');

  NoArquivo parse(String htmlTexto, {required String pastaRaiz}) {
    final doc = html.parse(htmlTexto);
    final raizNorm = _norm(pastaRaiz);
    final raiz = _PastaTmp(nome: _ultimo(raizNorm), caminho: raizNorm);

    // 1) Pastas (garante que pastas vazias também apareçam).
    for (final a
        in doc.querySelectorAll('a[href^="javascript:__doPostBack"]')) {
      final m = _postBack.firstMatch(a.attributes['href'] ?? '');
      if (m == null) continue;
      final caminho = _caminhoDoPostBack(m.group(1)!);
      if (caminho != null) _garantirPasta(raiz, caminho);
    }

    // 2) Arquivos. O TreeView renderiza cada arquivo duas vezes (link do
    //    ícone e link do texto), então deduplicamos pelo caminho.
    final vistos = <String>{};
    for (final a in doc.querySelectorAll('a[target="_blank"][href]')) {
      final href = a.attributes['href']!;
      if (href.startsWith('javascript:') ||
          href.startsWith('#') ||
          href.startsWith('http')) {
        continue;
      }
      final caminho = _norm(Uri.decodeFull(href));
      if (!vistos.add(caminho)) continue;
      final pastaPai = caminho.contains('/')
          ? caminho.substring(0, caminho.lastIndexOf('/'))
          : '';
      final pasta = _garantirPasta(raiz, pastaPai);
      pasta.arquivos.add(NoArquivo.arquivo(
        nome: _ultimo(caminho),
        caminho: caminho,
        url: baseArquivos.resolve(href),
      ));
    }

    return raiz.congelar();
  }

  /// `sF:*|*Produtos*|*ecrie.com.br*|*home*|*_arq*|*41*|*rh*|*X*|*2015\\F:*|*…*|*2015*|*2022`
  /// → `rh/X/2015/2022` (último segmento após `\\`; descarta tudo até o id
  /// numérico do cliente).
  String? _caminhoDoPostBack(String arg) {
    final ultimo = arg.split(r'\\').last;
    final partes = ultimo.split('*|*');
    final idx = partes.indexWhere(_soDigitos.hasMatch);
    if (idx < 0 || idx + 1 >= partes.length) return null;
    return _norm(partes.sublist(idx + 1).join('/'));
  }

  _PastaTmp _garantirPasta(_PastaTmp raiz, String caminho) {
    if (caminho.isEmpty || caminho == raiz.caminho) return raiz;
    final rel = caminho.startsWith('${raiz.caminho}/')
        ? caminho.substring(raiz.caminho.length + 1)
        : caminho;
    var atual = raiz;
    var acumulado = raiz.caminho;
    for (final seg in rel.split('/')) {
      if (seg.isEmpty) continue;
      acumulado = acumulado.isEmpty ? seg : '$acumulado/$seg';
      final cam = acumulado;
      atual = atual.subpastas.putIfAbsent(
        seg,
        () => _PastaTmp(nome: seg, caminho: cam),
      );
    }
    return atual;
  }

  static String _norm(String s) => s
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+'), '/')
      .replaceAll(RegExp(r'^/|/$'), '');

  static String _ultimo(String caminho) =>
      caminho.contains('/') ? caminho.split('/').last : caminho;
}

class _PastaTmp {
  _PastaTmp({required this.nome, required this.caminho});
  final String nome;
  final String caminho;
  final Map<String, _PastaTmp> subpastas = {};
  final List<NoArquivo> arquivos = [];

  NoArquivo congelar() {
    final pastas = subpastas.values.map((p) => p.congelar()).toList()
      ..sort((a, b) => compararNatural(a.nome, b.nome));
    final arqs = [...arquivos]..sort((a, b) => compararNatural(a.nome, b.nome));
    return NoArquivo.pasta(
      nome: nome,
      caminho: caminho,
      filhos: [...pastas, ...arqs],
    );
  }
}

/// Ordenação "natural": números dentro de nomes são comparados numericamente,
/// então `2012 09` vem antes de `2012 10` e `2013` depois de `2012`.
int compararNatural(String a, String b) {
  final re = RegExp(r'\d+|\D+');
  final ra = re.allMatches(a).map((m) => m.group(0)!).toList();
  final rb = re.allMatches(b).map((m) => m.group(0)!).toList();
  for (var i = 0; i < ra.length && i < rb.length; i++) {
    final na = int.tryParse(ra[i]);
    final nb = int.tryParse(rb[i]);
    final c = (na != null && nb != null)
        ? na.compareTo(nb)
        : ra[i].toLowerCase().compareTo(rb[i].toLowerCase());
    if (c != 0) return c;
  }
  return ra.length.compareTo(rb.length);
}
