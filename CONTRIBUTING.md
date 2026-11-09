# Contribuindo

Obrigado pelo interesse! Este é um projeto cidadão, de código aberto, para tornar os dados públicos de São João da Boa Vista/SP acessíveis a qualquer pessoa pelo celular. Toda ajuda conta — código, design, revisão de textos, teste em aparelhos, documentação, contato com a prefeitura.

## Antes de começar

1. Leia [docs/01-viabilidade.md](docs/01-viabilidade.md) e [docs/03-arquitetura.md](docs/03-arquitetura.md) (15 min).
2. Veja as issues com label [`good first issue`](../../labels/good%20first%20issue) e [`ajuda bem-vinda`](../../labels/ajuda%20bem-vinda).
3. Comente na issue antes de começar, para evitar trabalho duplicado.

## Ambiente

```bash
# Flutter stable (ver versão em .fvmrc / pubspec.yaml)
git clone https://github.com/marcioxtr/portal-transparencia.git
cd portal-transparencia
flutter pub get
cd packages/fontes && dart pub get && dart test
```

## Como contribuir com uma fonte de dados

Os adaptadores em `packages/fontes/` são o coração do projeto e a melhor porta de entrada:

1. Salve uma **fixture real** (HTML ou JSON) em `test/fixtures/<fonte>/<nome>-<AAAA-MM-DD>.<ext>`.
2. Escreva o teste que parseia a fixture para as entidades de domínio.
3. Implemente/ajuste o parser. Seletores ficam **em um único arquivo** por fonte (`seletores.dart`).
4. Rode `dart test`. Abra o PR descrevendo qual página/endpoint foi coberto.

Se você só conseguiu **capturar dados** (um HAR do DevTools, um JSON do console) e não quer programar, abra uma issue com o arquivo anexado — isso já é uma contribuição valiosa. Veja [docs/api/smarapd-pai.md → Como capturar](docs/api/smarapd-pai.md#como-capturar-os-formatos-de-resposta-próximo-passo).

## Padrões

- **Idioma**: código em inglês (nomes de classes/variáveis), domínio em português quando o termo é jurídico/contábil brasileiro (`Empenho`, `Licitacao`, `Emenda`) — tradução perderia precisão. Comentários, docs, issues e commits em português.
- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/pt-br/) — `feat(fontes/prefeitura): parser de detalhe de contrato`.
- **Lint**: `flutter analyze` / `dart analyze` sem warnings. Formatação com `dart format`.
- **Testes**: todo parser tem teste com fixture. Toda feature de UI tem ao menos um widget test do caminho feliz.
- **Nada de telemetria** no app sem discussão prévia em issue.

## Uso responsável das fontes

Os sites da prefeitura e dos fornecedores são infraestrutura pública compartilhada. Ao desenvolver:

- Use as fixtures; não bata nos sites em loop.
- Identifique-se no `User-Agent` (o cliente HTTP do projeto já faz isso).
- Máximo de 2 requisições simultâneas por host.
- Nunca chame `POST Estatistica` do SmarAPD (telemetria do portal oficial).

## Revisão

PRs precisam de uma aprovação. Revisores olham: testes, isolamento do parser, impacto em cache/offline, textos em linguagem cidadã.

## Código de conduta

Seja gentil e objetivo. Críticas são sobre o código, nunca sobre pessoas. Discussões político-partidárias não cabem aqui: o projeto é sobre **dados**, de qualquer governo, para qualquer cidadão.
