"""Utilidades compartilhadas pelos coletores (HTTP educado, parsing de HTML do CMS
eCrie, formatos brasileiros). Sem dependências fora da biblioteca padrão."""
import html as H
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

UA = 'TransparenciaSJBV-coletor/0.2 (+https://github.com/marcioxtr/portal-transparencia)'
SITE = 'https://www.saojoao.sp.gov.br'
SAPL = 'https://sapl.saojoaodaboavista.sp.leg.br/api'
RAIZ = Path(__file__).resolve().parent.parent  # dados/


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def agora():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def get(url, tentativas=3, timeout=90, json_=False, pausa=0.4):
    """GET com User-Agent identificado, retry com backoff e pausa (educação)."""
    req = urllib.request.Request(url, headers={'User-Agent': UA, 'Accept': 'application/json' if json_ else 'text/html,*/*'})
    for i in range(tentativas):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                dados = r.read()
            time.sleep(pausa)
            if json_:
                return json.loads(dados.decode('utf-8'))
            return dados.decode('utf-8', 'ignore')
        except Exception as e:  # noqa: BLE001
            log(f'  tentativa {i + 1} falhou: {url} → {e}')
            time.sleep(2 * (i + 1))
    return None


def get_json(url, **kw):
    return get(url, json_=True, **kw)


def sapl_todos(caminho, params=None, max_paginas=400, page_size=100):
    """Percorre todas as páginas de um endpoint do SAPL."""
    params = dict(params or {})
    params['page_size'] = page_size
    itens, pagina = [], 1
    while pagina <= max_paginas:
        params['page'] = pagina
        d = get_json(f'{SAPL}/{caminho}/?{urllib.parse.urlencode(params)}')
        if not d:
            break
        itens.extend(d.get('results', []))
        if not d.get('pagination', {}).get('links', {}).get('next'):
            break
        pagina += 1
    return itens


# ── HTML do CMS eCrie ──────────────────────────────────────────────────────

def texto(s):
    """Remove tags e normaliza espaços."""
    s = re.sub(r'<script.*?</script>|<style.*?</style>', '', s or '', flags=re.S)
    s = re.sub(r'<br\s*/?>', '\n', s)
    s = re.sub(r'<[^>]+>', ' ', s)
    return re.sub(r'[ \t\r\f\v]+', ' ', H.unescape(s)).strip()


def conteudo(html_):
    m = re.search(r'id="conteudo".*?id="final-pagina"', html_ or '', re.S)
    return m.group(0) if m else (html_ or '')


def itens_lista(html_):
    """Itens de uma lista padrão do CMS: [(url, titulo, publicadoEm|None, descricao)]."""
    out = []
    for li in re.findall(r'<li class="list-item[^"]*"[^>]*>(.*?)</li>', conteudo(html_), re.S):
        a = re.search(r'<a class="list-item__link" href="([^"]+)"[^>]*>(.*?)</a>', li, re.S)
        if not a:
            continue
        pub = re.search(r'Publicado:\s*(\d{2}/\d{2}/\d{4})', li)
        desc = re.search(r'class="list-description"[^>]*>(.*?)</div>', li, re.S)
        out.append((urllib.parse.urljoin(SITE, a.group(1)), texto(a.group(2)), data_iso(pub.group(1)) if pub else None, texto(desc.group(1)) if desc else ''))
    if not out:  # variante com <article>
        for art in re.findall(r'<article[^>]*>(.*?)</article>', conteudo(html_), re.S):
            a = re.search(r'<a class="list-item__link" href="([^"]+)"[^>]*>(.*?)</a>', art, re.S)
            if not a:
                continue
            desc = re.search(r'class="list-description"[^>]*>(.*?)</div>', art, re.S)
            out.append((urllib.parse.urljoin(SITE, a.group(1)), texto(a.group(2)), None, texto(desc.group(1)) if desc else ''))
    return out


def total_paginas(html_):
    m = re.search(r'página\s+\d+\s+de\s+(\d+)', html_ or '')
    return int(m.group(1)) if m else 1


def campos(html_):
    """Pares <strong>Rótulo:</strong> valor do corpo → {chave: valor}."""
    out = {}
    corpo = conteudo(html_)
    for rot, val in re.findall(r'<(?:strong|b)>\s*([^<]+?)\s*:?\s*</(?:strong|b)>\s*:?\s*(.*?)(?=<(?:strong|b)>|</p>|<br|</div>)', corpo, re.S):
        v = texto(val)
        if v:
            out[chave(rot)] = v
    return out


def chave(rotulo):
    s = texto(rotulo).lower().replace(':', '')
    s = s.translate(str.maketrans('áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc'))
    s = re.sub(r'\(.*?\)', '', s)
    return re.sub(r'[^a-z0-9]+', '_', s).strip('_')


def pdfs(html_):
    return sorted({urllib.parse.urljoin(SITE, u) for u in re.findall(r'href="([^"]+\.pdf[^"]*)"', conteudo(html_), re.I)})


def data_iso(br):
    m = re.search(r'(\d{2})/(\d{2})/(\d{4})', br or '')
    return f'{m.group(3)}-{m.group(2)}-{m.group(1)}' if m else None


def reais(s):
    m = re.search(r'(\d{1,3}(?:\.\d{3})*|\d+)(?:,(\d{1,2}))?', (s or '').replace('R$', ''))
    if not m:
        return None
    return round(float(m.group(1).replace('.', '')) + float('0.' + (m.group(2) or '0')), 2)


def percentual(s):
    m = re.search(r'(\d+(?:,\d+)?)\s*%', s or '')
    return float(m.group(1).replace(',', '.')) if m else None


def salvar(nome, dados):
    """Escreve dados/<nome>.json e a cópia embarcada no app."""
    corpo = {'geradoEm': agora(), **dados}
    for destino in (RAIZ / f'{nome}.json', RAIZ.parent / 'apps' / 'mobile' / 'assets' / 'dados' / f'{nome}.json'):
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_text(json.dumps(corpo, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    log(f'ok → dados/{nome}.json ({(RAIZ / f"{nome}.json").stat().st_size // 1024} KB)')
