"""Serviços e participação: unidades de saúde, escolas, conselhos, departamentos,
Carta de Serviços, relatórios da Ouvidoria, multas, Programa de Metas, modelos.

Saída (dados/servicos.json): ver chaves em `coletar()`. Tudo descoberto a partir
do site (mapa do site + listagens) — sem listas fixas de URLs.
"""
import re
import urllib.parse

from . import comum

SITE = comum.SITE
_TEL = re.compile(r'(?:\(?\b\d{2}\)?\s?)?\b\d{4,5}-\d{4}\b')
_END = re.compile(r'\b(Rua|Av\.?|Avenida|Pra[çc]a|Travessa|Alameda|Rodovia|Estrada|Largo)\b[^|\n]{3,120}', re.I)


def _linhas(fragmento):
    f = re.sub(r'</(p|div|li|h\d|span|br)>|<br\s*/?>', '\n', fragmento)
    return [l.strip() for l in comum.texto(f).split('\n') if l.strip()]


def _cards(html_, classe):
    """Segmentos entre ocorrências do <li class="classe"> (tolera <li> aninhados)."""
    partes = re.split(r'<li class="%s[^"]*"[^>]*>' % classe, comum.conteudo(html_))
    return [re.split(r'</ul>\s*</div>\s*</div>\s*</li>|</ul>\s*</li>', seg)[0] for seg in partes[1:]]


def _ficha(fragmento, url_base):
    """Nome + endereço + telefones + url a partir de um card/ficha genérico."""
    linhas = _linhas(fragmento)
    a = re.search(r'href="([^"]+)"', fragmento)
    nome = next((l for l in linhas if not _TEL.search(l) and not _END.search(l) and len(l) > 3), linhas[0] if linhas else '')
    tels = list(dict.fromkeys(_TEL.findall(fragmento) or [t.group(0) for t in _TEL.finditer(' '.join(linhas))]))
    end = next((_END.search(l).group(0).strip() for l in linhas if _END.search(l)), None)
    return {
        'nome': nome,
        'endereco': end,
        'telefones': [re.sub(r'\s+', ' ', t).strip() for t in tels][:3],
        'url': urllib.parse.urljoin(url_base, a.group(1)) if a else None,
        'detalhes': [l for l in linhas if l != nome and l != end and not _TEL.search(l) and 'email' not in l.lower()][:4],
    }


def unidades_saude():
    base = f'{SITE}/departamentos/saude/unidades-e-telefones-uteis'
    out = []
    for p in range(1, 6):
        html_ = comum.get(base if p == 1 else f'{base}?pagina={p}')
        if not html_:
            break
        cards = _cards(html_, 'pages-cards__grid-item')
        for c in cards:
            f = _ficha(c, base)
            h3 = re.search(r'<h3[^>]*>(.*?)</h3>', c, re.S)
            if h3:
                f['nome'] = comum.texto(h3.group(1))
            if f['url'] and not f['endereco']:
                det = comum.get(f['url']) or ''
                corpo = re.sub(r'<nav.*?</nav>|<div class="post-share.*?</div>\s*</div>', ' ', comum.conteudo(det), flags=re.S)
                m = _END.search(comum.texto(re.sub(r'</(p|div|li|span)>', '\n', corpo)))
                f['endereco'] = m.group(0).strip() if m else None
                f['telefones'] = f['telefones'] or list(dict.fromkeys(_TEL.findall(comum.texto(corpo))))[:3]
            if f['nome']:
                out.append(f)
        if p >= comum.total_paginas(html_) or not cards:
            break
    return out


def escolas():
    base = f'{SITE}/educacao/escolas-municipais'
    html_ = comum.get(base) or ''
    links = re.findall(r'href="((?:https?://(?:www\.)?saojoao\.sp\.gov\.br)?/educacao/escolas-municipais/[^"#?]+)"', comum.conteudo(html_))
    vistos, out = set(), []
    for l in links:
        u = urllib.parse.urljoin(SITE, l).rstrip('/')
        if u in vistos or u.rstrip('/') == base or 'merenda' in u or 'cardapio' in u:
            continue
        vistos.add(u)
    for u in sorted(vistos):
        h = comum.get(u) or ''
        t = re.search(r'<h1[^>]*>(.*?)</h1>', h, re.S)
        corpo = re.sub(r'<nav.*?</nav>|<div class="post-share.*?</div>\s*</div>', ' ', comum.conteudo(h), flags=re.S)
        f = _ficha(corpo, u)
        f['nome'] = comum.texto(t.group(1)) if t else f['nome']
        f['url'] = u
        card = re.search(r'href="([^"]*(?:merenda|cardapio)[^"]*)"', comum.conteudo(h), re.I)
        f['cardapio'] = urllib.parse.urljoin(SITE, card.group(1)) if card else None
        f.pop('detalhes', None)
        out.append(f)
    return out


