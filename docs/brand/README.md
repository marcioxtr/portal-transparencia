# Marca — Transparência SJBV

## Conceito

Seis pessoas, seis cores, encaixadas como peças de um quebra-cabeça em roda.
O centro é **vazio**: a informação pública fica aberta, no meio, para qualquer
um olhar. Uma peça está **entrando** — sempre cabe mais gente. É a ideia de
*ubuntu* ("eu sou porque nós somos") aplicada à transparência: a comunidade
monta a imagem inteira junta, e todo mundo ganha.

O desenho é **original** (gerado por `gerar_logo_anel.py`, licença MIT). Foi
inspirado em um motivo comum — anel de peças com pessoas — mas não reproduz
nenhuma arte de terceiros. Não use ilustrações de bancos de imagem (stock)
no projeto: elas têm licença própria e não podem ser redistribuídas num
repositório aberto.

## Arquivos

| Arquivo | Uso |
|---|---|
| `apps/mobile/assets/logo/logo.svg` | Logo principal (fundo transparente), usado no app |
| `apps/mobile/assets/logo/icon.png` | Ícone 1024² com fundo branco arredondado (lojas) |
| `apps/mobile/assets/logo/icon_fg.png` | Camada *foreground* do ícone adaptativo Android |
| `docs/brand/gerar_logo_anel.py` | Gerador — mude cores/geometria aqui e regenere |

Regenerar:

```bash
cd apps/mobile/assets/logo
python3 ../../../../docs/brand/gerar_logo_anel.py logo.svg
python3 ../../../../docs/brand/gerar_logo_anel.py icon.svg --margem=10 --fundo=#FFFFFF
python3 ../../../../docs/brand/gerar_logo_anel.py icon_fg.svg --margem=40
# converter os .svg de ícone para PNG 1024 (macOS: qlmanage -t -s 1024; ou rsvg-convert)
cd ../.. && dart run flutter_launcher_icons
```

## Paleta

| Nome | Hex | Onde |
|---|---|---|
| Rosa-vermelho | `#FF3B5C` | peça 1 (a que entra) |
| Laranja | `#FF8C1A` | peça 2 |
| Amarelo | `#FFD60A` | peça 3 |
| Verde | `#3DDC84` | peça 4 |
| Azul-céu | `#00B4FF` | peça 5 |
| Violeta | `#8A4DFF` | peça 6 |
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
