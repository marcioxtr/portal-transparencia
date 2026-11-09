# Arquitetura

## Princípio zero: o app não precisa de manutenção para continuar atualizado

Nada que o app mostra é digitado por uma pessoa. Cada dado vem de um destes caminhos:

1. **API pública ao vivo** (SAPL da Câmara, TCE-SP, SICONFI) — o app chama direto quando a
   consulta é leve (uma busca, um detalhe).
2. **JSON regenerado diariamente** pelo GitHub Actions (`dados/*.json`), para tudo o que é
   pesado ou raspado do site: `agregar.py` (TCE+SICONFI por ano) e `coletar.py`
   (coletores em `dados/coletores/`: obras, câmara, avisos, notícias, licitações,
   serviços, indicadores). O app lê via `dadosProvider('<nome>')`
   (`lib/data/dados_remotos.dart`): rede → asset embarcado.
3. **Texto editorial mínimo** (glossário, explicações de uma linha) — estático, revisado por PR.

Se o site mudar o layout, o coletor falha **no Actions, não no celular**: o JSON anterior
continua válido e o smoke diário abre uma issue. Um contribuidor conserta o coletor; o app
nas lojas não precisa de release. A fonte da verdade é sempre o site/API oficial — toda tela
mostra procedência e link para o original.

## Decisão central: app Flutter *sem backend obrigatório*

O app fala diretamente com as fontes públicas. Não há servidor do projeto a manter, pagar ou que vire ponto único de falha — essencial para um projeto comunitário que precisa sobreviver à rotatividade de mantenedores.

Um **BFF opcional** (Cloudflare Worker / Dart Frog) fica previsto para o caso de alguma fonte exigir headers que o cliente móvel não consegue enviar de forma confiável, ou para servir cache compartilhado. Ele é um *adaptador a mais*, não uma dependência.

```
┌──────────────────────────────────────────────────────────────────┐
│  apps/mobile  (Flutter)                                          │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │ features/  │→ │ domain/      │← │ data/ (repositories)     │  │
│  │ (telas)    │  │ (entidades,  │  │  ├─ cache (drift/sqlite) │  │
│  │            │  │  casos de    │  │  └─ fontes ───────────┐  │  │
│  └────────────┘  │  uso)        │  └───────────────────────┼──┘  │
│                  └──────────────┘                          │     │
└────────────────────────────────────────────────────────────┼─────┘
                                                             ▼
┌──────────────────────────────────────────────────────────────────┐
│  packages/fontes  (Dart puro, sem Flutter — testável em CI)      │
│  ├─ smarapd/      cliente JSON  → paiportalserver / paifileserver │
│  ├─ prefeitura/   scrapers HTML → contratos, emendas, notícias    │
│  ├─ ecrie_arquivos/  árvore ASP.NET → PDFs legados               │
│  ├─ tce_sp/       CSV → despesas/receitas 2023–2025 (fase 2)      │
│  └─ config_remota/  JSON no GitHub Pages → URLs, seletores, flags │
└──────────────────────────────────────────────────────────────────┘
```

## Camadas

### `packages/fontes` — adaptadores (Dart puro)

- Um sub-pacote por fonte, cada um expondo **uma interface de domínio** (ex.: `FonteContratos`, `FonteDespesas`), não o formato bruto do fornecedor.
- Sem dependência de Flutter → testes rodam em `dart test` em segundos; CI pode rodar *smoke tests* contra os sites reais todo dia e abrir issue automaticamente quando um parser quebrar.
- Fixtures HTML/JSON reais versionadas em `test/fixtures/` (com data no nome).
- HTTP via `dio` com interceptors: `User-Agent` do projeto, retry com backoff, limite de concorrência por host (2), e log estruturado.

### `config_remota`

Arquivo `config/v1.json` publicado via GitHub Pages do próprio repositório. Carregado no boot (com fallback ao embutido no app). Contém:

```json
{
  "versaoMinimaApp": "1.0.0",
  "fontes": {
    "smarapd": { "ativa": true, "baseUrl": "https://transparencia-saojoaodaboavista.smarapd.com.br", "referer": "https://transparencia-saojoaodaboavista.smarapd.com.br/" },
    "intertec": { "ativa": false, "motivo": "Portal em manutenção desde 2026-11" },
    "prefeitura": { "ativa": true, "baseUrl": "https://www.saojoao.sp.gov.br",
      "seletores": { "contratos.item": "article a.list-item__link", "contratos.descricao": ".list-description" } }
  },
  "avisos": [ { "id": "intertec-down", "texto": "Dados de 2023–2025 temporariamente indisponíveis na fonte oficial." } ]
}
```

Permite **corrigir um seletor quebrado ou desligar uma fonte em minutos**, sem passar pela revisão das lojas.

