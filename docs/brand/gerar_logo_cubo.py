"""Logo original: cubo isométrico montado de peças de quebra-cabeça.
Três faces (topo, esquerda, direita), cada uma com 2×2 peças encaixadas.
Conceito: a cidade se monta peça por peça; cada face é um lado da história
(quem arrecada, quem gasta, quem fiscaliza).

Uso: python3 -I gerar_logo_cubo.py saida.svg [--margem=N] [--fundo=#hex] [--tamanho=PX]
"""
import math
import sys

L = 78.0                 # aresta do cubo
CX, CY = 100.0, 104.0    # vértice central (onde as 3 faces se encontram)
EX = (math.cos(math.radians(30)) * L, math.sin(math.radians(30)) * L)   # (67.5, 39)
EY = (-EX[0], EX[1])
EZ = (0.0, L)

ROSA, LARANJA, AMARELO, VERDE, CEU, VIOLETA = '#FF3B5C', '#FF8C1A', '#FFD60A', '#3DDC84', '#00B4FF', '#8A4DFF'
FACES = {
    'topo': ([ROSA, AMARELO, CEU, VERDE], 1.00),
    'esq':  ([VIOLETA, LARANJA, CEU, ROSA], 0.78),
    'dir':  ([VERDE, VIOLETA, AMARELO, LARANJA], 0.62),
}
# encaixes da grade 2x2: H[0][c] aresta horizontal entre linhas; V[r][0] vertical
H = [[+1, -1]]
V = [[+1], [-1]]


def escurecer(hexcor, f):
    r, g, b = (int(hexcor[i:i + 2], 16) for i in (1, 3, 5))
    return '#%02X%02X%02X' % (int(r * f), int(g * f), int(b * f))


def knob(d):
    if d == 0:
        return [('L', [(1, 0)])]
    k, b = -0.14 * d, -0.36 * d
    return [('L', [(0.35, 0)]),
            ('C', [(0.45, 0), (0.39, k * 0.6), (0.41, k)]),
            ('C', [(0.24, b), (0.76, b), (0.59, k)]),
            ('C', [(0.61, k * 0.6), (0.55, 0), (0.65, 0)]),
            ('L', [(1, 0)])]


def lado_local(side, r, c):
    """Mapeia (u,v) do lado para coordenadas da face unitária (0..1), caminhada horária."""
    x0, y0, s = c * 0.5, r * 0.5, 0.5
    if side == 0: return lambda u, v: (x0 + u * s, y0 + v * s)
    if side == 1: return lambda u, v: (x0 + s - v * s, y0 + u * s)
    if side == 2: return lambda u, v: (x0 + s - u * s, y0 + s - v * s)
    return lambda u, v: (x0 + v * s, y0 + s - u * s)


def direcao(r, c, side):
    if side == 0: return 0 if r == 0 else -H[r - 1][c]
    if side == 1: return 0 if c == 1 else V[r][c]
    if side == 2: return 0 if r == 1 else H[r][c]
    return 0 if c == 0 else -V[r][c - 1]


def peca_unitaria(r, c):
    pts = [('M', [(c * 0.5, r * 0.5)])]
    for side in range(4):
        t = lado_local(side, r, c)
        for cmd, ps in knob(direcao(r, c, side)):
            pts.append((cmd, [t(u, v) for u, v in ps]))
    return pts


def projetar(face):
    if face == 'topo':
        o = (CX, CY - L)
        return lambda x, y: (o[0] + x * EX[0] + y * EY[0], o[1] + x * EX[1] + y * EY[1])
    if face == 'esq':
        o = (CX + EY[0], CY - L + EY[1])
        return lambda x, y: (o[0] + x * EX[0], o[1] + x * EX[1] + y * EZ[1])
    o = (CX, CY)
    return lambda x, y: (o[0] + x * (-EY[0]), o[1] + x * (-EY[1]) + y * EZ[1])


def path(face, r, c):
    P = projetar(face)
    out = []
    for cmd, ps in peca_unitaria(r, c):
        out.append(cmd + ' '.join('%.2f %.2f' % P(x, y) for x, y in ps))
    return ' '.join(out) + ' Z'


def svg(margem=0.0, fundo=None, tamanho=200):
    esc = 200.0 / (200.0 + 2 * margem)
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="%d" height="%d" role="img" '
         'aria-label="Transparência SJBV — cubo montado de peças de quebra-cabeça coloridas">' % (tamanho, tamanho),
         '<!-- Logo original do projeto Transparência SJBV (MIT). Gerado por docs/brand/gerar_logo_cubo.py. -->']
    if fundo:
        o.append('<rect width="200" height="200" rx="44" fill="%s"/>' % fundo)
    o.append('<g transform="translate(100 100) scale(%.4f) translate(-100 -100)">' % esc)
    # sombra suave no chão
    o.append('<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="#000" opacity="0.10"/>' % (CX, CY + L + 6, L * 1.05, L * 0.22))
    for face in ('esq', 'dir', 'topo'):
        cores, sombra = FACES[face]
        for r in range(2):
            for c in range(2):
                cor = escurecer(cores[r * 2 + c], sombra)
                o.append('<path d="%s" fill="%s" stroke="#fff" stroke-width="2.2" stroke-linejoin="round"/>' % (path(face, r, c), cor))
    o.append('</g></svg>')
    return '\n'.join(o) + '\n'


if __name__ == '__main__':
    saida, margem, fundo, tamanho = sys.argv[1], 0.0, None, 200
    for a in sys.argv[2:]:
        if a.startswith('--margem='): margem = float(a.split('=', 1)[1])
        elif a.startswith('--fundo='): fundo = a.split('=', 1)[1]
        elif a.startswith('--tamanho='): tamanho = int(a.split('=', 1)[1])
    open(saida, 'w', encoding='utf-8').write(svg(margem, fundo, tamanho))
    print('ok', saida)
