"""Avisos da cidade: interdições, alterações de trânsito, coleta seletiva /
cata-treco, eventos e agenda de reuniões dos conselhos — tudo do site oficial.

Saída (dados/avisos.json):
{
  "interdicoes": {"url", "atualizadoEm", "texto", "imagens":[...]},
  "alteracoesTransito": [{"titulo","url","publicadoEm","resumo"}],
  "coleta": {"seletiva": {"url","texto","imagens"}, "cataTreco": {"url","publicadoEm","texto","imagens"}},
  "eventos": [{"titulo","url","agenda","data","hora","local","tipo","imagem"}],
  "reunioesConselhos": [{"conselho","titulo","url","publicadoEm","data","hora","modalidade","local","descricao"}]
}
"""
import html as H
import re
import urllib.parse

from . import comum

SITE = comum.SITE

_SHARE = re.compile(r'<div class="post-share.*?</div>\s*</div>', re.S)
_NAV = re.compile(r'<nav.*?</nav>|<header class="post-header.*?</header>', re.S)


def _corpo(html_):
    """Texto do corpo de um artigo do CMS (sem menu, breadcrumb, botões de compartilhar)."""
    c = comum.conteudo(html_)
    c = re.sub(r'^[^>]*>', '', c, count=1)
    c = _NAV.sub(' ', c)
    c = _SHARE.sub(' ', c)
    c = re.sub(r'<a class="share-btn[^>]*>.*?</a>', ' ', c, flags=re.S)
    c = re.sub(r'<aside.*?</aside>', ' ', c, flags=re.S)
    c = re.sub(r'<ul class="submenu.*?</ul>', ' ', c, flags=re.S)
    c = re.sub(r'<div class="(menu-lateral|sidebar|submenu)[^"]*".*?</div>\s*</div>', ' ', c, flags=re.S)
    c = re.sub(r'</(p|div|li|h\d|tr)>', '\n', c)
    t = comum.texto(c)
    t = re.sub(r'\n\s*\n+', '\n', t)
    return t.strip()


def _imagens(html_):
    c = comum.conteudo(html_)
    urls = re.findall(r'(?:href|src)="(https?://[^"]+\.(?:jpe?g|png|webp)[^"]*)"', c, re.I)
    return list(dict.fromkeys(u for u in urls if 'Arquitetura' not in u))[:12]


def _data_hora(texto):
    """'24/01/2024 às 13h39' / '28/03/2024, quinta-feira às 13:30' → (iso, 'HH:MM')."""
    d = re.search(r'(\d{2}/\d{2}/\d{4})', texto or '')
    h = re.search(r'(\d{1,2})[h:](\d{2})?', (texto or '')[(d.end() if d else 0):][:40])
    hora = f'{int(h.group(1)):02d}:{h.group(2) or "00"}' if h else None
    return (comum.data_iso(d.group(1)) if d else None), hora


def interdicoes():
    url = f'{SITE}/departamentos/seguranca-e-transito/interdicoes-no-momento'
    html_ = comum.get(url) or ''
    cab = re.search(r'(\d{2}/\d{2}/\d{4})\s*(?:&#224;s|às)\s*(\d{1,2}h\d{2})', html_)
    texto = _corpo(html_)
    # remove o título e a data repetidos no topo
    texto = re.sub(r'^\s*(Início\s*)?(INTERDI[ÇC][ÕO]ES NO MOMENTO\s*)?Interdi[çc][õo]es\s*\n?', '', texto, flags=re.I)
    texto = re.sub(r'^\s*\d{2}/\d{2}/\d{4}\s*às\s*\d{1,2}h\d{2}\s*\n?', '', texto)
    return {
        'url': url,
        'atualizadoEm': comum.data_iso(cab.group(1)) if cab else None,
        'hora': cab.group(2).replace('h', ':') if cab else None,
        'texto': texto[:4000],
        'imagens': _imagens(html_),
    }


def alteracoes_transito(paginas=2):
    base = f'{SITE}/departamentos/seguranca-e-transito/alteracoes-de-transito'
    out = []
    for p in range(1, paginas + 1):
        html_ = comum.get(base if p == 1 else f'{base}?pagina={p}')
        if not html_:
            break
        for url, titulo, pub, desc in comum.itens_lista(html_):
            out.append({'titulo': titulo, 'url': url, 'publicadoEm': pub, 'resumo': desc[:300]})
        if p >= comum.total_paginas(html_):
            break
    return out


def coleta():
    sel_url = f'{SITE}/servicos/coleta-seletiva'
    cata_url = f'{SITE}/noticias/destaques/veja-os-dias-de-coleta-cata-treco-no-seu-bairro'
    sel = comum.get(sel_url) or ''
    cata = comum.get(cata_url) or ''
    pub = re.search(r'(\d{2}/\d{2}/\d{4})', comum.conteudo(cata))
    return {
        'seletiva': {'url': sel_url, 'texto': _corpo(sel)[:3000], 'imagens': _imagens(sel)},
        'cataTreco': {'url': cata_url, 'publicadoEm': comum.data_iso(pub.group(1)) if pub else None,
                      'texto': _corpo(cata)[:4000], 'imagens': _imagens(cata)},
    }


