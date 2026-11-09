"""Chamamentos públicos / inexigibilidades e processos seletivos — site oficial.
Licitações propriamente ditas vivem no portal SmarAPD (link).

Saída (dados/licitacoes.json):
{
  "chamamentos": [{"titulo","url","publicadoEm","despacho","processo","objeto","proponente","justificativa","prazoImpugnacao","pdf","tipo"}],
  "processosSeletivos": [{"titulo","url","publicadoEm","resumo"}],
  "licitacoesUrl": "...", "fontes": {...}
}
"""
import re

from . import comum

SITE = comum.SITE
LICITACOES_URL = ('https://transparencia-saojoaodaboavista.smarapd.com.br/#/dinamico/7/Licitacoes'
                  '?periodicidade=ANUAL&exercicio={ano}&pagina=1&quantidaderegistros=10')


def _campo(texto, rotulo):
    fim = r'(?=\s*(?:Justificativa|Objeto|Proponente|Entidade|Organiza[çc][ãa]o|Valor|Vig[êe]ncia|Fica aberto|O projeto foi)\s*:?|\n[A-ZÁÉÍÓÚÇ][a-zçãõéíóú ]{2,30}:|\n\n|$)'
    m = re.search(r'(?:' + rotulo + r')\s*:\s*(.+?)' + fim, texto, re.S)
    return re.sub(r'\s+', ' ', m.group(1)).strip(' "“”') if m else None


def _detalhe_chamamento(url):
    html_ = comum.get(url) or ''
    c = comum.conteudo(html_)
    c = re.sub(r'<nav.*?</nav>|<header class="post-header.*?</header>|<div class="post-share.*?</div>\s*</div>', ' ', c, flags=re.S)
    c = re.sub(r'</(p|div|li|h\d)>', '\n', c)
    t = comum.texto(c)
    t = re.sub(r'\n\s*\n+', '\n', t)
    pdfs = comum.pdfs(html_)
    desp = re.search(r'DESPACHO\s*P?\s*N[ºo°]\.?\s*([\d/]+)', t, re.I)
    proc = re.search(r'PROCESSO\s*N[ºo°]\.?\s*([\d/\.]+)', t, re.I)
    prazo = re.search(r'prazo de impugna[çc][ãa]o[^.]*?(\d+\s*\(?\w*\)?\s*dias)', t, re.I)
    tipo = 'Inexigibilidade' if re.search(r'inexigibilidade', t, re.I) else (
        'Dispensa' if re.search(r'dispensa', t, re.I) else 'Chamamento público')
    return {
        'despacho': desp.group(1) if desp else None,
        'processo': proc.group(1) if proc else None,
        'objeto': _campo(t, r'Objeto'),
        'proponente': _campo(t, r'Proponente|Entidade|Organiza[çc][ãa]o'),
        'justificativa': (lambda j: re.sub(r'\s+', ' ', j.group(1)).strip()[:600] if j else None)(
            re.search(r'Justificativa\s*:\s*(.+?)(?=\s*(?:Fica aberto|O projeto foi aprovado|\n\d{1,2} de \w+ de \d{4})|$)', t, re.S)),
        'valor': comum.reais(_campo(t, r'Valor(?: total| global| do repasse)?') or ''),
        'prazoImpugnacao': prazo.group(1) if prazo else None,
        'pdf': pdfs[0] if pdfs else None,
        'tipo': tipo,
    }


def chamamentos(max_paginas=6):
    base = f'{SITE}/transparencia/chamamentos-publicos'
    out = []
    for p in range(1, max_paginas + 1):
        html_ = comum.get(base if p == 1 else f'{base}?pagina={p}')
        if not html_:
            break
        for url, titulo, pub, desc in comum.itens_lista(html_):
            item = {'titulo': titulo, 'url': url, 'publicadoEm': pub}
            item.update(_detalhe_chamamento(url))
            out.append(item)
        if p >= comum.total_paginas(html_):
            break
    return out


def processos_seletivos():
    html_ = comum.get(f'{SITE}/transparencia/processos-seletivos') or ''
    return [{'titulo': t, 'url': u, 'publicadoEm': pub, 'resumo': d[:300]} for u, t, pub, d in comum.itens_lista(html_)]


def coletar():
    from datetime import date
    comum.log('chamamentos'); ch = chamamentos()
    comum.log('processos seletivos'); ps = processos_seletivos()
    return {
        'fontes': {'chamamentos': f'{SITE}/transparencia/chamamentos-publicos',
                   'processosSeletivos': f'{SITE}/transparencia/processos-seletivos'},
        'licitacoesUrl': LICITACOES_URL.format(ano=date.today().year),
        'chamamentos': ch,
        'processosSeletivos': ps,
    }
