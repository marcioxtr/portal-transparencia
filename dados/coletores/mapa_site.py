"""Mapa completo do site oficial, para o app mostrar *tudo* o que a Prefeitura
publica — e indicar o que já está organizado dentro do app.

Fontes: https://www.saojoao.sp.gov.br/mapa-do-site (cards com h2 + listas
aninhadas) e o menu principal da home.

Esquema de saída:
{
  "fonte": "https://www.saojoao.sp.gov.br/mapa-do-site",
  "total": n, "noApp": n_mapeados, "externos": n_externos,
  "categorias": [ {"nome": "Transparência", "itens": [item...]} ],
  "itens": [ {"url", "titulo", "secao", "subsecao", "grupo", "externo", "dominio",
              "categoria", "noApp": "/rota" | null} ]
}
"""
import re
import urllib.parse

from . import comum

MAPA = f'{comum.SITE}/mapa-do-site'

# Ordem define a prioridade de exibição.
CATEGORIAS = [
    'Transparência', 'Serviços ao cidadão', 'Departamentos', 'Conselhos', 'Educação',
    'Saúde', 'Cultura e esportes', 'Notícias', 'Institucional', 'Sistemas externos',
]

# (padrão de caminho, rota interna). Primeiro que casar vence.
ROTAS_INTERNAS = [
    (r'^/contratos', '/contratos'),
    (r'^/transparencia/emendas-parlamentares', '/emendas'),
    (r'^/obras', '/obras'),
    (r'^/transparencia/(chamamentos-publicos|compras-e-licitacoes|processos-seletivos)', '/licitacoes'),
    (r'^/transparencia/transparencia-ate-2022', '/documentos'),
    (r'^/transparencia/contas-publicas', '/documentos'),
    (r'^/transparencia/(despesas-com-funcionarios|quadro-de-pessoal|despesas-com-publicidade|diaria-pessoal-civil|planejamento-orcamentario|relacao-de-bens|concursos-publicos)', '/documentos'),
    (r'^/jornal-oficial', '/documentos'),
    (r'^/cidadao/ouvidoria', '/cobrar'),
    (r'^/transparencia/o-que-e-o-e-sic', '/cobrar'),
    (r'^/cidadao/modelos-de-requerimentos', '/cobrar'),
    (r'^/transparencia/agenda-de-reunioes-dos-conselhos-municipais', '/cidade/conselhos'),
    (r'^/conselhos-municipais', '/cidade/conselhos'),
    (r'^/conselho-municipal', '/cidade/conselhos'),
    (r'^/departamentos/[^/]+/conselho', '/cidade/conselhos'),
    (r'^/educacao/conselhos', '/cidade/conselhos'),
    (r'^/noticias', '/cidade/noticias'),
    (r'^/educacao/noticias', '/cidade/noticias'),
    (r'^/cultura/noticias', '/cidade/noticias'),
    (r'^/departamentos/seguranca-e-transito/(interdicoes-no-momento|alteracoes-de-transito)', '/cidade/avisos'),
    (r'^/servicos/coleta-seletiva', '/cidade/avisos'),
    (r'^/noticias/destaques/veja-os-dias-de-coleta', '/cidade/avisos'),
    (r'^/eventos', '/cidade/avisos'),
    (r'^/cultura/agenda', '/cidade/avisos'),
    (r'^/departamentos/saude/unidades-e-telefones-uteis', '/cidade/servicos'),
    (r'^/educacao/escolas-municipais', '/cidade/servicos'),
    (r'^/carta-de-servicos', '/cidade/servicos'),
    (r'^/departamentos', '/cidade/servicos'),
    (r'^/transparencia/leis', '/camara'),
    (r'^/transparencia/decretos', '/camara'),
]
ROTAS_EXTERNAS = [
    (r'saojoaodaboavista\.sp\.leg\.br|sapl\.', '/camara'),
    (r'eouve\.com\.br', '/cobrar'),
    (r'transparencia\.tce\.sp\.gov\.br', '/'),
]


def _categoria(caminho, grupo, externo, dominio, titulo):
    t = (titulo or '').lower()
    if externo:
        if re.search(r'sp\.leg\.br|sapl', dominio):
            return 'Transparência'
        return 'Sistemas externos'
    if caminho.startswith('/transparencia') or caminho in ('/contratos', '/obras', '/jornal-oficial'):
        return 'Transparência'
    if re.search(r'conselho', caminho) or 'conselho' in t:
        return 'Conselhos'
    if caminho.startswith('/educacao'):
        return 'Educação'
    if caminho.startswith('/departamentos/saude') or 'saúde' in t or 'saude' in caminho:
        return 'Saúde'
    if re.search(r'^/(cultura|equipamentos-culturais|documentos-da-cultura|cultura-banners|pnab|eventos)', caminho) or caminho.startswith('/departamentos/esportes') or caminho.startswith('/departamentos/turismo'):
        return 'Cultura e esportes'
    if caminho.startswith('/noticias'):
        return 'Notícias'
    if caminho.startswith('/departamentos'):
        return 'Departamentos'
    if re.search(r'^/(cidadao|servicos|atualizacao-cadastral|carta-de-servicos|perguntas-frequentes|empresas|servidores|recadastramentos|coletas)', caminho) or 'servi' in (grupo or '').lower():
        return 'Serviços ao cidadão'
    if re.search(r'^/(a-cidade|institucional|contato|plano-diretor|mapa-do-site|acessibilidade|politica-de-privacidade)', caminho) or caminho == '/':
        return 'Institucional'
    return 'Serviços ao cidadão'


