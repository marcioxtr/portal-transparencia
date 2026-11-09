# Roadmap

## Fase 0 — Fundação (atual)
- [x] Mapear fontes e endpoints ([02-fontes-de-dados.md](02-fontes-de-dados.md), [api/](api/))
- [x] Definir arquitetura ([03-arquitetura.md](03-arquitetura.md))
- [ ] Capturar amostras reais do SmarAPD (`MenuPortal`, `home/{ano}`, `modulovisao/filter` de 4 visões) → `docs/api/samples/`
- [x] Scaffold Flutter + monorepo (`apps/mobile`, `packages/fontes`)
- [x] CI básico (`dart test`, `flutter analyze`)
- [ ] Contato com a Controladoria da Prefeitura (ofício de ciência + pedido de documentação da API)

## Fase 1 — MVP (lojas)
- [x] `fontes/prefeitura`: contratos (lista, filtros, detalhe, PDF) + emendas
- [x] `fontes/ecrie_arquivos`: árvore de documentos até 2022 + busca por nome
- [x] **Painel com dados oficiais TCE-SP + SICONFI** (`dados/agregar.py` + workflow diário): receita × despesa, por fonte, por função, por fornecedor, por órgão, por morador, 2014→hoje
- [x] UI em vidro (Liquid Glass): fundo com profundidade, cartões translúcidos, barra flutuante, menu lateral, animações de entrada e contagem
- [x] Glossário em linguagem cidadã (35 termos) acessível de qualquer número do painel
- [x] Tela "Cobrar": pedido LAI pré-montado, ouvidoria, vereadores, conselhos, direitos
- [x] UI: Buscar, Contratos, Emendas, Documentos históricos, Sobre
- [ ] `fontes/smarapd`: bootstrap (`cliente`, `MenuPortal`, `exercicio`), visões dinâmicas genéricas, totais, anexos (API fora do ar em 2026-11-08)
- [ ] `config_remota`
- [ ] Cache offline (drift) — hoje: memória + assets embarcados do painel
- [ ] Política de privacidade + assets de loja + disclaimer "app independente"
- [ ] Publicar beta fechado (Play Internal Testing / TestFlight)

## Fase 2 — Cobertura completa
- [ ] Comparar anos/gestões lado a lado no painel (dados já existem em `dados/*.json`)
- [ ] Nomes de prefeitos e vereadores por mandato via TSE dados abertos (fato público, sem adjetivos)
- [ ] Câmara Municipal via SAPL (vereadores, projetos, votações, gastos do legislativo)
- [ ] Receitas / Despesas / Servidores / Licitações detalhados (SmarAPD) quando a API voltar
- [ ] Indicadores LRF: % pessoal, mínimos de saúde (15%) e educação (25%) — SICONFI RGF/RREO
- [ ] Tela "O que mudou": novas taxas/receitas que não existiam no ano anterior (ex.: taxa de lixo)
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
