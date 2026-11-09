# Amostras de respostas reais

Coloque aqui capturas **reais** das APIs/páginas, com a data no nome:

```
smarapd/MenuPortal-2026-11-10.json
smarapd/home-2026-2026-11-10.json
smarapd/modulovisao-filter-despesas-2026-11-10.json
smarapd/sessao-completa-2026-11-10.har
```

Como capturar: [docs/api/smarapd-pai.md → Como capturar](../smarapd-pai.md#como-capturar-os-formatos-de-resposta-próximo-passo).

Antes de enviar, remova qualquer dado pessoal que não seja público por natureza
(o portal só exibe dados públicos, mas um HAR também grava cookies e headers
do seu navegador — apague `cookies` e `Authorization` se houver).

A partir dessas amostras geramos os modelos Dart tipados em
`packages/fontes/lib/src/smarapd/modelos/`.
