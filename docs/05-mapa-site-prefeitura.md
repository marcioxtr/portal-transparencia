# Mapa do site da Prefeitura e features derivadas

Levantado em 2026-11-09 a partir de `/mapa-do-site` (221 links). Agrupado pelo que
interessa ao cidadão e marcado com o que o app pode fazer com cada seção.

Legenda: ✅ já no app · 🔜 próximo · 💡 ideia · 🔗 só link externo

## Transparência (o núcleo)

| Seção | URL | Formato | App |
|---|---|---|---|
| Contratos | `/contratos` | HTML paginado | ✅ |
| Emendas Parlamentares | `/transparencia/emendas-parlamentares` | HTML | ✅ |
| Transparência até 2022 (PDFs) | `/transparencia/contas-publicas/*` | iframe eCrie | ✅ |
| Transparência 2023–25 (Intertec) | externo | APEX | ⛔ fora do ar → TCE-SP |
| Transparência 2026+ (SmarAPD) | externo | API JSON | ⏳ API instável → TCE-SP/SICONFI |
| Compras e Licitações | `/transparencia/compras-e-licitacoes` | HTML/links | 🔜 |
| Leis / Decretos / Atos | `/transparencia/leis`, `/decretos`, `/atos-municipais` | HTML paginado | 🔜 busca de leis (ou via leismunicipais.com.br) |
| Chamamentos Públicos | `/transparencia/chamamentos-publicos` | HTML | 💡 |
| Agenda de Reuniões dos Conselhos | `/transparencia/agenda-de-reunioes-dos-conselhos-municipais` | HTML | 💡 "participe" com lembrete |
| Estrutura Organizacional | `/transparencia/estrutura-organizacional-da-prefeitura` | HTML/PDF | 🔜 organograma |
| Transparência Fiscal | `/transparencia/transparencia-fiscal` | links | 🔜 |
| Despesas com Funcionários | `/transparencia/despesas-com-funcionarios` | eCrie PDFs | ✅ |
| Relação de Cargos e Salários / Quadro de Pessoal | `/transparencia/relacao-de-cargos-e-salarios`, `/quadro-de-pessoal` | HTML/PDF | 🔜 |
| Despesas com Publicidade | `/transparencia/despesas-com-publicidade` | eCrie | ✅ |
| Diárias | `/transparencia/diaria-pessoal-civil` | eCrie | ✅ |
| Convênios | `/transparencia/liberacao-de-recursos-convenios` | links federais | 🔗 |
| Planejamento Orçamentário (PPA/LDO/LOA) | `/transparencia/planejamento-orcamentario` | eCrie | ✅ |
| Relação de Bens | `/transparencia/relacao-de-bens` | eCrie | ✅ |
| Concursos / Processos Seletivos | `/transparencia/concursos-publicos`, `/processos-seletivos` | HTML | 💡 alerta de vagas |
| COVID-19 | `/transparencia/covid-19` | HTML | histórico |
| O que é o e-SIC | `/transparencia/o-que-e-o-e-sic` | texto | ✅ glossário |

## Cobrar a Prefeitura (participação)

| Seção | URL | App |
|---|---|---|
| Ouvidoria / e-OUV | `https://saojoaodaboavista.eouve.com.br` | 🔜 botão "Fazer reclamação" |
| e-SIC (pedido de informação) | via e-OUV | 🔜 botão com modelo de texto pré-preenchido |
| Relatórios da Ouvidoria | `/cidadao/ouvidoria/relatorios` | 💡 quantas reclamações, prazo médio |
| Carta de Serviços | `/carta-de-servicos` | 💡 "o que a Prefeitura deve me oferecer" |
| Modelos de Requerimentos | `/cidadao/modelos-de-requerimentos` | 🔜 |
| Conselhos Municipais (24+) | `/conselhos-municipais`, `/departamentos/*/conselho-*` | 💡 como participar |
| Consulta Pública | `/servicos/consulta-publica` | 💡 |
| Consulta de Processos | `/servicos/consulta-de-processos` | 🔗 |
| Câmara Municipal | `https://www.saojoaodaboavista.sp.leg.br` (Plone + SAPL) | 🔜 vereadores, projetos, sessões (SAPL tem API REST) |

## Serviços do dia a dia (fora do escopo "transparência", mas úteis)

