/// Catálogo das pastas do file-browser eCrie que o site da Prefeitura embute
/// em `<iframe>` nas páginas de "Transparência até 2022".
///
/// Mapeado em 2026-11-08 a partir de `/transparencia/contas-publicas/*` e
/// páginas afins. Ver `docs/api/site-prefeitura.md`.
class PastaLegado {
  const PastaLegado({
    required this.id,
    required this.titulo,
    required this.pasta,
    required this.categoria,
    this.paginaSite,
  });

  /// Identificador estável para uso no app (rotas, cache, favoritos).
  final String id;
  final String titulo;

  /// Valor do parâmetro `pasta=` (sem URL-encoding).
  final String pasta;
  final String categoria;

  /// Caminho da página no site da prefeitura que embute esta pasta.
  final String? paginaSite;
}

const pastasLegado = <PastaLegado>[
  PastaLegado(
    id: 'despesas-funcionarios',
    titulo: 'Despesas com Funcionários',
    pasta: 'rh/Despesas Mensal Com Funcionarios',
    categoria: 'Pessoal',
    paginaSite: '/transparencia/despesas-com-funcionarios',
  ),
  PastaLegado(
    id: 'atas-audiencias',
    titulo: 'Atas de Audiências Públicas',
    pasta: 'transparencia/Atas De Audiência Pública',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/atas-de-audiencias-publicas',
  ),
  PastaLegado(
    id: 'balancetes',
    titulo: 'Balancetes',
    pasta: 'transparencia/Balancetes',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/balancetes',
  ),
  PastaLegado(
    id: 'balancos',
    titulo: 'Balanços',
    pasta: 'transparencia/Balancos',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/balancos',
  ),
  PastaLegado(
    id: 'despesas-publicidade',
    titulo: 'Despesas com Publicidade',
    pasta: 'transparencia/Despesas com Publicidade',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/despesas-com-publicidade',
  ),
  PastaLegado(
    id: 'despesas-diarias',
    titulo: 'Despesas Diárias',
    pasta: 'transparencia/Despesas Diárias',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/despesas-diarias',
  ),
  PastaLegado(
    id: 'diarias-pessoal-civil',
    titulo: 'Diárias Pessoal Civil',
    pasta: 'transparencia/Diarias Pessoal Civil',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/diarias-pessoal-civil',
  ),
  PastaLegado(
    id: 'patrimonio',
    titulo: 'Patrimônio',
    pasta: 'transparencia/Patrimonio',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/patrimonio',
  ),
  PastaLegado(
    id: 'planejamento-orcamentario',
    titulo: 'Planejamento Orçamentário',
    pasta: 'transparencia/Planejamento Orcamentario',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/planejamento-orcamentario',
  ),
  PastaLegado(
    id: 'multas-transito',
    titulo: 'Receitas de Multas de Trânsito',
    pasta: 'transparencia/Receitas de Multas de Trânsito',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/receitas-de-multas-de-transito',
  ),
  PastaLegado(
    id: 'receitas-diarias',
    titulo: 'Receitas Diárias',
    pasta: 'transparencia/Receitas Diárias',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/receitas-diarias',
  ),
  PastaLegado(
    id: 'tce-recibos-pareceres',
    titulo: 'Recibos e Pareceres do TCE-SP',
    pasta:
        'transparencia/Recibos e Pareceres do Tribunal de Contas do Estado de Sao Paulo',
    categoria: 'Contas Públicas',
    paginaSite:
        '/transparencia/contas-publicas/recibos-e-pareceres-do-tribunal-de-contas-do-estado-de-sao-paulo',
  ),
  PastaLegado(
    id: 'regime-adiantamento',
    titulo: 'Regime Especial de Adiantamento',
    pasta: 'transparencia/Regime Especial de Adiantamento',
    categoria: 'Contas Públicas',
    paginaSite:
        '/transparencia/contas-publicas/regime-especial-de-adiantamento',
  ),
  PastaLegado(
    id: 'lrf-siconfi-sistn',
    titulo: 'Relatórios da LRF, SICONFI e SISTN',
    pasta:
        'transparencia/Relatorios da Lei de Responsabilidade Fiscal, SICONFI e SISTN',
    categoria: 'Contas Públicas',
    paginaSite:
        '/transparencia/contas-publicas/relatorios-da-lei-de-responsabilidade-fiscal-siconfi-e-sistn',
  ),
  PastaLegado(
    id: 'saude-siops',
    titulo: 'Relatórios de Contas da Saúde e SIOPS',
    pasta: 'transparencia/Relatorios de Contas da Saude e SIOPS',
    categoria: 'Contas Públicas',
    paginaSite:
        '/transparencia/contas-publicas/relatorios-de-contas-da-saude-e-siops',
  ),
  PastaLegado(
    id: 'ensino-siope',
    titulo: 'Relatórios de Contas do Ensino e SIOPE',
    pasta: 'transparencia/Relatorios de Contas do Ensino e SIOPE',
    categoria: 'Contas Públicas',
    paginaSite:
        '/transparencia/contas-publicas/relatorios-de-contas-do-ensino-e-siope',
  ),
  PastaLegado(
    id: 'duodecimo-camara',
    titulo: 'Repasse de Duodécimo à Câmara',
    pasta: 'transparencia/Repasse de Duodécimo à Câmara',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/repasse-de-duodecimo-a-camara',
  ),
  PastaLegado(
    id: 'terceiro-setor',
    titulo: 'Repasses ao Terceiro Setor',
    pasta:
        'transparencia/Repasses ao Terceiro Setor - Leis 13.019-2014 e 12.527-2011',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/repasses-ao-terceiro-setor',
  ),
  PastaLegado(
    id: 'repasses-financeiros',
    titulo: 'Repasses Financeiros',
    pasta: 'transparencia/Repasses Financeiros',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/repasses-financeiros',
  ),
  PastaLegado(
    id: 'siafic',
    titulo: 'SIAFIC',
    pasta: 'transparencia/SIAFIC',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/siafic',
  ),
  PastaLegado(
    id: 'subsidio-transporte',
    titulo: 'Subsídio do Transporte Público',
    pasta: 'transparencia/Subsídio do Transporte Público',
    categoria: 'Contas Públicas',
    paginaSite: '/transparencia/contas-publicas/subsidio-do-transporte-publico',
  ),
  PastaLegado(
    id: 'transferencias-uniao',
    titulo: 'Transferências de Recursos da União',
    pasta:
        'transparencia/Transferências de Recursos da União - Lei Federal 9.452-1997',
    categoria: 'Contas Públicas',
    paginaSite:
        '/transparencia/contas-publicas/transferencias-de-recursos-da-uniao',
  ),
  // Descobertas no crawl completo de 2026-11-09 (docs/06-inventario-site-e-features.md)
  PastaLegado(
    id: 'quadro-pessoal',
    titulo: 'Quadro de Pessoal',
    pasta: 'rh/Despesas Mensal Com Funcionarios/Quadro de Pessoal',
    categoria: 'Pessoal',
    paginaSite: '/transparencia/quadro-de-pessoal',
  ),
  PastaLegado(
    id: 'concursos',
    titulo: 'Concursos Públicos',
    pasta: 'rh/Concursos',
    categoria: 'Pessoal',
    paginaSite: '/transparencia/concursos-publicos',
  ),
  PastaLegado(
    id: 'jornal-oficial',
    titulo: 'Jornal Oficial do Município',
    pasta: 'imprensa/jornaloficial',
    categoria: 'Publicações oficiais',
    paginaSite: '/jornal-oficial',
  ),
  PastaLegado(
    id: 'escala-saude',
    titulo: 'Escala de trabalho da Saúde',
    pasta: 'escala_saude',
    categoria: 'Saúde e Assistência',
    paginaSite:
        '/departamentos/saude/escala-de-trabalho-do-departamento-de-saude',
  ),
  PastaLegado(
    id: 'vigilancia-socioassistencial',
    titulo: 'Vigilância Socioassistencial',
    pasta: 'vigilancia',
    categoria: 'Saúde e Assistência',
    paginaSite:
        '/departamentos/assistencia-social/vigilancia-socioassistencial',
  ),
];
