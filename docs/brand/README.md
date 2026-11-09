# Marca — Transparência SJBV

## Conceito

Um **cubo montado de peças de quebra-cabeça**, em isometria: três faces
visíveis, cada uma com quatro peças encaixadas, nas seis cores da marca. A
cidade se constrói peça por peça; cada face é um lado da mesma história —
quem arrecada, quem gasta, quem fiscaliza. As faces laterais são mais escuras
(sombreamento) para dar volume; a sombra no chão ancora o objeto.

O desenho é **original** (gerado por `gerar_logo_cubo.py`, licença MIT),
inspirado num motivo comum — cubo de peças — sem reproduzir arte de terceiros.
Não use ilustrações de bancos de imagem (Freepik, Depositphotos…) no projeto:
as licenças proíbem uso como logotipo e não permitem redistribuição num
repositório aberto.

Variante anterior (anel de pessoas-peça) continua disponível em
`gerar_logo_anel.py` para materiais de divulgação ("a comunidade em roda").

## Arquivos

| Arquivo | Uso |
|---|---|
| `apps/mobile/assets/logo/logo.svg` | Logo principal (fundo transparente), usado no app |
| `apps/mobile/assets/logo/icon.png` | Ícone 1024² com fundo branco arredondado (lojas) |
| `apps/mobile/assets/logo/icon_fg.png` | Camada *foreground* do ícone adaptativo Android |
| `docs/brand/gerar_logo_cubo.py` | Gerador do logo atual — mude cores/geometria e regenere |
| `docs/brand/gerar_logo_anel.py` | Gerador da variante "anel de pessoas" |

Regenerar:

```bash
cd apps/mobile/assets/logo
python3 ../../../../docs/brand/gerar_logo_cubo.py logo.svg
python3 ../../../../docs/brand/gerar_logo_cubo.py icon.svg --margem=14 --fundo=#FFFFFF --tamanho=1024
python3 ../../../../docs/brand/gerar_logo_cubo.py icon_fg.svg --margem=44 --tamanho=1024
# converter os .svg de ícone para PNG 1024 (macOS: qlmanage -t -s 1024; ou rsvg-convert)
cd ../.. && dart run flutter_launcher_icons
```

## Paleta

| Nome | Hex | Onde |
|---|---|---|
| Rosa-vermelho | `#FF3B5C` | peças · **despesa/pago** no painel |
| Laranja | `#FF8C1A` | peças · empenhado no painel |
| Amarelo | `#FFD60A` | peças · "ano parcial" |
| Verde | `#3DDC84` | peças · **receita** no painel |
| Azul-céu | `#00B4FF` | peças · acentos |
| Violeta | `#8A4DFF` | peças · acentos |
| Azul (UI) | `#4361EE` | cor-semente do tema Material (`lib/app/tema.dart`) |

Cores vivas de propósito: transparência não precisa parecer repartição.
Na UI, as seis cores aparecem só como acentos (ícones dos atalhos, gráficos);
texto e superfícies seguem o esquema Material gerado a partir do azul.

## Nome e identidade

- Nome de trabalho: **Transparência SJBV** · subtítulo "app cidadão".
- Nunca usar brasão, bandeira ou logotipo da Prefeitura. Nunca sugerir que é
  um canal oficial. Toda tela com dado mostra a procedência.
- Tom de voz: direto, em linguagem cidadã ("quanto a Prefeitura gastou?"),
  sem jargão contábil sem explicação.
