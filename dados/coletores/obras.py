"""Obras públicas do site da Prefeitura (https://www.saojoao.sp.gov.br/obras).

Saída (dados/obras.json):
{
  "fonte": "https://www.saojoao.sp.gov.br/obras",
  "total": 35, "porSituacao": {"Em andamento": 7, "Concluído": 26, ...},
  "valorTotalContratos": 0.0, "valorTotalExecutado": 0.0,
  "filtros": {"secretarias": [{"valor": "40", "nome": "Departamento de Esportes"}], "situacoes": [...]},
  "obras": [{
    "slug", "titulo", "url", "secretaria", "responsavelTecnico", "situacao",
    "dataInicio", "dataTerminoPrevista" (ISO), "endereco", "bairro", "empresa",
    "cpfCnpj", "valorContrato", "valorExecutado", "percentualExecucao",
    "lat", "lng", "fotos": [url]
  }]
}
Ordem: em andamento → suspenso → em projeto → concluído; dentro, data de início mais recente primeiro.
"""
import re
import urllib.parse

from . import comum

LISTA = f'{comum.SITE}/obras'
ORDEM_SITUACAO = {'Em andamento': 0, 'Suspenso': 1, 'Em projeto': 2, 'Concluído': 3}


def _opcoes(html_, nome):
    sel = re.search(rf'<select[^>]*name="{nome}"[^>]*>(.*?)</select>', html_, re.S)
    if not sel:
        return []
    out = []
    for valor, rotulo in re.findall(r'<option value="([^"]*)"[^>]*>(.*?)</option>', sel.group(1), re.S):
        if valor.strip():
            out.append({'valor': valor.strip(), 'nome': comum.texto(rotulo)})
    return out


def _campos_b(html_):
    """Pares <b>Rótulo:</b> valor dentro de <li> (markup próprio das obras)."""
    out = {}
    for li in re.findall(r'<li>(.*?)</li>', comum.conteudo(html_), re.S):
        m = re.search(r'<b>\s*(.*?)\s*:?\s*</b>(.*)', li, re.S)
        if not m:
            continue
        chave = comum.chave(m.group(1))
        valor = comum.texto(m.group(2))
        out[chave] = valor
    return out


def _detalhe(url):
    html_ = comum.get(url)
    if not html_:
        return None
    c = _campos_b(html_)
    t = re.search(r'<h1[^>]*>(.*?)</h1>', comum.conteudo(html_), re.S)
    coord = re.search(r"setView\(\[\s*(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)\s*\]", html_)
    sit = re.search(r'obra__detalhes-situacao[^"]*"[^>]*>(.*?)</span>', html_, re.S)
    pct = re.search(r'obra__detalhes-progresso__porcentagem[^>]*>(.*?)</span>', html_, re.S)
    fotos = sorted({
        urllib.parse.urljoin(url, src) for src in re.findall(r'<img[^>]+src="([^"]+)"', comum.conteudo(html_))
        if re.search(r'\.(jpe?g|png|webp)(\?|$)', src, re.I) and not re.search(r'fotonaodisponivel|/Arquitetura/|logo', src, re.I)
    })
    return {
        'slug': url.rstrip('/').split('/')[-1],
        'titulo': comum.texto(t.group(1)) if t else '',
        'url': url,
        'secretaria': c.get('secretaria_responsavel'),
        'responsavelTecnico': c.get('responsavel_tecnico'),
        'situacao': comum.texto(sit.group(1)) if sit else c.get('situacao'),
        'dataInicio': comum.data_iso(c.get('data_de_inicio')),
        'dataTerminoPrevista': comum.data_iso(c.get('data_de_termino_prevista')),
        'endereco': c.get('endereco'),
        'bairro': c.get('bairro'),
        'empresa': c.get('nome_razao_social') or c.get('razao_social'),
        'cpfCnpj': c.get('cpf_cnpj'),
        'valorContrato': comum.reais(c.get('valor_do_contrato')),
        'valorExecutado': comum.reais(c.get('valor_em_execucao_financeira')),
        'percentualExecucao': comum.percentual(pct.group(1) if pct else c.get('percentual_de_execucao_financeira')),
        'lat': float(coord.group(1)) if coord else None,
        'lng': float(coord.group(2)) if coord else None,
        'fotos': fotos,
    }


def coletar():
    primeira = comum.get(LISTA)
    if not primeira:
        raise RuntimeError('lista de obras indisponível')
    filtros = {
        'secretarias': _opcoes(primeira, 'idSecretaria'),
        'situacoes': _opcoes(primeira, 'idStatus'),
    }
    urls = []
    for pagina in range(1, comum.total_paginas(primeira) + 1):
        html_ = primeira if pagina == 1 else comum.get(f'{LISTA}?pagina={pagina}')
        for href in re.findall(r'href="(/obras/[^"?#]+)"', comum.conteudo(html_ or '')):
            u = urllib.parse.urljoin(comum.SITE, href)
            if u not in urls:
                urls.append(u)
    comum.log(f'{len(urls)} obras encontradas')

    obras = []
    for u in urls:
        d = _detalhe(u)
        if d:
            obras.append(d)

    # dentro de cada situação, data mais recente primeiro
    obras.sort(key=lambda o: (ORDEM_SITUACAO.get(o['situacao'] or '', 9), -(int((o['dataInicio'] or '0000-00-00').replace('-', '')) or 0)))

    por_sit = {}
    for o in obras:
        por_sit[o['situacao'] or 'Não informada'] = por_sit.get(o['situacao'] or 'Não informada', 0) + 1

    return {
        'fonte': LISTA,
        'total': len(obras),
        'porSituacao': por_sit,
        'valorTotalContratos': round(sum(o['valorContrato'] or 0 for o in obras), 2),
        'valorTotalExecutado': round(sum(o['valorExecutado'] or 0 for o in obras), 2),
        'filtros': filtros,
        'obras': obras,
    }