| Seção | URL |
|---|---|
| 2ª via IPTU / certidões | `https://pm-saojoao.smarapd.com.br/portalservicosweb` |
| Atualização cadastral IPTU | `/atualizacao-cadastral-de-iptu` |
| NFS-e | `https://pm-saojoao.smarapd.com.br/tb/loginISSContribuinte.jsp` |
| Coleta seletiva / Cata-Treco | `/servicos/coleta-seletiva`, `/noticias/destaques/veja-os-dias-de-coleta-cata-treco-no-seu-bairro` |
| Interdições de trânsito | `/departamentos/seguranca-e-transito/interdicoes-no-momento` |
| Multas: arrecadação e aplicação | `/departamentos/seguranca-e-transito/arrecadacao-e-aplicacao-de-multas` |
| Saúde: unidades e telefones, escala, farmácia | `/departamentos/saude/*` |
| Educação: escolas, EJA, período integral | `/educacao/*` |
| Obras | `/obras` |
| Jornal Oficial | `/jornal-oficial` |
| Notícias por departamento (RSS) | `/noticias/*`, `https://ecrie20.com.br/saojoao.sp.gov.br/feed.xml` |
| Bem-estar animal: adoção, castração | `/departamentos/protecao-e-bem-estar-animal/*` |

## Departamentos (22)

Gabinete, Administração, Desenvolvimento Econômico, Trânsito e Segurança, Assistência
Social, Comunicação Social, Educação, Engenharia, Esportes, Finanças, Procuradoria,
Meio Ambiente/Agricultura, Gestão e Planejamento Urbano, Recursos Humanos, Saúde,
Obras e Serviços Públicos, Turismo, Habitação, TI, Bem-Estar Animal, Cultura,
Controladoria-Geral.

💡 No app: cada **função de governo** do painel (Saúde, Educação…) linka para o
departamento correspondente, seus conselhos e sua página de notícias — "quem cuida
disso e como falar com eles".

## Fontes oficiais externas que alimentam o painel

| Fonte | Endpoint | O que dá |
|---|---|---|
| **TCE-SP** | `transparencia.tce.sp.gov.br/api/json/despesas/sao-joao-da-boa-vista/{ano}/{mes}` | cada empenho/liquidação/pagamento: órgão, fornecedor, valor |
| **TCE-SP** | `…/api/json/receitas/sao-joao-da-boa-vista/{ano}/{mes}` | arrecadação por alínea (IPTU, ISS, COSIP, FPM…) e fonte |
| **SICONFI** | `apidatalake.tesouro.gov.br/ords/siconfi/tt/dca?an_exercicio=…&no_anexo=DCA-Anexo I-E&id_ente=3549102` | despesa anual por função (saúde, educação…) + população |
| **SICONFI** | `…/rreo?…&no_anexo=RREO-Anexo 02` | mesma coisa, bimestral, para o ano em curso |
| **SAPL (Câmara)** | `sapl.saojoaodaboavista.sp.leg.br/api/` | vereadores, matérias, votações (a mapear) |
| **TSE dados abertos** | `dadosabertos.tse.jus.br` | prefeitos/vereadores eleitos por mandato (a mapear) |

Dados TCE-SP disponíveis a partir de **2014** (2008–2013 retornam vazio).

## Features do painel (o que a tela Início passa a responder)

1. **Quanto entrou e quanto saiu este ano** — receita vs despesa (empenhado/liquidado/pago), mês a mês.
2. **De onde vem o dinheiro** — IPTU, ISS, taxas, COSIP, FPM, ICMS, IPVA, FUNDEB, SUS… com explicação de uma linha cada.
3. **Para onde vai** — por função (Saúde, Educação, Urbanismo…) e por órgão (Prefeitura, Câmara, FAE, Previdência).
4. **Quem recebe** — top fornecedores do ano, com filtro "só empresas" (exclui folha/transferências internas).
5. **Por habitante** — tudo dividido pela população (SICONFI) para fazer sentido.
6. **Comparar anos / gestões** — mesma métrica lado a lado por mandato (2013–16, 2017–20, 2021–24, 2025–28). Nomes de prefeitos entram quando a fonte TSE estiver integrada — o app mostra o número, não o adjetivo: cabe ao cidadão julgar.
7. **Cobrar** — do dado para a ação: botão "pedir explicação" abre e-SIC com texto pré-preenchido citando o empenho/contrato.