### `domain`

Entidades neutras ao fornecedor: `Despesa`, `Receita`, `Contrato`, `Emenda`, `Servidor`, `Licitacao`, `Documento`, `Orgao`. Cada entidade carrega `fonte` e `obtidoEm` para o app exibir a procedência ("dado obtido do portal SmarAPD em 08/11/2026 14:32").

### `data`

- Repositórios combinam fontes por período (ex.: `ContratoRepository` sempre vai ao site da prefeitura; `DespesaRepository` roteia por ano → SmarAPD / TCE-SP / eCrie).
- Cache em SQLite (`drift`) com TTL por tipo: listas 1 h, detalhes 24 h, árvore legado 7 dias, config remota 1 h. Primeiro renderiza do cache, depois atualiza (*stale-while-revalidate*).
- Modo offline: tudo que já foi visto fica navegável.

### `features` (UI)

| Tela | Fonte(s) |
|---|---|
| **Início** — resumo do ano: receita × despesa, top 5 fornecedores, últimos contratos, últimas emendas | SmarAPD `home/{ano}`, contratos, emendas |
| **Buscar** — campo único que pesquisa contratos, emendas, documentos (SmarAPD `BuscaDocumento/busca`) e nomes de arquivos legados | todas |
| **Receitas / Despesas / Servidores / Licitações** — tabela paginada com filtros simples (ano, mês, texto) e totais | SmarAPD `modulovisao/filter` + `colunasTotalizadoras` |
| **Contratos** — lista, filtros, detalhe, PDF | prefeitura |
| **Emendas** — lista, detalhe, agrupamento por autor/função | prefeitura |
| **Documentos históricos (até 2022)** — navegador de pastas, busca por nome, PDF inline | eCrie |
| **Órgãos** — organograma navegável | SmarAPD `estruturaOrganizacional` |
| **Sobre** — procedência dos dados, disclaimer "app independente", link pro repositório, política de privacidade | — |

Princípios de UX (o site é "muito confuso"; o app precisa ser o oposto):

- **Linguagem cidadã**: "Quanto a prefeitura gastou?", "Com quem?", "Quem recebeu emenda?". Termos técnicos (empenho, liquidação) explicados em tooltip usando o próprio `glossario` do SmarAPD.
- **Uma pergunta por tela.** Nada de 12 filtros; o avançado fica atrás de um botão.
- **Valores sempre com contexto**: "R$ 14 mil — 0,002% do orçamento" ou "R$ 190 por habitante".
- Acessibilidade: fontes escaláveis, contraste AA, labels para leitor de tela (o portal oficial usa VLibras; o app pode linkar).

## Stack Flutter

| Necessidade | Pacote |
|---|---|
| HTTP | `dio` |
| HTML parsing | `html` (dart-lang) + `csslib` |
| Estado | `riverpod` (+ `riverpod_generator`) |
| Modelos imutáveis / JSON | `freezed` + `json_serializable` |
| Cache | `drift` (SQLite) |
| PDF | `pdfx` ou `syncfusion_flutter_pdfviewer` (licença comunitária) |
| Gráficos | `fl_chart` |
| Navegação | `go_router` |
| Formatação BRL/datas | `intl` |
| Feature flags / config remota | próprio (`config_remota`) |
| Crash reporting | **nenhum por padrão** (privacidade); opcional Sentry self-hosted via flag |

## Privacidade

O app não coleta nada. Sem analytics, sem contas, sem IDs de anúncio. A política de privacidade (obrigatória nas lojas) é uma página do repositório dizendo exatamente isso. Favoritos e histórico ficam só no dispositivo.

## CI/CD

- `dart test` em `packages/fontes` em todo PR.
- Job agendado diário `smoke-fontes`: bate nos sites reais com fixtures mínimas; falha → abre issue `fonte-quebrada`.
- `flutter build apk --release` + `flutter build ipa` em tag; publicação via fastlane (Play) e Xcode Cloud ou fastlane (App Store). Chaves ficam em *secrets* da organização — contribuidores externos não precisam delas para desenvolver.

## Decisões registradas (ADR)

| # | Decisão | Motivo |
|---|---|---|
| 1 | Flutter | Um código, duas lojas; o autor já domina; Dart puro reaproveitado nos adaptadores |
| 2 | Sem backend obrigatório | Custo zero, sem ponto único de falha, sobrevive sem mantenedor ativo |
| 3 | Config remota via GitHub Pages | Corrigir scraper sem release de loja |
| 4 | Parsers em pacote Dart puro | Testes rápidos, CI diário contra produção |
| 5 | TCE-SP para 2023–2025 | Fonte oficial estável enquanto Intertec está fora |
| 6 | Zero telemetria | Confiança do cidadão; menos burocracia nas lojas |
