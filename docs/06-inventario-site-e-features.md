# Inventário completo do site da Prefeitura e backlog de features

Crawl de **www.saojoao.sp.gov.br** em 2026-11-09 (901 páginas HTML, 2 requisições
simultâneas, User-Agent identificado), mais sondagem dos sistemas externos que o site
aponta. Inventário bruto: [`api/samples/crawl-site-2026-11-09.json`](api/samples/crawl-site-2026-11-09.json).

## 1. O que o site é, em números

| Tipo de página | Qtde | O que significa |
|---|---|---|
| Artigo (texto) | 597 | notícias, páginas institucionais, conselhos |
| Lista paginada | 82 | coleções consultáveis (contratos, obras, emendas, leis, editais, agendas…) |
| Repositório de PDFs (≥3) | 58 | documentos de conselhos, programa de metas, EIV/RIV, carta de serviços |
| Pasta eCrie (iframe de arquivos) | 10 | balancetes, folha, concursos, jornal oficial… |
| Formulário | 22 | filtros de busca, cadastro IPTU, consultas públicas |
| Seção | páginas | — |
| `/noticias` | 309 | 501 páginas × 12 notícias ≈ **6.000 notícias**, filtráveis por departamento |
| `/educacao` | 228 | 30+ escolas com página própria, conselhos, cardápios da merenda |
| `/departamentos` | 199 | 22 departamentos, 24+ conselhos municipais |
| `/transparencia` | 52 | o menu de transparência propriamente dito |
| `/obras` | 13 | 35 obras georreferenciadas |

Tecnologia: CMS eCrie (ASP.NET, server-side). Sem API, mas **HTML extremamente regular**:
toda lista usa `li.list-item > a.list-item__link`, `p "Publicado: dd/mm/aaaa"` e
`nav.pagination[aria-label="Paginação: página X de Y"]`; todo detalhe usa
`<strong>Rótulo:</strong> valor`. Um único parser cobre tudo (já é o que
`packages/fontes/prefeitura` faz).

## 2. Datasets estruturados descobertos

Coleções com campos consistentes — candidatas a virar tela no app.

| Dataset | URL | Volume | Campos / filtros | Status no app |
|---|---|---|---|---|
| **Contratos** | `/contratos` | 7.410 (741 pág.) | número, ano, tipo, objeto, razão social; detalhe: CNPJ, licitação, valor, datas, PDF | ✅ |
| **Obras** | `/obras` | 35 (26 concluídas, 7 em andamento, 2 suspensas) | secretaria, situação, endereço, bairro, CEP, datas, empresa, CPF/CNPJ; detalhe: responsável técnico, **lat/long**, valor do contrato, **valor e % de execução financeira** | 🔜 **alta prioridade** |
| **Emendas parlamentares** | `/transparencia/emendas-parlamentares` | 103 | origem, tipo, autoria, forma de repasse, valor, finalidade, função, beneficiário | ✅ |
| **Chamamentos públicos** | `/transparencia/chamamentos-publicos` | ~55 (5 pág.) | extratos de inexigibilidade/justificativa, processo | 🔜 (junto com contratos) |
| **Leis** (destaques) | `/transparencia/leis` | ~30 (3 pág.) | título, PDF | 🔗 melhor via SAPL/leismunicipais |
| **Decretos** (destaques) | `/transparencia/decretos` | 5 | número, ementa, PDF | 🔗 idem |
| **Agenda dos conselhos** | `/transparencia/agenda-de-reunioes-dos-conselhos-municipais` | ~100 (9 pág.) | conselho, data, pauta | 🔜 "participe" |
| **Alterações de trânsito** | `/departamentos/seguranca-e-transito/alteracoes-de-transito` | ~45 (4 pág.) | título, data | 💡 avisos |
| **Interdições no momento** | `/departamentos/seguranca-e-transito/interdicoes-no-momento` | artigo | texto | 💡 avisos |
| **Unidades de saúde** | `/departamentos/saude/unidades-e-telefones-uteis` | 3 pág. | nome, endereço, telefone, ano | 💡 mapa de serviços |
| **Escolas municipais** | `/educacao/escolas-municipais/*` | 30+ | página por escola, mapa, cardápio da merenda semanal | 💡 |
| **Eventos** (agendas) | `/eventos/agenda-geral`, `agenda-cultural`, `agenda-do-esporte` | — | agenda, status, data | 💡 |
| **Notícias** | `/noticias` + RSS `ecrie20.com.br/saojoao.sp.gov.br/feed.xml` | ~6.000 | título, descrição, data, departamento | 💡 "o que a Prefeitura disse sobre isso" |
| **Carta de Serviços** | `/carta-de-servicos` | 31 PDFs | um por departamento | 🔜 "o que devem me oferecer" |
| **Relatórios da Ouvidoria** | `/cidadao/ouvidoria/relatorios` | 6 PDFs (2021–2026) | anual | 🔜 extrair indicadores |
| **Multas: arrecadação e aplicação** | `/departamentos/seguranca-e-transito/arrecadacao-e-aplicacao-de-multas` | 5 PDFs | por período | 💡 cruzar com receita de multas (TCE) |
| **Programa de Metas 2021–24** | `/departamentos/desenvolvimento-economico/programa-de-metas` | 83 PDFs | metas por departamento | 💡 "prometido × entregue" |
| **EIV/RIV** (impacto de vizinhança) | `/departamentos/gestao-e-planejamento-urbano/estudo-e-relatorio-de-impacto-de-vizinhanca` | 95 PDFs | empreendimentos | 💡 "o que vai ser construído perto de mim" |
| **Intervenção na OSS** | `/departamentos/saude/intervencaodaoss` | 46 PDFs | documentos | 💡 contexto para "Quem mais recebe" (saúde) |

