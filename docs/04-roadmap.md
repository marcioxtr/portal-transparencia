# Roadmap

## Fase 0 — Fundação (atual)
- [x] Mapear fontes e endpoints ([02-fontes-de-dados.md](02-fontes-de-dados.md), [api/](api/))
- [x] Definir arquitetura ([03-arquitetura.md](03-arquitetura.md))
- [ ] Capturar amostras reais do SmarAPD (`MenuPortal`, `home/{ano}`, `modulovisao/filter` de 4 visões) → `docs/api/samples/`
- [ ] Scaffold Flutter + monorepo (`apps/mobile`, `packages/fontes`)
- [ ] CI básico (`dart test`, `flutter analyze`)
- [ ] Contato com a Controladoria da Prefeitura (ofício de ciência + pedido de documentação da API)

## Fase 1 — MVP (lojas)
- [ ] `fontes/prefeitura`: contratos (lista, filtros, detalhe, PDF) + emendas
- [ ] `fontes/ecrie_arquivos`: árvore de documentos até 2022 + busca por nome
- [ ] `fontes/smarapd`: bootstrap (`cliente`, `MenuPortal`, `exercicio`), visões dinâmicas genéricas, totais, anexos
- [ ] `config_remota`
- [ ] UI: Início, Buscar, Contratos, Emendas, Documentos históricos, Sobre
- [ ] Cache offline (drift)
- [ ] Política de privacidade + assets de loja + disclaimer "app independente"
- [ ] Publicar beta fechado (Play Internal Testing / TestFlight)

## Fase 2 — Cobertura completa
- [ ] Receitas / Despesas / Servidores / Licitações com filtros simples e gráficos
- [ ] Órgãos (organograma) e e-SIC (estatísticas)
- [ ] `fontes/tce_sp` para 2023–2025
- [ ] Smoke test diário contra produção + issue automática
- [ ] Fonte Intertec se/quando voltar

## Fase 3 — Cidadania ativa
- [ ] "Explique isso" — glossário contextual (SmarAPD `glossario`) e textos didáticos
- [ ] Comparativos: gasto por habitante (IBGE), evolução anual, município × vizinhos (SICONFI)
- [ ] Alertas: novo contrato acima de R$ X, nova emenda, novo balancete
- [ ] Compartilhar um dado como imagem (card) com link da fonte
- [ ] Atalho para pedido LAI (e-SIC) pré-preenchido a partir de um registro

## Fase 4 — Replicabilidade
- [ ] Extrair o que é específico de SJBV para `config/municipios/sjbv.json`
- [ ] Documentar como adaptar para outro município que use SmarAPD/eCrie (centenas de prefeituras paulistas usam os mesmos fornecedores)
