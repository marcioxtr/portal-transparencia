/// Endpoints do SmarAPD PAI extraídos do bundle do portal oficial
/// (`static/js/main.518d6fa9.chunk.js`, 2026-11-08).
///
/// Caminhos relativos a `{host}/paiportalserver/`. Documentação completa,
/// payloads e pendências em `docs/api/smarapd-pai.md`.
abstract final class SmarapdEndpoints {
  static const prefixoDados = 'paiportalserver';
  static const prefixoArquivos = 'paifileserver';

  // Bootstrap
  static const cliente = 'cliente';
  static const configuracaoAparencia = 'configuracaoaparencia';
  static const menuPortal = 'MenuPortal';
  static const exercicio = 'exercicio';
  static String moduloHabilitado(String chave) => 'Modulo/habilitado/$chave';
  static String moduloConfiguracoes(String chave) =>
      'modulo/$chave/configuracoes';

  // Home
  static String home(int ano) => 'home/$ano';

  // Visões dinâmicas
  static String visaoConfiguracao(String modulo, String visao) =>
      'modulovisao/$modulo/$visao/configuracao';
  static String colunasFiltro(String modulo) => 'Modulo/$modulo/colunasfiltro';
  static const periodicidade = 'periodicidade';
  static const periodicidadePeriodos = 'periodicidade/periodos';
  static const visaoFilter = 'modulovisao/filter'; // POST
  static const visaoTotalizadoras = 'modulovisao/colunasTotalizadoras'; // POST
  static const visaoTextoColuna = 'modulovisao/textocoluna'; // POST
  static const visaoFiltroAvancado = 'ModuloVisao/filtroavancado'; // POST
  static String visaoFixa(String modulo, String visao) =>
      'modulovisao/fixo/$modulo/$visao';
  static String visaoFixaItem(String modulo, String visao, int item) =>
      'ModuloVisaoItemDetalhe/$modulo/$visao/$item';
  static const exportarDinamico = 'modulovisao/exportar/dinamico/'; // POST
  static const exportarFixo = 'modulovisao/exportar/fixo/'; // POST

  // Detalhe analítico
  static String detalhePeriodos(String modulo, String visao) =>
      'detalhevisaoanalitica/periodos/$modulo/$visao';
  static const detalheFilter = 'detalhevisaoanalitica/filter'; // POST
  static const detalheExportar = 'detalhevisaoanalitica/exportar/detalhe/';

  // Anexos
  static const arquivosDigitais = 'ModuloArquivoDigital/arquivos'; // POST
  static String download(String nomeArquivo, {bool inline = false}) =>
      'filemanager/pai/download?nomeArquivo=${Uri.encodeQueryComponent(nomeArquivo)}'
      '${inline ? '&isInlineContent=true' : ''}';

  // e-SIC
  static const esicConfiguracoes = 'esic/configuracoes';
  static const esicExercicios = 'esic/exercicios';
  static String esicVisoes(int ano) => 'esic/visoes/exercicio/$ano';
  static String esicGrafico(int ano) => 'esic/grafico/exercicio/$ano';

  // Busca de documentos
  static const buscaModulos = 'BuscaDocumento/modulos';
  static const busca = 'BuscaDocumento/busca'; // POST

  // Outros
  static const dadosAbertos = 'DadosAbertos';
  static const estruturaOrganizacional = 'estruturaOrganizacional';
  static String estruturaDetalhe(int id) =>
      'estruturaOrganizacional/$id/detalhe';
  static const faq = 'faq';
  static const glossario = 'glossario';
  static const autenticidadeConfiguracoes = 'autenticidade/configuracoes';
  static String autenticidadeObter(String codigo) =>
      'autenticidade/obter/$codigo';

  // Estatísticas de acesso (leitura). `POST Estatistica` é telemetria do
  // portal oficial e NÃO deve ser chamado pelo app.
  static const estatisticaAnos = 'estatistica/anos';
  static const estatisticaGraficoAno = 'estatistica/grafico/ano/portal';
}
