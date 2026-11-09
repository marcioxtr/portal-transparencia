# dados/ — tudo o que o app mostra, regenerado todo dia

## Coletores (`coletar.py`)

`python3 -I dados/coletar.py [nomes]` roda os módulos de `dados/coletores/` e grava
`dados/<nome>.json` + cópia em `apps/mobile/assets/dados/`. Cada módulo tem uma função
`coletar() -> dict` e documenta seu esquema no topo do arquivo:

| JSON | Fonte | Conteúdo |
|---|---|---|
| `obras.json` | site `/obras` | obras georreferenciadas, empresa, valor, % executado |
| `camara.json` | SAPL (API) + TSE | vereadores, mandatos, votos, matérias, sessões, leis, gestões |
| `avisos.json` | site | interdições, alterações de trânsito, coleta, eventos, reuniões de conselhos |
| `noticias.json` | RSS + site | últimas notícias por departamento |
| `licitacoes.json` | site | chamamentos, inexigibilidades, processos seletivos |
| `servicos.json` | site | unidades de saúde, escolas, conselhos, carta de serviços, ouvidoria, metas |
| `indicadores.json` | SICONFI + TCE + `{ano}.json` | mínimos constitucionais, LRF, comparativos, vizinhos, o que mudou |

Um coletor que falhar não derruba os outros nem apaga o JSON anterior.

## Agregados do painel (`agregar.py`)

Um JSON por exercício (`2014.json` … `2026.json`), gerado por `agregar.py` a
partir de duas fontes oficiais e públicas:

- **TCE-SP** (`transparencia.tce.sp.gov.br/api/json`) — cada lançamento de
  despesa (empenho, liquidação, pagamento) e de receita (por alínea) do
  município, mês a mês.
- **SICONFI / Tesouro Nacional** (`apidatalake.tesouro.gov.br/ords/siconfi`) —
  despesa por função de governo (saúde, educação…) e população.

O app lê `https://raw.githubusercontent.com/marcioxtr/portal-transparencia/main/dados/{ano}.json`
e, sem rede, usa a cópia embarcada em `apps/mobile/assets/dados/`. O workflow
`agregar-dados.yml` atualiza o ano corrente e o anterior todo dia.

## Estrutura

```jsonc
{
  "municipio": "sao-joao-da-boa-vista", "codIbge": 3549102, "ano": 2025,
  "geradoEm": "2026-11-09T03:16:00+00:00",
  "fontes": { "tce": "...", "siconfi": "SICONFI DCA 2025 (Anexo I-E)" },
  "populacao": 92319,
  "mesesDisponiveis": [1, 2, ..., 12],
  "despesas": {
    "porMes": [ { "mes": 1, "empenhado": 0, "liquidado": 0, "pago": 0, "anulado": 0 } ],
    "total": { "empenhado": 0, "liquidado": 0, "pago": 0, "anulado": 0 },
    "topFornecedores": [ { "nome": "", "id": "CNPJ - PESSOA JURÍDICA - 000", "orgao": "", "empenhado": 0, "pago": 0, "interno": false } ],
    "porOrgao": [ { "orgao": "", "empenhado": 0 } ],
    "porFuncao": [ { "codigo": "10", "nome": "Saúde", "empenhado": 0, "liquidado": 0, "pago": 0 } ]
  },
  "receitas": {
    "porMes": [ { "mes": 1, "total": 0, "categorias": { "iptu": 0, "fpm": 0 } } ],
    "total": 0,
    "porCategoria": [ { "id": "iptu", "nome": "IPTU", "explicacao": "...", "valor": 0 } ],
    "topAlineas": [ { "alinea": "11125000 - Imposto sobre a Propriedade Predial...", "valor": 0 } ]
  }
}
```

Valores em reais (float). `interno: true` marca folha, previdência e repasses
entre órgãos — não são "empresas contratadas".

## Rodar localmente

```bash
python3 -I dados/agregar.py 2025
cp dados/*.json apps/mobile/assets/dados/
```

Cada ano faz 24 requisições ao TCE-SP (~750 KB cada) e 1–6 ao SICONFI. Rode
com moderação; os dados históricos (≤ ano anterior) quase não mudam.