### Pastas eCrie (file-browser) além das 22 já catalogadas

| Página | `pasta=` | Conteúdo |
|---|---|---|
| Concursos Públicos | `rh/Concursos` | editais, resultados |
| Jornal Oficial | `imprensa/jornaloficial` | edições do JOM — **onde as leis são publicadas** |
| Quadro de Pessoal | `rh/Despesas Mensal Com Funcionarios/Quadro de Pessoal` | servidores por cargo |
| Vigilância Socioassistencial | `vigilancia` | relatórios da assistência |
| Escala do Dept. de Saúde | `escala_saude` | escalas de médicos por unidade |

Anexos avulsos seguem o padrão `https://ecrie.com.br/sistema/conteudos/arquivo/a_41_*.pdf`
e `https://ecrie.com.br/Sistema/Conteudos/Contratos/c41_*.pdf`.

## 3. Sistemas externos (o que o site só linka)

| Sistema | Host | O que tem | Acesso |
|---|---|---|---|
| **SAPL — Câmara Municipal** | `sapl.saojoaodaboavista.sp.leg.br/api/` | **API REST aberta**: 50 parlamentares (19 mandatos atuais, com partido via `filiacao`), 29.197 matérias (8.528 requerimentos, 47 **emendas impositivas**), 727 sessões (com **vídeo YouTube** e **ata PDF**), 22.160 votações, **27.164 votos nominais**, 11.832 tramitações, normas (leis desde sempre, com ementa e página do JOM) | JSON, sem chave |
| Site da Câmara | `www.saojoaodaboavista.sp.leg.br` (Plone) | vereadores, pautas, sessões, transparência do legislativo | HTML |
| e-OUV / e-SIC | `saojoaodaboavista.eouve.com.br` | ouvidoria + LAI, protocolo | externo (login) |
| SmarAPD serviços | `pm-saojoao.smarapd.com.br/portalservicosweb` | 2ª via IPTU, certidões, processos | externo |
| SmarAPD transparência | `transparencia-saojoaodaboavista.smarapd.com.br` | 2026+ (API fora do ar) | ver [api/smarapd-pai.md](api/smarapd-pai.md) |
| Intertec | `gpmodsaojoaodaboavista.intertecsolucoes.com.br` | 2023–25 (em manutenção) | — |
| leismunicipais.com.br / leis.org | — | leis consolidadas, busca full-text | HTML (links `leismunicipa.is/...`) |
| GERR | `gerr.com.br` (chave 46429379000150) | repasses ao terceiro setor | HTML |
| SimplISS | `saojoao.simplissweb.com.br` | NFS-e | externo |
| BLL Compras | `bllcompras.org.br` | pregões eletrônicos | externo |
| Issuu | `e.issuu.com` | cartilhas (COMAD) | embed |
| TCE-SP / SICONFI | — | receitas e despesas (base do painel) | JSON ✅ |

## 4. Backlog de features (priorizado)

Impacto = o que muda para o cidadão · Esforço = dev part-time · Fonte = de onde vem.

### Prioridade 1 — próximas semanas