def departamentos():
    html_ = comum.get(f'{SITE}/departamentos') or ''
    out = []
    for c in _cards(html_, 'lista-secretarias-modulo__grid-item'):
        linhas = _linhas(c)
        if not linhas:
            continue
        a = re.search(r'href="([^"]+)"', c)
        resp = next((l for l in linhas if re.match(r'^(Ilm[oa]\.|Sr\.|Sra\.|Dr\.|Dra\.)', l)), None)
        hor = next((l for l in linhas if re.search(r'\d{1,2}h', l)), None)
        out.append({
            'nome': linhas[0],
            'responsavel': re.sub(r'^(Ilm[oa]\.\s*Sr[a]?\.\s*)', '', resp) if resp else None,
            'horario': hor,
            'telefones': list(dict.fromkeys(_TEL.findall(' '.join(linhas))))[:2],
            'endereco': next((_END.search(l).group(0).strip() for l in linhas if _END.search(l)), None),
            'url': urllib.parse.urljoin(SITE, a.group(1)) if a else None,
        })
    return out


def conselhos():
    """Descobre as páginas de conselhos pelo mapa do site e lê as últimas publicações."""
    mapa = comum.get(f'{SITE}/mapa-do-site') or ''
    cand = {}
    for href, nome in re.findall(r'href="([^"]+)"[^>]*>(.*?)</a>', comum.conteudo(mapa), re.S):
        n = comum.texto(nome)
        if re.search(r'conselh|comit[êe]|comad|comsea|condema|cmdca|comtur', href + ' ' + n, re.I) and 'agenda-de-reunioes' not in href:
            u = urllib.parse.urljoin(SITE, href).split('?')[0].rstrip('/')
            cand.setdefault(u, n)
    out = []
    for u, nome in sorted(cand.items(), key=lambda kv: kv[1]):
        h = comum.get(u) or ''
        itens = comum.itens_lista(h)[:5]
        sigla = re.search(r'\(([A-Z]{3,8})\)|[-–]\s*([A-Z]{3,8})\s*$', nome)
        desc = ''
        corpo = re.sub(r'<nav.*?</nav>|<div class="post-share.*?</div>\s*</div>', ' ', comum.conteudo(h), flags=re.S)
        for par in re.findall(r'<p[^>]*>(.*?)</p>', corpo, re.S):
            tx = comum.texto(par)
            if len(tx) > 80 and 'Publicado' not in tx:
                desc = tx[:300]
                break
        out.append({
            'nome': re.sub(r'\s*\((?:[A-Z]{3,8})\)\s*$', '', nome).strip(),
            'sigla': (sigla.group(1) or sigla.group(2)) if sigla else None,
            'url': u,
            'descricao': desc or None,
            'publicacoes': [{'titulo': t, 'url': iu, 'publicadoEm': pub} for iu, t, pub, _ in itens],
            'pdfs': comum.pdfs(h)[:8],
        })
    return out


def _pdfs_rotulados(caminho):
    html_ = comum.get(f'{SITE}{caminho}') or ''
    out = []
    for href, rot in re.findall(r'<a [^>]*href="([^"]+\.(?:pdf|docx?|xlsx?)[^"]*)"[^>]*>(.*?)</a>', comum.conteudo(html_), re.S | re.I):
        rotulo = comum.texto(rot)
        if not rotulo or re.match(r'^(acesse aqui|clique aqui|aqui|download|baixar)$', rotulo, re.I):
            # usa o texto imediatamente anterior ao link como rótulo
            idx = html_.find(href)
            antes = html_[max(0, idx - 600):idx]
            antes = antes[:antes.rfind('<')] if '<' in antes else antes
            antes = re.sub(r'</(p|div|li|h\d|tr|td)>', '\n', antes)
            linhas = [l.strip(' -–:\xa0') for l in comum.texto(antes).split('\n') if l.strip(' -–:\xa0')]
            rotulo = (linhas[-1][-120:] if linhas else rotulo) or rotulo
        out.append({'titulo': rotulo, 'url': urllib.parse.urljoin(SITE, href)})
    vistos, uniq = set(), []
    for o in out:
        if o['url'] not in vistos:
            vistos.add(o['url']); uniq.append(o)
    return uniq


def coletar():
    comum.log('unidades de saúde'); us = unidades_saude()
    comum.log('escolas'); es = escolas()
    comum.log('departamentos'); dp = departamentos()
    comum.log('conselhos'); cs = conselhos()
    comum.log('documentos')
    carta = _pdfs_rotulados('/carta-de-servicos')
    ouv = _pdfs_rotulados('/cidadao/ouvidoria/relatorios')
    for o in ouv:
        a = re.search(r'(20\d{2})', o['titulo']); o['ano'] = int(a.group(1)) if a else None
    multas = _pdfs_rotulados('/departamentos/seguranca-e-transito/arrecadacao-e-aplicacao-de-multas')
    metas = _pdfs_rotulados('/departamentos/desenvolvimento-economico/programa-de-metas')
    modelos = _pdfs_rotulados('/cidadao/modelos-de-requerimentos')
    return {
        'fontes': {'site': SITE},
        'unidadesSaude': us,
        'escolas': es,
        'departamentos': dp,
        'conselhos': cs,
        'cartaServicos': {'url': f'{SITE}/carta-de-servicos', 'documentos': carta},
        'ouvidoriaRelatorios': {'url': f'{SITE}/cidadao/ouvidoria/relatorios', 'documentos': ouv},
        'multas': {'url': f'{SITE}/departamentos/seguranca-e-transito/arrecadacao-e-aplicacao-de-multas', 'documentos': multas},
        'programaMetas': {'url': f'{SITE}/departamentos/desenvolvimento-economico/programa-de-metas', 'documentos': metas},
        'modelos': {'url': f'{SITE}/cidadao/modelos-de-requerimentos', 'documentos': modelos},
    }
