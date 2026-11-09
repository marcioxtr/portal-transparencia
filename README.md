# Transparência SJBV — app cidadão

> Aplicativo **independente e de código aberto** (Android + iOS, Flutter) que reúne em uma interface simples tudo o que o Portal da Transparência da Prefeitura de São João da Boa Vista/SP publica — hoje espalhado em cinco sistemas de três fornecedores.
>
> ⚠️ Este app **não é da Prefeitura**. Todos os dados vêm das fontes oficiais públicas e exibem data/hora de obtenção e link para a origem.

## Por que

O cidadão que quer saber "quanto a prefeitura gastou com X" precisa descobrir em qual dos portais o ano está, aprender uma interface diferente em cada um e, no celular, desistir. Dados públicos só são transparência se qualquer pessoa consegue vê-los.

## Status

**Fase 1 — MVP em andamento.** App navegável (Android + iOS) consumindo contratos, emendas e documentos históricos com dados reais; receitas/despesas aguardam o portal SmarAPD voltar ao ar. Veja o [roadmap](docs/04-roadmap.md).

<p align="center">
  <img src="docs/screenshots/android-inicio-2026-11-09.png" width="260" alt="Início no Android">
  &nbsp;&nbsp;
  <img src="docs/screenshots/ios-inicio-2026-11-09.png" width="260" alt="Início no iOS">
</p>

| Fonte | Período | Tecnologia | Mapeamento |
|---|---|---|---|
| SmarAPD PAI | 2026 → | API JSON | ✅ [endpoints](docs/api/smarapd-pai.md) · ⏳ amostras de resposta |
| Site da Prefeitura (contratos, emendas) | todos | HTML | ✅ [seletores](docs/api/site-prefeitura.md) |
| Arquivos legados (eCrie) | ≤ 2022 | HTML (árvore) | ✅ [22 pastas](docs/api/site-prefeitura.md#3-transparência-até-2022--arquivos-file-browser-ecrie) |
| Intertec GPMOD | 2023–2025 | Oracle APEX | ⛔ [fora do ar](docs/api/intertec-gpmod.md) → alternativa TCE-SP |

## Estrutura do repositório

```
apps/mobile/        app Flutter (Android + iOS)
packages/fontes/    adaptadores Dart puro: SmarAPD, site da Prefeitura, eCrie
                    └ test/fixtures/   HTML/JSON reais capturados, com data
docs/               viabilidade, fontes, arquitetura, roadmap, mapa das APIs
.github/workflows/  CI (analyze + test) e smoke diário contra as fontes
```

```bash
# testes dos adaptadores (sem Flutter)
cd packages/fontes && dart pub get && dart test

# app
cd apps/mobile && flutter pub get && flutter run
```

## Documentação

1. [Viabilidade](docs/01-viabilidade.md) — é possível? sim; com quais ressalvas
2. [Fontes de dados](docs/02-fontes-de-dados.md) — o mapa dos cinco sistemas
3. [Arquitetura](docs/03-arquitetura.md) — Flutter sem backend, adaptadores por fonte, config remota
4. [Roadmap](docs/04-roadmap.md)
5. APIs: [SmarAPD](docs/api/smarapd-pai.md) · [Site/eCrie](docs/api/site-prefeitura.md) · [Intertec](docs/api/intertec-gpmod.md)

## Como ajudar

Leia o [CONTRIBUTING.md](CONTRIBUTING.md). A contribuição mais valiosa agora é **capturar amostras reais da API SmarAPD** (um HAR do DevTools basta) — instruções [aqui](docs/api/smarapd-pai.md#como-capturar-os-formatos-de-resposta-próximo-passo).

## Base legal

Lei de Acesso à Informação (12.527/2011, art. 8º §3º II e III), Lei Complementar 131/2009 e Decreto 7.185/2010 determinam a publicação desses dados em formato aberto e com acesso automatizado por sistemas externos.

## Licença

[MIT](LICENSE). Os dados pertencem ao público.