| # | Feature | Por quê | Fonte | Esforço |
|---|---|---|---|---|
| F1 | **Obras no mapa** — pinos por obra, cor por situação, cartão com empresa, valor, % executado, prazo; filtro por bairro/secretaria; "obras perto de mim" | É o dado mais tangível do site: a pessoa passa na frente da obra | `/obras` (lat/long, valor, execução) | M |
| F2 | **Vereadores** — lista com foto e partido, o que cada um propôs (requerimentos, indicações, projetos), como votou (votos nominais), presença; emendas impositivas por vereador | Fecha o ciclo "quem fiscaliza": o legislativo é a parte mais invisível | SAPL API | M–G |
| F3 | **Sessões da Câmara** — próximas sessões, pauta, vídeo ao vivo/gravado, ata em PDF; notificação "sessão hoje" | Participação direta sem sair de casa | SAPL `sessaoplenaria` + `cadastro-de-eventos` | P |
| F4 | **Leis e decretos com busca** — ementa, data, publicação no JOM, texto integral; "leis que citam X" | Hoje o cidadão não acha a lei que o afeta | SAPL `normajuridica` (+ leismunicipais) | P–M |
| F5 | **Comparar anos no painel** — mesma métrica lado a lado (receita, gasto por morador, % saúde/educação) 2014→2026; por mandato (2013–16, 17–20, 21–24, 25–28) | Pergunta que o usuário fez: "quem gastou mais / economizou" — com números, sem adjetivos | `dados/*.json` (já existem) | P |
| F6 | **Pastas eCrie novas** — Concursos, Jornal Oficial, Quadro de Pessoal, Vigilância, Escala da Saúde | 5 linhas no catálogo | eCrie | P ✅ (feito nesta rodada) |

### Prioridade 2 — próximo trimestre

| # | Feature | Fonte | Esforço |
|---|---|---|---|
| F7 | **Mínimos constitucionais e LRF** — % em saúde (≥15%) e educação (≥25%), % com pessoal (≤54%), semáforo verde/amarelo/vermelho com explicação | SICONFI RREO/RGF | M |
| F8 | **"O que mudou"** — receitas que apareceram/sumiram vs ano anterior (ex.: nova taxa de lixo), fornecedores novos no top 20, obras que atrasaram | `dados/*.json` diff | P–M |
| F9 | **Fornecedor 360°** — toque num fornecedor do painel → contratos dele (site), empenhos por ano (TCE), obras (site), CNPJ na Receita (link) | TCE + site | M |
| F10 | **Conselhos: participe** — agenda de reuniões, atas, como virar conselheiro; lembrete | site (agenda + 24 páginas de conselhos) | P |
| F11 | **Chamamentos e inexigibilidades** — junto de Contratos, com explicação ("contratação sem disputa: por quê?") | site | P |
| F12 | **Avisos da cidade** — interdições de trânsito, alterações, cata-treco, coleta seletiva, eventos | site (listas) + RSS | P |
| F13 | **Notícias cruzadas** — na tela de uma obra/contrato/área, "o que a Prefeitura publicou sobre isso" | RSS + `/noticias?titulo=` | P |
| F14 | **Carta de Serviços navegável** — "o que cada departamento deve me oferecer e em quanto tempo" | 31 PDFs → texto | M (extração) |
| F15 | **Ouvidoria em números** — reclamações por ano, tempo de resposta, assuntos (dos relatórios anuais) | 6 PDFs | M (extração) |

### Prioridade 3 — visão

| # | Feature | Fonte |
|---|---|---|
| F16 | **Prometido × entregue** — Programa de Metas (83 PDFs) vs obras concluídas e despesa por função | site + TCE |
| F17 | **Meu bairro** — obras, escolas, unidades de saúde, EIV/RIV, interdições num raio do endereço | site (lat/long) |
| F18 | **Alertas personalizados** — novo contrato acima de R$ X, sessão com projeto sobre tema Y, obra do meu bairro mudou de status | tudo acima + push |
| F19 | **Comparar com cidades vizinhas** — mesmas métricas para Águas da Prata, Aguaí, Vargem Grande do Sul… (TCE-SP e SICONFI cobrem todas) | TCE-SP + SICONFI |
| F20 | **Multas: arrecadado × aplicado** — receita de multas (TCE) vs relatório de aplicação (PDF) — a lei exige que seja gasto em trânsito | TCE + 5 PDFs |
| F21 | **Linha do tempo da lei** — projeto (autor, votação nominal) → lei → publicação no JOM → gasto correspondente | SAPL + TCE |
| F22 | **Modo "explique pra mim"** — qualquer tela resumida em 3 frases com os termos do glossário | local |
| F23 | **Replicar para outro município** — tudo que é SJBV vira `config/municipios/sjbv.json`; eCrie, SmarAPD, SAPL, TCE-SP e SICONFI atendem centenas de cidades paulistas | — |

## 5. Regras que valem para todas as features

1. **Fonte da verdade é sempre o site/API oficial.** Toda tela mostra procedência (host + data/hora) e link para o original.
2. **Números, não adjetivos.** O app compara e explica; "gastou mal" é conclusão do cidadão, do TCE ou da Justiça.
3. **Nada que o cidadão já não possa ver.** Só dados públicos por força da LAI/LC 131. Nomes de servidores e CPFs aparecem como no original (CPF mascarado quando o original mascara).
4. **Uso responsável das fontes.** Cache agressivo, 2 conexões por host, agregação pesada no GitHub Actions — nunca no celular.
5. **Cada feature começa por uma pergunta** ("tem obra perto de mim?", "meu vereador votou como?") e termina num botão de ação ("pedir explicação", "ir à sessão", "participar do conselho").