def _rota_interna(caminho, externo, dominio):
    if externo:
        for pad, rota in ROTAS_EXTERNAS:
            if re.search(pad, dominio):
                return rota
        return None
    for pad, rota in ROTAS_INTERNAS:
        if re.search(pad, caminho):
            return rota
    return None


def _item(href, titulo, grupo, subsecao=None):
    url = urllib.parse.urljoin(comum.SITE, href.strip())
    p = urllib.parse.urlparse(url)
    dominio = p.netloc.lower()
    externo = 'saojoao.sp.gov.br' not in dominio
    caminho = re.sub(r'/+$', '', p.path) or '/'
    if not externo:
        url = f'{comum.SITE}{caminho}' + (f'?{p.query}' if p.query else '')
    secao = caminho.split('/')[1] if not externo and caminho != '/' else dominio
    titulo = re.sub(r'\s*Acesse todas as informações.*$', '', comum.texto(titulo)).strip()
    return {
        'url': url, 'titulo': titulo, 'secao': secao, 'subsecao': subsecao, 'grupo': grupo,
        'externo': externo, 'dominio': dominio,
        'categoria': _categoria(caminho, grupo, externo, dominio, titulo),
        'noApp': _rota_interna(caminho, externo, dominio),
    }


def _mapa(html_):
    """Cards: h2 título → ul (li item → ul li subitem)."""
    itens = []
    corpo = comum.conteudo(html_)
    cards = re.split(r'<h2 class="mapa-site-card__title">', corpo)
    for card in cards[1:]:
        grupo = comum.texto(card.split('</h2>', 1)[0])
        for li in re.findall(r'<li class="mapa-site-card__list-item">(.*?)(?=<li class="mapa-site-card__list-item">|</ul>\s*</div>|$)', card, re.S):
            a = re.search(r'<a class="mapa-site-card__link" href="([^"]+)"[^>]*>(.*?)</a>', li, re.S)
            if not a:
                continue
            pai = _item(a.group(1), a.group(2), grupo)
            itens.append(pai)
            for sub in re.findall(r'<li class="mapa-site-card__sublist-item">(.*?)</li>', li, re.S):
                b = re.search(r'<a [^>]*href="([^"]+)"[^>]*>(.*?)</a>', sub, re.S)
                if b:
                    itens.append(_item(b.group(1), b.group(2), grupo, subsecao=pai['titulo']))
    return itens


def _menu_home(html_):
    itens = []
    for a in re.findall(r'<a class="(?:site-nav__link|dropdown__link)[^"]*" href="([^"]+)"[^>]*>(.*?)</a>', html_ or '', re.S):
        href, titulo = a
        if href.startswith('#') or 'javascript' in href:
            continue
        itens.append(_item(href, titulo, 'Menu principal'))
    return itens


def coletar():
    comum.log(f'GET {MAPA}')
    html_mapa = comum.get(MAPA) or ''
    comum.log(f'GET {comum.SITE}/')
    html_home = comum.get(f'{comum.SITE}/') or ''

    vistos, itens = set(), []
    for it in _mapa(html_mapa) + _menu_home(html_home):
        chave = it['url'].lower()
        if chave in vistos or not it['titulo']:
            continue
        vistos.add(chave)
        itens.append(it)

    ordem = {c: i for i, c in enumerate(CATEGORIAS)}
    itens.sort(key=lambda i: (ordem.get(i['categoria'], 99), i['grupo'] or '', i['subsecao'] or '', i['titulo']))
    categorias = []
    for nome in CATEGORIAS:
        grupo = [i for i in itens if i['categoria'] == nome]
        if grupo:
            categorias.append({'nome': nome, 'total': len(grupo), 'noApp': sum(1 for i in grupo if i['noApp']), 'itens': grupo})

    comum.log(f'{len(itens)} links · {sum(1 for i in itens if i["noApp"])} com rota no app · {sum(1 for i in itens if i["externo"])} externos')
    return {
        'fonte': MAPA,
        'total': len(itens),
        'noApp': sum(1 for i in itens if i['noApp']),
        'externos': sum(1 for i in itens if i['externo']),
        'categorias': categorias,
        'itens': itens,
    }
