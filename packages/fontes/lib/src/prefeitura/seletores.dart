/// Seletores CSS do CMS eCrie (www.saojoao.sp.gov.br).
///
/// **Único lugar** onde seletores do site aparecem. Se o layout mudar, o
/// conserto é aqui (e, no app, via config remota que sobrescreve estes
/// valores). Mantenha os nomes estáveis.
class SeletoresPrefeitura {
  const SeletoresPrefeitura({
    this.listaLink = 'a.list-item__link',
    this.listaDescricao = '.list-description',
    this.listaPublicado = 'p',
    this.paginacao = 'nav.pagination',
    this.detalheTitulo = 'h1.post-title, h1.page-heading',
    this.detalheDescricao = 'p.page-description',
    this.detalheCorpo = 'article.post-text, .post-content, #conteudo',
    this.detalheCampo = 'p',
    this.detalheRotulo = 'strong',
    this.detalheDocumento = 'a[data-btn][href], a[href\$=".pdf"]',
  });

  final String listaLink;
  final String listaDescricao;
  final String listaPublicado;
  final String paginacao;
  final String detalheTitulo;
  final String detalheDescricao;
  final String detalheCorpo;
  final String detalheCampo;
  final String detalheRotulo;
  final String detalheDocumento;

  static const padrao = SeletoresPrefeitura();
}
