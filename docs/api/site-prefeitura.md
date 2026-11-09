# Fonte — Site da Prefeitura (CMS eCrie)

> Host: <https://www.saojoao.sp.gov.br>
> Tecnologia: CMS proprietário da [eCrie](https://ecrie.com.br/) (ASP.NET, renderização server-side). **Não há API JSON**: os dados são obtidos por *scraping* de HTML estável e bem estruturado.
> Cobre: **Contratos**, **Emendas Parlamentares**, **Transparência até 2022** (arquivos) e páginas institucionais.

Todas as páginas são servidas sem autenticação, aceitam `GET` e não exigem cookies. Há Cloudflare Turnstile apenas em formulários `POST` (busca do site, ouvidoria) — nada que o app precise.

---

## 1. Contratos — `/contratos`

Lista pública de contratos, atas de registro de preço, convênios, termos etc. Em 2026-11-08: **741 páginas × 10 itens ≈ 7.400 registros**.

### Listagem

```
GET /contratos?numero=&ano=&tipo=&objeto=&razaoSocial=&pagina=N
```

| Parâmetro | Tipo | Exemplo |
|---|---|---|
| `numero` | texto | `77` |
| `ano` | inteiro | `2026` |
| `tipo` | enum (ver abaixo) | `Ata de Registro de Preço` |
| `objeto` | texto livre | `materiais hidráulicos` |
| `razaoSocial` | texto livre | `HIDROSANEAMENTO` |
| `pagina` | inteiro ≥ 2 (omitir para 1) | `2` |

Valores de `tipo` (extraídos do `<select name="tipo">`):

`Acordo de Cooperação` · `Apostilamento` · `Ata de Registro de Preço` · `Contrato` · `Convênio` · `Registro Inicial` · `Termo Aditivo` · `Termo de Cessão` · `Termo de Cessão de Uso de Bem Móvel` · `Termo de Colaboração` · `Termo de Compromisso` · `Termo de Cooperação Técnica` · `Termo de Credenciamento` · `Termo de Doação` · `Termo de Fomento` · `Termo de Permissão` · `Termo de Uso de Bem Imóvel`

Estrutura HTML de cada item:

```html
<article>
  <h3><a class="list-item__link" href="/contratos/26048">Ata de Registro de Preços 77/26</a></h3>
  <div class="list-description">Registro de Preços para Aquisição de Materiais Hidraulicos.</div>
</article>
<nav class="pagination" aria-label="Paginação: página 1 de 741">…</nav>
```

Seletores:

| Dado | Seletor |
|---|---|
| Itens | `article a.list-item__link` → `href` (id numérico no final) e texto (título) |
| Descrição | `article .list-description` |
| Total de páginas | `nav.pagination[aria-label]` → regex `página (\d+) de (\d+)` |

### Detalhe — `/contratos/{id}`

Texto renderizado (exemplo real, id `26048`):

```
Ata de Registro de Preços 77/26
Registro de Preços para Aquisição de Materiais Hidraulicos.
Contratado(a): HIDROSANEAMENTO LTDA– EPP
CPF/CNPJ: 05.958.760/0001-20
Licitação: PE 003/26
Valor: R$ 14.231,58
Ano: 2026
Data da assinatura: 27/03/2026
Data de início: 27/03/2026
Data de fim: 26/03/2027
[Baixar documento]  → link para o PDF
```

Campos a extrair: `titulo`, `objeto`, `contratado`, `cpfCnpj`, `licitacao`, `valor` (BRL), `ano`, `dataAssinatura`, `dataInicio`, `dataFim`, `urlDocumento`.

> Observação: o `id` é sequencial e global do CMS (ex.: 24378, 26048…). Pode ser usado como chave de cache.

---

## 2. Emendas Parlamentares — `/transparencia/emendas-parlamentares`

Em 2026-11-08: **103 registros, 9 páginas de 12**.

### Listagem

```
GET /transparencia/emendas-parlamentares?titulo=&descricao=&data=dd/mm/aaaa&pagina=N
```

Itens: `a.list-item__link` (href `/transparencia/emendas-parlamentares/emenda-n-{numero-sem-pontos}[-recurso-nao-liberado]`), com "Publicado: dd/mm/aaaa" ao lado. Texto "Listando resultados de 1 - 12 de um total de 103" dá o total.

### Detalhe

O corpo é um único `<p>` com pares `<strong>Campo:</strong> valor<br/>`:

```
Origem do Recurso: Federal
Tipo de Emenda: Bancada
Autoria: Bancada de São Paulo
Forma de Repasse: Fundo a fundo
Número da Emenda: 2026.71250001
Valor da Emenda: R$ 193.600,00
Objetivo/Finalidade: Incremento temporário ao Custeio dos serviços de Assistência Hospitalar…
Função de Governo: 10 – Saúde
Beneficiário: Fundo Municipal de Saúde
```

Parser: dividir o `<p>` por `<br>`, separar em `<strong>` (chave) e resto (valor). Chaves podem variar levemente entre emendas (manter mapa tolerante + "outros campos").

---

## 3. Transparência até 2022 — arquivos (file-browser eCrie)

Página índice: `/transparencia/transparencia-ate-2022` ("Acesso Rápido"). Cada subpágina de **Contas Públicas** (`/transparencia/contas-publicas/*`) e páginas afins embute um `<iframe>` apontando para um navegador de arquivos ASP.NET:

```
https://ecrie.com.br/home/_arq/41/Default.aspx?pasta={caminho}
```

`41` é o id do cliente (prefeitura) no CMS. O HTML devolvido contém a árvore **completa** (todas as pastas e arquivos já expandidos, `TreeView` ASP.NET), e cada arquivo é um `<a target="_blank" href="{caminho-relativo}">`. A URL final do arquivo é:

```
https://ecrie.com.br/home/_arq/41/{href}
```

Exemplo: `https://ecrie.com.br/home/_arq/41/rh/Despesas%20Mensal%20Com%20Funcionarios/2013/2013%2005%20Servidores.pdf`

Seletores:

| Dado | Seletor |
|---|---|
| Nós da árvore | `a.tvArquivos_0` (classe `node`) |
| Arquivo (folha) | `a[target=_blank][href]` → nome = texto, url = base + href |
| Pasta | `a[href^="javascript:__doPostBack"]` → nome = texto; o caminho vem do argumento `sF:*|*…*|*{pasta}` |

Hierarquia: os `<div id="tvArquivosnNNodes">` aninham os filhos — basta percorrer a árvore DOM.

### Catálogo de pastas (mapeado em 2026-11-08)

| Página do site | `pasta=` |
|---|---|
| Despesas com Funcionários | `rh/Despesas Mensal Com Funcionarios` |
| Atas de Audiências Públicas | `transparencia/Atas De Audiência Pública` |
| Balancetes | `transparencia/Balancetes` |
| Balanços | `transparencia/Balancos` |
| Despesas com Publicidade | `transparencia/Despesas com Publicidade` |
| Despesas Diárias | `transparencia/Despesas Diárias` |
| Diárias Pessoal Civil | `transparencia/Diarias Pessoal Civil` |
| Patrimônio | `transparencia/Patrimonio` |
| Planejamento Orçamentário | `transparencia/Planejamento Orcamentario` |
| Receitas de Multas de Trânsito | `transparencia/Receitas de Multas de Trânsito` |
| Receitas Diárias | `transparencia/Receitas Diárias` |
| Recibos e Pareceres do TCE-SP | `transparencia/Recibos e Pareceres do Tribunal de Contas do Estado de Sao Paulo` |
| Regime Especial de Adiantamento | `transparencia/Regime Especial de Adiantamento` |
| Relatórios LRF, SICONFI e SISTN | `transparencia/Relatorios da Lei de Responsabilidade Fiscal, SICONFI e SISTN` |
| Relatórios Contas da Saúde e SIOPS | `transparencia/Relatorios de Contas da Saude e SIOPS` |
| Relatórios Contas do Ensino e SIOPE | `transparencia/Relatorios de Contas do Ensino e SIOPE` |
| Repasse de Duodécimo à Câmara | `transparencia/Repasse de Duodécimo à Câmara` |
| Repasses ao Terceiro Setor | `transparencia/Repasses ao Terceiro Setor - Leis 13.019-2014 e 12.527-2011` |
| Repasses Financeiros | `transparencia/Repasses Financeiros` |
| SIAFIC | `transparencia/SIAFIC` |
| Subsídio do Transporte Público | `transparencia/Subsídio do Transporte Público` |
| Transferências de Recursos da União | `transparencia/Transferências de Recursos da União - Lei Federal 9.452-1997` |

Páginas "Relação de Bens", "Planejamento Orçamentário" (fora de Contas Públicas) e "Diária Pessoal Civil" seguem o mesmo padrão (`Arquivos relacionados` + iframe). Páginas que são só texto/links externos: `liberacao-de-recursos-convenios` (links para FNS, FNDE, Portal da Transparência federal), `perguntas-frequentes`, `leis/lei-de-accessibilidade`, `covid-19`.

Organogramas (PDF estático):
- `https://saojoao.sp.gov.br/home/esic/pdf/org_organizacional_prefeitura.pdf`
- `https://saojoao.sp.gov.br/home/esic/pdf/org_organizacional_departamentos.pdf`

> O conteúdo desses arquivos (muitos `.pdf` e alguns `.txt`) é documento, não dado tabular. No app, a feature é **navegador de arquivos + visualizador de PDF + busca por nome**, não tabelas.

---

## 4. Outras páginas úteis do site

| Página | URL | Formato |
|---|---|---|
| Notícias (feed RSS) | `https://ecrie20.com.br/saojoao.sp.gov.br/feed.xml` | RSS/XML |
| Notícias | `/noticias` | HTML (mesma estrutura `list-item__link`) |
| Departamentos | `/departamentos` | HTML |
| Governo Municipal | `/a-cidade/governo-municipal` | HTML |
| FAQ | `/perguntas-frequentes-faq` | HTML |
| Ouvidoria | `/cidadao/ouvidoria` | HTML → redireciona ao e-OUV |

---

## Boas práticas para o scraper

- Identificar-se no `User-Agent` com nome do projeto e link do repositório.
- Cache local obrigatório (listas: 1 h; detalhes: 24 h; árvore de arquivos legados: 7 dias — são dados históricos, quase imutáveis).
- Nunca paralelizar mais que 2–3 requisições simultâneas contra o site da prefeitura.
- Parsers isolados em `packages/fontes/` com **fixtures HTML versionadas** em `test/fixtures/` para detectar mudanças de layout em CI.
- Seletores centralizados num único arquivo por fonte, para que uma quebra de layout seja um PR de uma linha.
