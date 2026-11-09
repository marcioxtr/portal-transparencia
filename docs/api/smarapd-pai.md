# API — SmarAPD PAI (Portal de Acesso à Informação)

> Fonte: **"Transparências a partir de 2026"**
> URL pública: <https://transparencia-saojoaodaboavista.smarapd.com.br/#/>
> Status do mapeamento: **endpoints extraídos do bundle JS do portal (engenharia reversa do front-end)**; o formato de resposta de cada endpoint ainda precisa ser capturado com o portal aberto no navegador (ver [Pendências](#pendências)).

## Visão geral

O portal é um SPA React (`pai-webapp`, webpack, Ant Design, Redux + redux-saga) que consome dois back-ends hospedados **no mesmo host** do portal:

| Base URL | Papel |
|---|---|
| `https://transparencia-saojoaodaboavista.smarapd.com.br/paiportalserver` | API de dados (JSON) |
| `https://transparencia-saojoaodaboavista.smarapd.com.br/paifileserver` | Download de arquivos (PDF/planilhas) |

Trecho relevante do bundle (`static/js/main.518d6fa9.chunk.js`):

```js
const { protocol, host } = window.location;
function re(e) { return `${protocol}//${host}/${e}`; }
baseURL_dados    = re("paiportalserver");
baseURL_arquivos = re("paifileserver");
```

O produto é multi-tenant: o mesmo software atende várias prefeituras e **identifica o município pela origem da requisição**. Chamadas sem contexto de origem retornam:

```
HTTP 400  "Não foi possível obter a origem da requisição."
```

Isso significa que o app móvel precisará enviar `Referer`/`Origin` apontando para o host do portal (exatamente como o SPA faz), ou — alternativa mais robusta e transparente — usar um pequeno proxy/BFF do projeto. Ver [docs/03-arquitetura.md](../03-arquitetura.md).

Não há autenticação, token ou cookie de sessão nas chamadas de leitura.

## Rotas do SPA (react-router)

Úteis para entender a navegação e replicá-la no app.

| Rota | Tela |
|---|---|
| `/` | Home (cards/gráficos do exercício atual) |
| `/dinamico/:modulo/:visao` | Listagem de uma "visão" (tabela paginada com filtros) |
| `/dinamico/:modulo/:visao/busca` | Filtro avançado de uma visão |
| `/dinamico/:modulo/:visao/detalhevisao` | Detalhe analítico (drill-down) de uma visão |
| `/fixo/:modulo/:visao` | Visão "fixa" (conteúdo editorial / listas de arquivos) |
| `/fixo/:modulo/:visao/:itemVisao` | Item de uma visão fixa |
| `/esic` | e-SIC — estatísticas de pedidos de informação |
| `/estatisticas` | Estatísticas de acesso ao portal |
| `/estrutura_organizacional` | Organograma |
| `/estrutura_organizacional/detalhe/:id/` | Detalhe de órgão/unidade |
| `/dados_abertos` | Dados abertos (exportações por módulo) |
| `/busca_documentos` | Busca textual em documentos |
| `/autenticidade` | Verificação de autenticidade de documento |
| `/faleconosco` | Formulário Fale Conosco |
| `/faq` | Perguntas frequentes |
| `/glossario` | Glossário |
| `/sumario` | Sumário (mapa do portal) |
| `/manutencao`, `/notfound`, `/smar` | Utilitárias |

## Endpoints — `paiportalserver`

Todos os caminhos são relativos à base `…/paiportalserver/`. Convenção: `GET` salvo indicação.

### Configuração / bootstrap

| Método | Caminho | Uso no front | Observações |
|---|---|---|---|
| GET | `cliente` | Dados do município (razão social, brasão, links) | Chamado no boot junto com `configuracaoaparencia` |
| GET | `configuracaoaparencia` | Tema: `BannerUrl`, `BrasaoUrl`, `BrasaoPretoBrancoUrl`, `ImagemFundoHomeUrl`, `ImagemFundoTelasUrl`, `CorTema`, `Titulo`, `CorFonteTituloPortal`, … | Campos lidos diretamente do bundle |
| GET | `MenuPortal` | Árvore de menus (módulos → visões) | **Endpoint-chave**: define tudo o que o portal expõe. Cada item tem `URI`, `Titulo`, filhos |
| GET | `exercicio` | Exercícios (anos) disponíveis | |
| GET | `Modulo/habilitado/{chave}` | 200 = módulo habilitado | Chaves fixas conhecidas: `sumario`, `faleconosco`, `autenticidade`, `busca_documentos` |
| GET | `modulo/{chaveModulo}/configuracoes` | Configurações do módulo | |
| GET | `pagina` | Conteúdo de página editorial | |
| GET | `titulo` | Título de página | |

### Home

| Método | Caminho | Observações |
|---|---|---|
| GET | `/home/{ano}` | Widgets/cards da home para o exercício `ano` (layout em grid: `id`, `position`) |
| GET | `/home/{a}/{b}` | Variante com dois parâmetros (provável: ano + widget) |

### Visões dinâmicas (o coração dos dados: receitas, despesas, servidores, licitações, contratos…)

| Método | Caminho | Observações |
|---|---|---|
| GET | `modulovisao/{chaveModulo}/{nomeVisao}/configuracao` | Metadados da visão: colunas, `ModoVisao`, `Titulo`, `UrlExportacao`, texto de ajuda, "Página de Origem das Informações" |
| GET | `Modulo/{chaveModulo}/colunasfiltro` | Colunas filtráveis do módulo |
| GET | `filtros` | Filtros disponíveis |
| GET | `periodicidade` | Periodicidades (`MENSAL`, etc.) |
| GET | `periodicidade/periodos` | Períodos de uma periodicidade |
| GET | `periodo` | Período corrente |
| GET | `quantidaderegistros` | Opções de tamanho de página |
| GET | `listacolunaordem` | Ordenação padrão |
| GET | `visao` | Dados da visão (consulta simples) |
| GET | `colunafiltroredirecionavisao`, `valorfiltroredirecionavisao`, `tipovalorfiltroredirecionavisao` | Suporte a *drill-down* entre visões (parâmetros também viajam na query string) |
| **POST** | `modulovisao/filter` | **Consulta paginada da visão** — ver payload abaixo |
| POST | `modulovisao/colunasTotalizadoras` | Totais das colunas numéricas para o filtro atual |
| POST | `modulovisao/textocoluna` | Texto longo de uma célula |
| POST | `ModuloVisao/filtroavancado` | Filtro avançado (campos `Campo`, `Valor`, `TipoValor`) |
| GET | `modulovisao/fixo/{chaveModulo}/{nomeVisao}` | Conteúdo de visão fixa |
| GET | `ModuloVisaoItemDetalhe/{modulo}/{visao}/{itemId}` | Item de visão fixa |
| POST | `modulovisao/exportar/dinamico/` | Exportar visão dinâmica (CSV/XLS/PDF) |
| POST | `modulovisao/exportar/fixo/` | Exportar visão fixa |

**Payload de `POST modulovisao/filter`** (extraído do bundle):

```json
{
  "ChaveModulo": "string",
  "NomeVisao": "string",
  "Filtros": [ { "Campo": "string", "Valor": "string", "TipoValor": "string" } ],
  "Periodicidade": "MENSAL",
  "Periodo": "string|null",
  "Exercicio": 2026,
  "Pagina": 1,
  "QuantidadeRegistros": 10,
  "Ordenacao": [ { "Coluna": "string", "Direcao": "ASC|DESC" } ],
  "FiltroRedirecionaVisao": null
}
```

**Resposta** (shape inferido do tratamento de erro no front):

```json
{ "QuantidadePaginas": 0, "QuantidadeRegistros": 0, "Valores": [ ] }
```

### Detalhe analítico (drill-down)

| Método | Caminho | Observações |
|---|---|---|
| GET | `detalhevisaoanalitica/periodos/{modulo}/{visao}` | Períodos disponíveis no detalhe |
| POST | `detalhevisaoanalitica/filter` | Consulta do detalhe; resposta tem `Dados: []` |
| POST | `detalhevisaoanalitica/exportar/detalhe/` | Exportação do detalhe |

### Arquivos digitais / anexos

| Método | Caminho | Observações |
|---|---|---|
| POST | `ModuloArquivoDigital/arquivos` | "Listagem dos Anexos" de um registro |
| GET (`paifileserver`) | `filemanager/pai/download?nomeArquivo={nome}` | Download. Para PDF o front acrescenta `&isInlineContent=true` |

### e-SIC

| Método | Caminho |
|---|---|
| GET | `esic/configuracoes` |
| GET | `esic/exercicios` |
| GET | `esic/visoes/exercicio/{ano}` |
| GET | `esic/grafico/exercicio/{ano}` |
| GET | `esic/grafico/{tipo}/filtrar/{a}/{b}` |

### Estatísticas de acesso

| Método | Caminho |
|---|---|
| GET | `/estatistica/anos` |
| GET | `/estatistica/grafico/ano/portal` |
| GET | `/estatistica/grafico/visao/portal/` |
| POST | `Estatistica` — body `{ "Rota": "/caminho" }` (telemetria de navegação; **o app NÃO deve chamar**) |

### Busca de documentos

| Método | Caminho | Payload |
|---|---|---|
| GET | `BuscaDocumento/modulos` | Módulos pesquisáveis |
| POST | `BuscaDocumento/busca` | `{ "Termo", "Periodo", "Inicio": "YYYY-MM-DD", "Fim": "YYYY-MM-DD", "ChaveModulo" }` → `{ "Quantidade", "Itens": [] }` |

### Outros

| Método | Caminho | Observações |
|---|---|---|
| GET | `DadosAbertos` | `{ "Informacao": { "Titulo", "Texto" }, "Modulos": [] }` |
| GET | `estruturaOrganizacional` | Organograma |
| GET | `estruturaOrganizacional/{id}/detalhe` | Detalhe da unidade |
| GET | `faq` | Perguntas frequentes |
| GET | `glossario` | Glossário |
| GET | `/autenticidade/configuracoes` | Config da verificação |
| GET | `/autenticidade/obter/{codigo}` | Verifica autenticidade de documento |
| POST | `/faleconosco` | Envia mensagem (formulário) |

## Como capturar os formatos de resposta (próximo passo)

1. Abra <https://transparencia-saojoaodaboavista.smarapd.com.br/#/> no Chrome.
2. DevTools → aba **Network** → filtro `paiportalserver`.
3. Navegue pela home, abra um módulo (ex.: Despesas) e um detalhe.
4. Clique com o botão direito em qualquer requisição → **Save all as HAR with content**.
5. Salve em `docs/api/samples/smarapd-<data>.har` e abra um PR. A partir do HAR geramos os modelos Dart (`freezed`/`json_serializable`).

Alternativamente, com o portal aberto, no console:

```js
copy(await (await fetch('/paiportalserver/MenuPortal')).json())
```

e cole o resultado em `docs/api/samples/MenuPortal.json`.

## Pendências

- [ ] Capturar `MenuPortal` real (lista definitiva de módulos/visões do município).
- [ ] Capturar amostras de `modulovisao/filter` para 3–4 visões (Receitas, Despesas, Servidores, Licitações).
- [ ] Confirmar se basta o header `Referer` ou se o servidor valida `Origin`. Sem `Referer` → 400 imediato ("Não foi possível obter a origem da requisição").
- [ ] **Backend instável.** Em 2026-11-08 (noite) o próprio portal oficial, aberto no navegador, recebia `HTTP 500` em `cliente`, `configuracaoaparencia` e `MenuPortal` (console do SPA: `[DefaultLayout] Falha ao carregar configuracao/cliente`). Via `curl` com `Referer`, 500 após ~87 s. Ou seja, a API estava fora do ar para todos — não é bloqueio. O smoke diário (`.github/workflows/smoke-fontes.yml`) agora checa `paiportalserver/cliente`; capturar amostras assim que voltar a responder 200.
- [ ] Verificar limites de taxa (rate limit) para dimensionar cache do app.

## Observações de uso responsável

- A API é pública e serve dados abertos por força da LAI (Lei 12.527/2011) e da LC 131/2009, mas **não é documentada nem oferece SLA**. O app deve cachear agressivamente e degradar com elegância.
- Não enviar `POST Estatistica` (telemetria do portal oficial).
- Identificar o app no `User-Agent` (ex.: `TransparenciaSJBV/1.0 (+https://github.com/marcioxtr/portal-transparencia)`).
