# Fontes de dados

O "Portal da Transparência" de São João da Boa Vista **não é um sistema — é um menu que aponta para cinco sistemas diferentes**, de fornecedores diferentes, com tecnologias diferentes. Essa é a causa raiz da confusão para o cidadão, e é exatamente o que o app resolve: uma única interface sobre todas elas.

```
www.saojoao.sp.gov.br/transparencia  (menu, CMS eCrie)
│
├── "Transparências a partir de 2026"  → SmarAPD PAI       (SPA React + API JSON)   ✅ mapeada
├── "Transparência a partir de 2023"   → Intertec GPMOD    (Oracle APEX)            ⛔ em manutenção
├── "Transparência até 2022"           → eCrie file-browser (ASP.NET, árvore de PDFs) ✅ mapeada
├── "Emendas Parlamentares"            → CMS eCrie         (HTML)                   ✅ mapeada
└── (menu lateral) "Contratos"         → CMS eCrie         (HTML, ~7.400 registros) ✅ mapeada
```

Periféricos linkados do portal (fora do escopo inicial, mas documentados):

| Sistema | URL | O que é |
|---|---|---|
| Portal do Cidadão (SmarAPD) | `https://pm-saojoao.smarapd.com.br/portalservicosweb` | Serviços (2ª via IPTU, processos) — exige CPF/login |
| e-OUV / e-SIC | `https://saojoaodaboavista.eouve.com.br` | Ouvidoria e pedidos LAI — redireciona para plataforma nacional |
| Consulta de Falecidos | `https://pm-saojoao.smarapd.com.br/smarit/#!/consultafalecido` | Cemitério |
| GERR (Repasses) | `https://gerr.com.br/principal.php?m=portal&chave=46429379000150` | Repasses ao terceiro setor (linkado em "até 2022") |

## Matriz fonte × período × conteúdo

| Conteúdo | ≤ 2022 | 2023–2025 | 2026 → |
|---|---|---|---|
| Receitas / Despesas / Empenhos | eCrie (PDF) | Intertec ⛔ / **TCE-SP** (CSV) | SmarAPD (JSON) |
| Servidores / Folha | eCrie (PDF mensal) | Intertec ⛔ | SmarAPD (JSON) |
| Licitações | eCrie | Intertec ⛔ | SmarAPD (JSON) |
| Contratos | **Site prefeitura (HTML)** — cobre todos os anos | ← | ← |
| Emendas parlamentares | **Site prefeitura (HTML)** — todos os anos | ← | ← |
| Balancetes / Balanços / LRF | eCrie (PDF) | eCrie (PDF)¹ | SmarAPD + eCrie |
| Repasses ao terceiro setor | eCrie / GERR | ? | SmarAPD |
| Patrimônio / Bens | eCrie (PDF) | ? | SmarAPD |
| Organograma | PDF estático | PDF estático | SmarAPD `estruturaOrganizacional` |
| e-SIC (estatísticas) | — | — | SmarAPD `esic/*` |
| Dados abertos (exportações) | — | — | SmarAPD `DadosAbertos` |

¹ Várias pastas do eCrie continuam recebendo arquivos pós-2022 (ex.: Atas de Audiência Pública têm 2016→hoje).

## Detalhes por fonte

- [SmarAPD PAI](api/smarapd-pai.md) — API JSON, ~50 endpoints.
- [Site da Prefeitura (eCrie)](api/site-prefeitura.md) — contratos, emendas, arquivos legados.
- [Intertec GPMOD](api/intertec-gpmod.md) — fora do ar; alternativas oficiais.

## Fontes externas oficiais que complementam (fase 2)

| Fonte | API | Uso no app |
|---|---|---|
| TCE-SP Transparência Municipal | CSV por município/ano | Despesas e receitas 2023–2025 (e validação cruzada) |
| SICONFI (Tesouro Nacional) | REST/ORDS | Indicadores fiscais (RREO/RGF), comparativo com municípios vizinhos |
| Portal da Transparência (CGU) | REST (chave gratuita) | Transferências da União, emendas (confere com o site) |
| IBGE Cidades | REST | População, PIB per capita → "gasto por habitante" |
