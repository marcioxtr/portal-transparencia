"""Notícias da Prefeitura: RSS oficial + primeira página de cada departamento.

Saída (dados/noticias.json):
{
  "ultimas": [{"titulo","url","data","departamento","resumo","imagem"}],   # ≤ 150, mais recentes primeiro
  "porDepartamento": {"slug": "Nome do departamento"},
  "fontes": {"rss": url, "site": url}
}
"""
import html as H
import re
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime
from email.utils import parsedate_to_datetime

from . import comum

SITE = comum.SITE
RSS = 'https://ecrie20.com.br/saojoao.sp.gov.br/feed.xml'
MAX = 150


def _departamentos():
    """Descobre /noticias/<slug> no mapa do site (sem lista fixa)."""
    html_ = comum.get(f'{SITE}/mapa-do-site') or ''
    out = {}
    for href, nome in re.findall(r'href="(/noticias/[a-z0-9\-]+)"[^>]*>(.*?)</a>', html_, re.S):
        slug = href.rsplit('/', 1)[-1]
        nome = comum.texto(nome)
        if slug and nome and slug not in out:
            out[slug] = nome
    return out


def _rss():
    xml_ = comum.get(RSS)
    if not xml_:
        return []
    out = []
    try:
        root = ET.fromstring(xml_.encode('utf-8'))
    except ET.ParseError:
        return []
    for it in root.iter('item'):
        g = lambda tag: (it.findtext(tag) or '').strip()  # noqa: E731
        data = None
        try:
            data = parsedate_to_datetime(g('pubDate')).date().isoformat()
        except Exception:  # noqa: BLE001
            pass
        desc_html = H.unescape(g('description'))
        img = re.search(r'<img[^>]+src="([^"]+)"', desc_html)
        media = it.find('{http://search.yahoo.com/mrss/}content')
        imagem = (media.get('url') if media is not None else None) or (img.group(1) if img else None)
        if imagem and (imagem.startswith('data:') or len(imagem) > 300):
            imagem = None
        out.append({
            'titulo': H.unescape(g('title')),
            'url': g('link'),
            'data': data,
            'departamento': None,
            'resumo': comum.texto(desc_html)[:280],
            'imagem': imagem,
        })
    return out


def _data_relativa(txt):
    from datetime import date, timedelta
    m = re.search(r'(\d{2}/\d{2}/\d{4})', txt)
    if m:
        return comum.data_iso(m.group(1))
    m = re.search(r'H[áa]\s+(\d+)\s+(dia|hora|minuto|semana|m[êe]s|mes)', txt, re.I)
    if m:
        n, u = int(m.group(1)), m.group(2).lower()
        dias = n if u.startswith('dia') else 7 * n if u.startswith('semana') else 30 * n if u.startswith('m') else 0
        return (date.today() - timedelta(days=dias)).isoformat()
    if re.search(r'\bontem\b', txt, re.I):
        return (date.today() - timedelta(days=1)).isoformat()
    if re.search(r'\bhoje\b', txt, re.I):
        return date.today().isoformat()
    return None


def _lista_departamento(slug, nome):
    html_ = comum.get(f'{SITE}/noticias/{slug}') or ''
    out = []
    for li in re.findall(r'<li class="list-item[^"]*"[^>]*>(.*?)</li>', comum.conteudo(html_), re.S):
        a = re.search(r'<a class="list-item__link" href="([^"]+)"[^>]*>(.*?)</a>', li, re.S)
        if not a:
            continue
        img = re.search(r'<img[^>]+src="([^"]+)"', li)
        desc = re.search(r'class="list-(?:item__)?description"[^>]*>(.*?)</(?:p|div)>', li, re.S)
        out.append({
            'titulo': comum.texto(a.group(2)),
            'url': urllib.parse.urljoin(SITE, a.group(1)),
            'data': _data_relativa(comum.texto(li)),
            'departamento': nome,
            'resumo': comum.texto(desc.group(1))[:280] if desc else '',
            'imagem': urllib.parse.urljoin(SITE, img.group(1)) if img else None,
        })
    return out


def coletar():
    deps = _departamentos()
    comum.log(f'{len(deps)} departamentos com notícias')
    itens = _rss()
    comum.log(f'RSS: {len(itens)} itens')
    por_url = {i['url'].rstrip('/').replace('https://www.', 'https://'): i for i in itens}
    for slug, nome in deps.items():
        for n in _lista_departamento(slug, nome):
            k = n['url'].rstrip('/').replace('https://www.', 'https://')
            if k in por_url:
                por_url[k]['departamento'] = por_url[k]['departamento'] or nome
                por_url[k]['data'] = por_url[k]['data'] or n['data']
                por_url[k]['imagem'] = por_url[k]['imagem'] or n['imagem']
            else:
                por_url[k] = n
    todas = sorted(por_url.values(), key=lambda n: n['data'] or '', reverse=True)[:MAX]
    return {
        'fontes': {'rss': RSS, 'site': f'{SITE}/noticias'},
        'porDepartamento': deps,
        'ultimas': todas,
    }
