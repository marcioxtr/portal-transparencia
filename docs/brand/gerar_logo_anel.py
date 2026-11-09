"""Logo original: anel de 6 peças de quebra-cabeça, uma pessoa por peça,
uma peça se encaixando. Centro vazio = transparência.

Uso: python3 -I gerar_logo_anel.py saida.svg [--margem=N] [--fundo=#hex] [--sem-levantar] [--tamanho=PX]
"""
import math
import sys

CX = CY = 100.0
R_EXT = 88.0
R_INT = 44.0
N = 6
CORES = ['#FF3B5C', '#FF8C1A', '#FFD60A', '#3DDC84', '#00B4FF', '#8A4DFF']
LEVANTAR = 0          # índice da peça que está "entrando"
DESLOC = 9.0          # quanto ela se afasta
GIRO = 6.0            # graus


def pol(r, ang):
    return CX + r * math.cos(ang), CY + r * math.sin(ang)


def knob(d):
    """Pontos (u,v) de uma aresta unitária com aba: d=+1 fora, -1 dentro."""
    k = -0.15 * d
    b = -0.40 * d
    return [
        ('L', [(0.33, 0)]),
        ('C', [(0.45, 0), (0.38, k * 0.6), (0.40, k)]),
        ('C', [(0.20, b), (0.80, b), (0.60, k)]),
        ('C', [(0.62, k * 0.6), (0.55, 0), (0.67, 0)]),
        ('L', [(1, 0)]),
    ]


def aresta_radial(ang, para_fora, d):
    """Aresta reta ao longo do raio `ang`, com aba. Caminhada horária."""
    p0 = pol(R_INT if para_fora else R_EXT, ang)
    p1 = pol(R_EXT if para_fora else R_INT, ang)
    L = R_EXT - R_INT
    dx, dy = (p1[0] - p0[0]) / L, (p1[1] - p0[1]) / L
    nx, ny = -dy, dx  # normal à direita da direção (interior da peça)
    out = []
    for cmd, pts in knob(d):
        out.append(cmd + ' '.join(
            f'{p0[0] + u*L*dx + v*L*nx:.2f} {p0[1] + u*L*dy + v*L*ny:.2f}' for u, v in pts))
    return out


def peca(i):
    a0 = -math.pi / 2 + i * 2 * math.pi / N
    a1 = a0 + 2 * math.pi / N
    # aba pertence à peça de índice par na aresta i (esquerda) → alterna
    d_esq = -1 if i % 2 == 0 else +1   # aresta a0, caminhando para fora
    d_dir = +1 if i % 2 == 0 else -1   # aresta a1, caminhando para dentro
    p = [f'M{pol(R_INT, a0)[0]:.2f} {pol(R_INT, a0)[1]:.2f}']
    p += aresta_radial(a0, True, d_esq)
    x, y = pol(R_EXT, a1)
    p.append(f'A{R_EXT:.2f} {R_EXT:.2f} 0 0 1 {x:.2f} {y:.2f}')
    p += aresta_radial(a1, False, d_dir)
    x, y = pol(R_INT, a0)
    p.append(f'A{R_INT:.2f} {R_INT:.2f} 0 0 0 {x:.2f} {y:.2f}')
    p.append('Z')
    return ' '.join(p)


def pessoa(i):
    mid = -math.pi / 2 + (i + 0.5) * 2 * math.pi / N
    deg = math.degrees(mid)
    rm = (R_INT + R_EXT) / 2
    # Pessoa olhando para o centro: cabeça (círculo) mais perto do centro,
    # ombros (meia-lua) atrás dela. Desenhada no eixo +x e girada.
    # Ícone "pessoa": cabeça redonda + ombros (cantos arredondados do lado da
    # cabeça, base reta do lado de fora). Desenhado no eixo +x e girado.
    hx = CX + rm - 9.0
    b0 = CX + rm - 0.5          # topo dos ombros (lado da cabeça)
    b1 = CX + rm + 11.0         # base (lado externo)
    w = 20.0
    rc = 7.0
    ombros = (f'M{b1:.2f} {CY - w/2:.2f} L{b0 + rc:.2f} {CY - w/2:.2f} '
              f'Q{b0:.2f} {CY - w/2:.2f} {b0:.2f} {CY - w/2 + rc:.2f} '
              f'L{b0:.2f} {CY + w/2 - rc:.2f} '
              f'Q{b0:.2f} {CY + w/2:.2f} {b0 + rc:.2f} {CY + w/2:.2f} '
              f'L{b1:.2f} {CY + w/2:.2f} Z')
    return (f'<g transform="rotate({deg:.2f} {CX} {CY})">'
            f'<circle cx="{hx:.2f}" cy="{CY}" r="6.8" fill="#fff"/>'
            f'<path d="{ombros}" fill="#fff"/>'
            f'</g>')


def svg(margem, fundo, levantar, tamanho=200):
    esc = 200.0 / (200.0 + 2 * margem)
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="{tamanho}" height="{tamanho}" '
           'role="img" aria-label="Transparência SJBV — pessoas coloridas encaixadas como peças de quebra-cabeça em roda, com o centro aberto">',
           '<!-- Logo original do projeto Transparência SJBV (MIT). Gerado por docs/brand/gerar_logo_anel.py. -->']
    if fundo:
        out.append(f'<rect width="200" height="200" rx="44" fill="{fundo}"/>')
    out.append(f'<g transform="translate(100 100) scale({esc:.4f}) translate(-100 -100)">')
    for i in range(N):
        tr = ''
        if levantar and i == LEVANTAR:
            mid = -math.pi / 2 + (i + 0.5) * 2 * math.pi / N
            dx, dy = DESLOC * math.cos(mid), DESLOC * math.sin(mid)
            tr = f' transform="translate({dx:.2f} {dy:.2f}) rotate({GIRO} {CX} {CY})"'
        out.append(f'<g{tr}>')
        out.append(f'<path d="{peca(i)}" fill="{CORES[i]}" stroke="#fff" stroke-width="2.6" stroke-linejoin="round"/>')
        out.append(pessoa(i))
        out.append('</g>')
    out.append('</g></svg>')
    return '\n'.join(out) + '\n'


if __name__ == '__main__':
    saida = sys.argv[1]
    margem, fundo, levantar, tamanho = 0.0, None, True, 200
    for a in sys.argv[2:]:
        if a.startswith('--margem='):
            margem = float(a.split('=', 1)[1])
        elif a.startswith('--fundo='):
            fundo = a.split('=', 1)[1]
        elif a == '--sem-levantar':
            levantar = False
        elif a.startswith('--tamanho='):
            tamanho = int(a.split('=', 1)[1])
    with open(saida, 'w', encoding='utf-8') as f:
        f.write(svg(margem, fundo, levantar, tamanho))
    print('ok', saida)
