# Viabilidade

**Resposta curta: sim, é viável — e o problema que o app resolve é real e verificável.** O portal atual fragmenta a transparência municipal em cinco sistemas de três fornecedores, sem busca unificada e sem versão móvel decente. Mas há três ressalvas que moldam o projeto.

## O que torna viável

1. **Dados públicos por lei.** LAI (12.527/2011), LC 131/2009 e Decreto 7.185/2010 obrigam a prefeitura a publicar esses dados em tempo real e em formato aberto. Consumir e reapresentar dados públicos é legítimo e até incentivado (art. 8º, §3º, II e III da LAI: "possibilitar a gravação de relatórios em diversos formatos eletrônicos, abertos e não proprietários" e "possibilitar o acesso automatizado por sistemas externos").
2. **Fonte principal (2026+) tem API JSON de verdade.** O SmarAPD PAI é um SPA que consome uma API REST limpa; [já mapeamos ~50 endpoints](api/smarapd-pai.md).
3. **As fontes HTML são estáveis e bem estruturadas.** Contratos e emendas no CMS eCrie têm markup semântico (`list-item__link`, `list-description`, paginação com `aria-label`), e os arquivos legados vêm numa árvore completa num único GET.
4. **Flutter resolve Android + iOS com um código** e tem bibliotecas maduras para tudo que precisamos (HTTP, parsing HTML, cache SQLite, visualização de PDF, gráficos).

## As três ressalvas

### 1. Não há API oficial estável — o app depende de engenharia reversa

Nenhum dos fornecedores documenta ou garante suas APIs. Mudanças de layout ou versão quebram o app. **Mitigação arquitetural**: parsers isolados por fonte, fixtures em testes de CI que rodam diariamente contra os sites reais, e um arquivo de configuração remoto (JSON no GitHub Pages) com seletores/URLs que pode ser atualizado sem publicar nova versão nas lojas.

### 2. Identidade: o app é *cidadão*, não *oficial*

O app não pode se apresentar como da Prefeitura: sem brasão como logo, sem "Prefeitura de São João da Boa Vista" no nome da loja, com aviso claro "aplicativo independente, dados obtidos do portal oficial em {data/hora}". Isso protege o projeto (Apple e Google removem apps que simulam entidades governamentais) e protege o cidadão (sabe o que está vendo). Nome de trabalho sugerido: **"Transparência SJBV"** com subtítulo "app cidadão, código aberto".

Vale, em paralelo, **procurar a prefeitura** (Controladoria / Departamento de Comunicação). Um ofício simples pedindo (a) ciência do projeto e (b) acesso documentado à API do SmarAPD pode transformar engenharia reversa em parceria — e é um argumento de ouro no README.

### 3. O período 2023–2025 está num portal fora do ar

O Intertec GPMOD está "em manutenção" e não tem snapshot no Wayback. Para não deixar um buraco de três anos, usar o **TCE-SP** (dados padronizados de todos os municípios paulistas) como fonte para esse período. Detalhes em [intertec-gpmod.md](api/intertec-gpmod.md).

## Estimativa de esforço (MVP)

| Entrega | Esforço (dev solo, part-time) |
|---|---|
| Captura de amostras SmarAPD + modelos Dart | 1 semana |
| Camada de fontes (SmarAPD, contratos, emendas, eCrie) com testes | 2–3 semanas |
| UI: home, busca unificada, listas, detalhe, visualizador PDF, favoritos | 3–4 semanas |
| Cache offline, config remota, telemetria de quebras | 1 semana |
| Publicação (Play Store + App Store), privacidade, screenshots | 1 semana |
| **Total MVP** | **~2–3 meses** |

Com comunidade contribuindo (repositório aberto, issues etiquetadas `good first issue` por fonte), o paralelismo natural é por fonte: cada contribuidor pode adotar um adaptador.

## Riscos residuais

| Risco | Probabilidade | Impacto | Resposta |
|---|---|---|---|
| SmarAPD muda API sem aviso | média | alto | CI diário + config remota + fallback "abrir no site" |
| Prefeitura solicita remoção | baixa | alto | Base legal LAI; contato proativo; código aberto |
| Rate limit / bloqueio por IP | média | médio | Cache agressivo, `User-Agent` identificado, BFF opcional |
| App Store rejeita por "conteúdo governamental" | baixa | médio | Branding independente, disclaimer, política de privacidade |