_AGENDAS = [
    ('Geral', '/eventos/agenda-geral'),
    ('Cultura', '/eventos/agenda-cultural-1'),
    ('Cultura', '/cultura/agenda'),
    ('Esporte', '/eventos/agenda-do-esporte'),
    ('Agendas', '/eventos-das-agendas'),
]


def eventos():
    out, vistos = [], set()
    for agenda, caminho in _AGENDAS:
        html_ = comum.get(SITE + caminho) or ''
        for item in re.findall(r'<li class="evento__grid-item[^"]*"[^>]*>(.*?)</li>', comum.conteudo(html_), re.S):
            a = re.search(r'href="([^"]+)"', item)
            url = urllib.parse.urljoin(SITE, a.group(1)) if a else None
            if not url or url in vistos:
                continue
            vistos.add(url)
            h3 = re.search(r'<h3[^>]*>(.*?)</h3>', item, re.S)
            tempo = re.search(r'<time[^>]*>.*?<span>(.*?)</span>', item, re.S)
            end = re.search(r'<address[^>]*>.*?<span>(.*?)</span>', item, re.S)
            tipo = re.search(r'class="tipo"[^>]*>(.*?)</span>', item, re.S)
            img = re.search(r'<img[^>]+src="([^"]+)"', item)
            data, hora = _data_hora(comum.texto(tempo.group(1)) if tempo else '')
            out.append({
                'titulo': comum.texto(h3.group(1)) if h3 else comum.texto(item)[:120],
                'local': comum.texto(end.group(1)) if end else None,
                'url': url,
                'agenda': (comum.texto(tipo.group(1)).replace('Agenda de ', '') if tipo else agenda),
                'data': data,
                'hora': hora,
                'imagem': urllib.parse.urljoin(SITE, img.group(1)) if img else None,
            })
    # mesmo evento publicado em duas agendas (ex.: /eventos/agenda-cultural-1 e /cultura/agenda)
    uniq, chaves = [], set()
    for e in sorted(out, key=lambda e: (e['data'] or '9999', e['hora'] or '')):
        k = (e['titulo'].lower(), e['data'], e['hora'])
        if k not in chaves:
            chaves.add(k); uniq.append(e)
    return uniq


_CONSELHO_RE = re.compile(r'(Conselho|Comit[êe]|COMAD|COMSEA|CONDEMA|CMDCA|CMAS|CMS|CTER|CMDE|CMI|CMDM|CMDPcD|CMU|COMTUR)[^|–\-]*', re.I)


def reunioes_conselhos(max_paginas=9):
    base = f'{SITE}/transparencia/agenda-de-reunioes-dos-conselhos-municipais'
    out = []
    for p in range(1, max_paginas + 1):
        html_ = comum.get(base if p == 1 else f'{base}?pagina={p}')
        if not html_:
            break
        for li in re.findall(r'<li class="list-item[^"]*"[^>]*>(.*?)</li>', comum.conteudo(html_), re.S):
            a = re.search(r'<a class="list-item__link" href="([^"]+)"[^>]*>(.*?)</a>', li, re.S)
            if not a:
                continue
            url, titulo = urllib.parse.urljoin(SITE, a.group(1)), comum.texto(a.group(2))
            pubm = re.search(r'Publicado:\s*(\d{2}/\d{2}/\d{4})', li)
            pub = comum.data_iso(pubm.group(1)) if pubm else None
            dm = re.search(r'class="list-item__description"[^>]*>(.*?)</p>', li, re.S)
            desc = comum.texto(dm.group(1)) if dm else ''
            data, hora = _data_hora(desc)
            mod = re.search(r'\b(Presencial|Remot[ao]|On-?line|H[íi]brid[ao]|Virtual)\b', desc, re.I)
            loc = re.search(r'Local:\s*(.+?)(?:\.$|$)', desc)
            cons = _CONSELHO_RE.search(titulo)
            out.append({
                'conselho': cons.group(0).strip(' -–,') if cons else titulo,
                'titulo': titulo,
                'url': url,
                'publicadoEm': pub,
                'data': data,
                'hora': hora,
                'modalidade': mod.group(1).capitalize() if mod else None,
                'local': loc.group(1).strip() if loc else None,
                'descricao': desc[:500],
            })
        if p >= comum.total_paginas(html_):
            break
    uniq, vistos = [], set()
    for r in sorted(out, key=lambda r: (r['data'] or r['publicadoEm'] or ''), reverse=True):
        if r['url'] not in vistos:
            vistos.add(r['url']); uniq.append(r)
    return uniq


def coletar():
    comum.log('interdições'); i = interdicoes()
    comum.log('alterações de trânsito'); a = alteracoes_transito()
    comum.log('coleta'); c = coleta()
    comum.log('eventos'); e = eventos()
    comum.log('reuniões dos conselhos'); r = reunioes_conselhos()
    return {
        'fonte': SITE,
        'interdicoes': i,
        'alteracoesTransito': a,
        'coleta': c,
        'eventos': e,
        'reunioesConselhos': r,
    }
