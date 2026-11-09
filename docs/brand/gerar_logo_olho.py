"""Logo 'Tô de Olho': um olho cuja íris é o cubo de peças de quebra-cabeça.
Reutiliza a geometria de gerar_logo_cubo.py (mesma pasta).

Uso: python3 -I gerar_logo_olho.py saida.svg [--margem=N] [--fundo=#hex] [--tamanho=PX] [--escuro]
"""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location('cubo', Path(__file__).with_name('gerar_logo_cubo.py'))
cubo = importlib.util.module_from_spec(spec); spec.loader.exec_module(cubo)

AZUL = '#4361EE'


def svg(margem=0.0, fundo=None, tamanho=200, escuro=False):
    esc = 200.0 / (200.0 + 2 * margem)
    traco = '#F2F3F8' if escuro else '#14172B'
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="%d" height="%d" role="img" '
         'aria-label="Tô de Olho — um olho cuja íris é um cubo de peças de quebra-cabeça coloridas">' % (tamanho, tamanho),
         '<!-- Logo original do projeto Tô de Olho (MIT). Gerado por docs/brand/gerar_logo_olho.py. -->']
    if fundo:
        o.append('<rect width="200" height="200" rx="44" fill="%s"/>' % fundo)
    o.append('<g transform="translate(100 100) scale(%.4f) translate(-100 -100)">' % esc)
    # Olho (amêndoa): duas curvas quadráticas; branco do olho levemente translúcido
    o.append('<path d="M8 100 Q100 14 192 100 Q100 186 8 100 Z" fill="%s" stroke="%s" stroke-width="7" stroke-linejoin="round"/>'
             % ('#FFFFFF' if not escuro else '#1B1F3B', traco))
    # Íris: anel azul; dentro, o cubo (recortado pelo círculo)
    o.append('<circle cx="100" cy="100" r="56" fill="%s"/>' % AZUL)
    o.append('<defs><clipPath id="iris"><circle cx="100" cy="100" r="49"/></clipPath></defs>')
    o.append('<circle cx="100" cy="100" r="49" fill="#0E1230"/>')
    # cubo inteiro dentro da íris (altura do cubo 156 → ×0.56 ≈ 87 < 98 de diâmetro)
    o.append('<g clip-path="url(#iris)" transform="translate(100 100) scale(0.5) translate(-100 -104)">')
    for face in ('esq', 'dir', 'topo'):
        cores, sombra = cubo.FACES[face]
        for r in range(2):
            for c in range(2):
                cor = cubo.escurecer(cores[r * 2 + c], sombra)
                o.append('<path d="%s" fill="%s" stroke="#fff" stroke-width="2.2" stroke-linejoin="round"/>' % (cubo.path(face, r, c), cor))
    o.append('</g>')
    # brilho da córnea
    o.append('<circle cx="74" cy="76" r="7" fill="#fff" opacity="0.9"/>')
    o.append('</g></svg>')
    return '\n'.join(o) + '\n'


if __name__ == '__main__':
    saida, margem, fundo, tamanho, escuro = sys.argv[1], 0.0, None, 200, False
    for a in sys.argv[2:]:
        if a.startswith('--margem='): margem = float(a.split('=', 1)[1])
        elif a.startswith('--fundo='): fundo = a.split('=', 1)[1]
        elif a.startswith('--tamanho='): tamanho = int(a.split('=', 1)[1])
        elif a == '--escuro': escuro = True
    open(saida, 'w', encoding='utf-8').write(svg(margem, fundo, tamanho, escuro))
    print('ok', saida)
