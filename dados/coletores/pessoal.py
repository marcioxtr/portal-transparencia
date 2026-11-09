"""Pessoal, salários e gabinetes — quanto ganham prefeito, vice, vereadores e
diretores; quanto a Câmara gasta e com quem; folha e quadro de pessoal.

Fontes (todas oficiais):
  • SAPL (Câmara)  — normas que fixam/revisam subsídios (ementa + PDF do texto)
  • Câmara (Plone) — Tabela de Cargos e Vencimentos, Relação de Cargos, Níveis Salariais (PDF)
  • Prefeitura/eCrie — Quadro de Pessoal mensal e Tabela Salarial (PDF)
  • TCE-SP via dados/{ano}.json — gasto por órgão, fornecedores por órgão, folha por mês
    (campos porOrgaoFornecedor/folhaPorOrgaoMes gerados por agregar.py)

Saída (dados/pessoal.json):
{
  "subsidios": {"prefeito": {...}, "vice": {...}, "vereador": {...}, "presidenteCamara": {...},
                "diretorDepartamento": {...}, "historico": [normas]},
  "camara": {"gastoAno": {ano: R$}, "folhaAno": {ano: R$}, "folhaPorMes": {ano: {mes: R$}},
             "topFornecedores": {ano: [...]}, "cargos": [...], "niveisSalariais": [...],
             "documentos": [...]},
  "prefeitura": {"folhaAno": {...}, "folhaPorMes": {...}, "topFornecedoresFolha": {ano: [...]},
                 "tabelaSalarial": [...], "diretores": [...], "quadroPessoal": {...}, "documentos": [...]},
  "avisos": [...]
}
Nomes de pessoas NÃO entram no JSON (ficam nos PDFs oficiais linkados); só cargos e valores.
"""
import json
import re
import tempfile
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

from . import comum

try:  # extração de PDF é opcional: sem ela o JSON traz só os links
    import pdfplumber  # type: ignore
except ImportError:  # pragma: no cover
    pdfplumber = None

CAMARA_TRANSP = 'https://www.saojoaodaboavista.sp.leg.br/transparencia/acesso-a-informacao'
ECRIE = 'https://ecrie.com.br/home/_arq/41/'
PASTA_QUADRO = 'rh/Despesas Mensal Com Funcionarios/Quadro de Pessoal'
# O file-browser eCrie só devolve a árvore para clientes "compatíveis com navegador";
# o UA continua identificando o projeto.
UA_ECRIE = 'Mozilla/5.0 (compatible; TransparenciaSJBV-coletor/0.2; +https://github.com/marcioxtr/portal-transparencia)'

RE_REMUN = re.compile(r'subs[ií]dio|remunera|vencimento|verba de gabinete|gratifica', re.I)
RE_REAIS = re.compile(r'R\$\s?([\d\.]+,\d{2})')


# ── util ───────────────────────────────────────────────────────────────────

def _get_ua(url, ua, timeout=120, binario=False):
    req = urllib.request.Request(url, headers={'User-Agent': ua, 'Accept': '*/*'})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            dados = r.read()
        return dados if binario else dados.decode('utf-8', 'ignore')
    except Exception as e:  # noqa: BLE001
        comum.log(f'  falhou {url}: {e}')
        return None


def _baixar_pdf(url, ua=comum.UA):
    dados = _get_ua(url, ua, binario=True)
    if not dados or not dados.startswith(b'%PDF'):
        return None
    f = tempfile.NamedTemporaryFile(suffix='.pdf', delete=False)
    f.write(dados)
    f.close()
    return Path(f.name)


def _tabelas(pdf_path):
    """Todas as linhas de todas as tabelas do PDF (lista de listas de str)."""
    linhas = []
    with pdfplumber.open(pdf_path) as pdf:
        for p in pdf.pages:
            for t in p.extract_tables() or []:
                for row in t:
                    linhas.append([(c or '').replace('\n', ' ').strip() for c in row])
    return linhas


def _texto(pdf_path, max_paginas=6):
    with pdfplumber.open(pdf_path) as pdf:
        return '\n'.join((p.extract_text() or '') for p in pdf.pages[:max_paginas])


def _reais(s):
    return comum.reais(s) if s else None


# ── 1. Subsídios (SAPL) ────────────────────────────────────────────────────

def _cargo_da_ementa(e):
    e = e.lower()
    cargos = []
    if 'prefeito' in e and 'vice' in e:
        cargos += ['prefeito', 'vice']
    elif 'prefeito' in e:
        cargos.append('prefeito')
    if 'vereador' in e:
        cargos.append('vereador')
    if 'presidente' in e and ('câmara' in e or 'camara' in e):
        cargos.append('presidenteCamara')
    if re.search(r'secret[áa]rio|diretor', e):
        cargos.append('diretorDepartamento')
    return cargos


def _valores_do_texto(pdf_url):
    """Lê o PDF da norma e devolve os valores em R$ com o contexto em que aparecem."""
    if not pdfplumber or not pdf_url:
        return []
    p = _baixar_pdf(pdf_url)
    if not p:
        return []
    try:
        txt = _texto(p)
    except Exception:  # noqa: BLE001
        return []
    finally:
        p.unlink(missing_ok=True)
    out = []
    for m in RE_REAIS.finditer(txt):
        ctx = txt[max(0, m.start() - 160):m.start()].lower()
        cargo = None
        if re.search(r'vice', ctx[-80:]):
            cargo = 'vice'
        elif 'prefeito' in ctx:
            cargo = 'prefeito'
        if re.search(r'presidente', ctx[-100:]):
            cargo = 'presidenteCamara'
        elif 'vereador' in ctx:
            cargo = cargo or 'vereador'
        out.append({'valor': _reais(m.group(1)), 'cargo': cargo})
    return out


def coletar_subsidios():
    comum.log('subsídios (SAPL normas 2008→hoje)')
    normas = []
    for ano in range(2008, date.today().year + 1):
        for r in comum.sapl_todos('norma/normajuridica', {'ano': ano}, max_paginas=10):
            ementa = comum.texto(r.get('ementa') or '')
            if not RE_REMUN.search(ementa):
                continue
            if re.search(r'concede licen[çc]a', ementa, re.I):  # licenças sem remuneração não interessam
                continue
            cargos = _cargo_da_ementa(ementa)
            if not cargos:
                continue
            vig = re.search(r'(20\d\d)\s*(?:a|à|-|e t[ée]rmino em 31 de dezembro de)\s*(?:2\.?)?(\d{3,4})', ementa, re.I)
            normas.append({
                'id': r['id'], 'tipo': r.get('tipo'), 'numero': r.get('numero'), 'ano': r.get('ano'),
                'data': r.get('data'), 'ementa': ementa, 'cargos': cargos,
                'textoUrl': r.get('texto_integral'),
                'saplUrl': f"https://sapl.saojoaodaboavista.sp.leg.br/norma/{r['id']}",
                'revogacao': bool(re.search(r'^revoga', ementa, re.I)),
            })
    normas.sort(key=lambda n: (n['data'] or ''), reverse=True)

    # Para a norma vigente de cada cargo (a mais recente que fixa/revisa, não revoga), lê o PDF.
    vigentes = {}
    for n in normas:
        if n['revogacao']:
            continue
        for c in n['cargos']:
            if c not in vigentes and re.search(r'fixa|revis[ãa]o|disp[õo]e', n['ementa'], re.I):
                vigentes[c] = n
    for c, n in vigentes.items():
        if 'valores' not in n:
            n['valores'] = _valores_do_texto(n['textoUrl'])
    return normas, vigentes


# ── 2. Câmara: PDFs de cargos/vencimentos ──────────────────────────────────

def coletar_camara_pdfs():
    comum.log('Câmara: página de transparência')
    html_ = comum.get(CAMARA_TRANSP)
    docs, cargos, niveis = [], [], []
    if not html_:
        return docs, cargos, niveis
    for href, titulo in re.findall(r'<a [^>]*href="([^"]+)"[^>]*>(.*?)</a>', html_, re.S):
        t = comum.texto(titulo)
        if re.search(r'\.pdf$', href, re.I) or re.search(r'despesas-com|balancetes|balanco|relatorio|concursos|licitacoes|contratos', href, re.I):
            if t and not re.search(r'^\d{4}$|^Todos$|^Demais$', t):
                docs.append({'titulo': t, 'url': urllib.parse.urljoin(CAMARA_TRANSP, href)})
    # dedup
    vistos, docs2 = set(), []
    for d in docs:
        if d['url'] not in vistos:
            vistos.add(d['url'])
            docs2.append(d)
    docs = docs2

    def acha(padrao):
        for d in docs:
            if re.search(padrao, d['url'] + ' ' + d['titulo'], re.I):
                return d
        return None

    tab = acha(r'TABELADECARGOS|Cargos e Sal')
    if tab and pdfplumber:
        p = _baixar_pdf(tab['url'])
        if p:
            try:
                categoria = ''
                for row in _tabelas(p):
                    cells = [c for c in row if c]
                    if len(cells) == 1 and re.search(r'^Cargos ', cells[0]):
                        categoria = cells[0]
                        continue
                    if len(row) >= 6 and row[0] and _reais(row[5]) is not None and not row[0].startswith('CARGO'):
                        cargos.append({
                            'cargo': row[0], 'referencia': row[2], 'providos': int(row[3] or 0), 'vagos': int(row[4] or 0),
                            'valorBase': _reais(row[5]), 'categoria': categoria,
                        })
                tab['referencia'] = _data_no_nome(tab['url'])
            except Exception as e:  # noqa: BLE001
                comum.log(f'  tabela de cargos: {e}')
            finally:
                p.unlink(missing_ok=True)

    niv = acha(r'NVELSALARIAL|N[íi]veis Salariais')
    if niv and pdfplumber:
        p = _baixar_pdf(niv['url'])
        if p:
            try:
                classe = ''
                for row in _tabelas(p):
                    if row and row[0]:
                        classe = row[0]
                    if len(row) >= 3 and row[1] and re.match(r'^(I|II|III|IV|V)$', row[1]):
                        refs = [_reais(c) for c in row[2:] if _reais(c) is not None]
                        if refs:
                            niveis.append({'classe': classe, 'nivel': row[1], 'inicial': refs[0], 'final': refs[-1], 'referencias': len(refs)})
            except Exception as e:  # noqa: BLE001
                comum.log(f'  níveis salariais: {e}')
            finally:
                p.unlink(missing_ok=True)
    return docs, cargos, niveis


def _data_no_nome(url):
    m = re.search(r'(\d{2})\.(\d{2})\.(\d{4})', url)
    return f'{m.group(3)}-{m.group(2)}-{m.group(1)}' if m else None


# ── 3. Prefeitura: Quadro de Pessoal e Tabela Salarial (eCrie) ─────────────

def _arquivos_ecrie(pasta):
    html_ = _get_ua(f'{ECRIE}Default.aspx?pasta={urllib.parse.quote(pasta)}', UA_ECRIE)
    if not html_:
        return []
    hrefs = sorted({h for h in re.findall(r'href="([^"]+\.pdf)" target="_blank"', html_, re.I)})
    return [{'url': ECRIE + h, 'nome': urllib.parse.unquote(h.split('/')[-1]), 'caminho': urllib.parse.unquote(h)} for h in hrefs]


def _mes_ano(nome):
    m = re.search(r'(\d{2})\.(\d{4})', nome)
    return (int(m.group(2)), int(m.group(1))) if m else (0, 0)


def coletar_prefeitura_pdfs():
    comum.log('Prefeitura: quadro de pessoal e tabela salarial (eCrie)')
    arquivos = _arquivos_ecrie(PASTA_QUADRO)
    quadros = sorted([a for a in arquivos if re.search(r'/\d{4}/\d{2}\.\d{4}\.pdf$', a['caminho'])], key=lambda a: _mes_ano(a['nome']))
    tabelas = sorted([a for a in arquivos if 'tabela salarial' in a['caminho'].lower()], key=lambda a: a['nome'])
    docs = [{'titulo': f"Quadro de Pessoal {a['nome'][:-4]}", **a} for a in quadros[-3:][::-1]]
    docs += [{'titulo': a['nome'][:-4], **a} for a in tabelas[-1:]]

    quadro, tabela, diretores = None, [], []
    if pdfplumber and quadros:
        ult = quadros[-1]
        p = _baixar_pdf(ult['url'], UA_ECRIE)
        if p:
            try:
                itens = []
                for row in _tabelas(p):
                    if len(row) >= 6 and row[0] and not row[0].startswith('DENOMINA') and re.match(r'^\d*$', row[3] or '') and (row[3] or row[4]):
                        def n(x):
                            return int(x) if (x or '').strip().isdigit() else 0
                        itens.append({'cargo': row[0], 'colunaA': n(row[1]), 'colunaB': n(row[2]), 'total': n(row[3]), 'providos': n(row[4]), 'vagos': n(row[5])})
                ano, mes = _mes_ano(ult['nome'])
                quadro = {
                    'referencia': f'{ano}-{mes:02d}', 'url': ult['url'], 'cargos': itens,
                    'totais': {k: sum(i[k] for i in itens) for k in ('colunaA', 'colunaB', 'total', 'providos', 'vagos')},
                    'notaColunas': 'Colunas A e B são as formas de provimento conforme o documento oficial (ver PDF para a legenda).',
                }
            except Exception as e:  # noqa: BLE001
                comum.log(f'  quadro de pessoal: {e}')
            finally:
                p.unlink(missing_ok=True)
    if pdfplumber and tabelas:
        ult = tabelas[-1]
        p = _baixar_pdf(ult['url'], UA_ECRIE)
        if p:
            try:
                for row in _tabelas(p):
                    if len(row) >= 4 and re.match(r'^\d+$', row[0] or '') and _reais(row[3]) is not None:
                        item = {'codigo': row[0], 'funcao': row[1], 'referencia': row[2], 'valorInicial': _reais(row[3])}
                        tabela.append(item)
                        if re.search(r'^DIRETOR|SECRET[ÁA]RIO|CHEFE DE GABINETE|ASSESSOR|PROCURADOR[- ]GERAL|CONTROLADOR', row[1] or '', re.I):
                            diretores.append(item)
            except Exception as e:  # noqa: BLE001
                comum.log(f'  tabela salarial: {e}')
            finally:
                p.unlink(missing_ok=True)
    return docs, quadro, tabela, diretores


# ── 4. TCE-SP por órgão (dados/{ano}.json) ─────────────────────────────────

def coletar_tce():
    camara = {'gastoAno': {}, 'folhaAno': {}, 'folhaPorMes': {}, 'topFornecedores': {}}
    pref = {'gastoAno': {}, 'folhaAno': {}, 'folhaPorMes': {}, 'topFornecedoresFolha': {}, 'topFornecedores': {}}
    for arq in sorted(comum.RAIZ.glob('20??.json')):
        try:
            d = json.loads(arq.read_text(encoding='utf-8'))
        except Exception:  # noqa: BLE001
            continue
        ano = str(d.get('ano'))
        desp = d.get('despesas', {})
        for o in desp.get('porOrgao', []):
            nome = o['orgao'].upper()
            if 'CÂMARA' in nome or 'CAMARA' in nome:
                camara['gastoAno'][ano] = o['empenhado']
            elif nome.startswith('PREFEITURA'):
                pref['gastoAno'][ano] = o['empenhado']
        for o, fs in (desp.get('porOrgaoFornecedor') or {}).items():
            nome = o.upper()
            lista = [{'nome': f['nome'], 'empenhado': f['empenhado'], 'folha': f['folha']} for f in fs]
            if 'CÂMARA' in nome or 'CAMARA' in nome:
                camara['topFornecedores'][ano] = lista
            elif nome.startswith('PREFEITURA'):
                pref['topFornecedores'][ano] = lista[:15]
                pref['topFornecedoresFolha'][ano] = [f for f in lista if f['folha']][:10]
        for o, ms in (desp.get('folhaPorOrgaoMes') or {}).items():
            nome = o.upper()
            alvo = camara if ('CÂMARA' in nome or 'CAMARA' in nome) else pref if nome.startswith('PREFEITURA') else None
            if alvo is not None:
                alvo['folhaPorMes'][ano] = ms
                alvo['folhaAno'][ano] = round(sum(ms.values()), 2)
    return camara, pref


# ── principal ──────────────────────────────────────────────────────────────

def coletar():
    avisos = []
    if not pdfplumber:
        avisos.append('pdfplumber indisponível: tabelas dos PDFs não foram extraídas (só links).')

    normas, vigentes = coletar_subsidios()
    docs_cam, cargos_cam, niveis_cam = coletar_camara_pdfs()
    docs_pref, quadro, tabela, diretores = coletar_prefeitura_pdfs()
    tce_cam, tce_pref = coletar_tce()

    def subsidio(cargo):
        n = vigentes.get(cargo)
        if not n:
            return None
        vals = [v for v in n.get('valores', []) if v['valor']]
        escolhido = next((v['valor'] for v in vals if v['cargo'] == cargo), None)
        # Lei conjunta prefeito+vice: o maior valor é do prefeito e o menor do vice.
        if escolhido is None and set(n['cargos']) >= {'prefeito', 'vice'} and len(vals) >= 2:
            ordenados = sorted({v['valor'] for v in vals}, reverse=True)
            escolhido = ordenados[0] if cargo == 'prefeito' else ordenados[1] if cargo == 'vice' else None
        return {
            'valor': escolhido, 'valoresNoTexto': [v['valor'] for v in vals][:6],
            'lei': f"{_tipo_nome(n['tipo'])} nº {n['numero']}/{n['ano']}", 'data': n['data'],
            'ementa': n['ementa'], 'textoUrl': n['textoUrl'], 'saplUrl': n['saplUrl'],
        }

    sub = {c: subsidio(c) for c in ('prefeito', 'vice', 'vereador', 'presidenteCamara')}
    # Valores correntes da Câmara vêm da Tabela de Cargos (documento oficial mais recente).
    for c in cargos_cam:
        if re.search(r'^Vereador', c['cargo'], re.I):
            sub['vereador'] = {**(sub.get('vereador') or {}), 'valor': c['valorBase'], 'fonteValor': 'Tabela de Cargos e Vencimentos da Câmara'}
        if re.search(r'^Presidente', c['cargo'], re.I):
            sub['presidenteCamara'] = {**(sub.get('presidenteCamara') or {}), 'valor': c['valorBase'], 'fonteValor': 'Tabela de Cargos e Vencimentos da Câmara'}
    if diretores:
        sub['diretorDepartamento'] = {
            'valor': max(d['valorInicial'] for d in diretores if d['funcao'].upper().startswith('DIRETOR')) if any(d['funcao'].upper().startswith('DIRETOR') for d in diretores) else diretores[0]['valorInicial'],
            'fonteValor': 'Tabela Salarial da Prefeitura (valor inicial do cargo de Diretor de Departamento)',
            'cargos': diretores,
        }
    if not cargos_cam:
        avisos.append('Tabela de Cargos da Câmara não extraída.')
    if not quadro:
        avisos.append('Quadro de Pessoal da Prefeitura não extraído.')
    avisos.append('A Prefeitura não publica "Relação de Cargos e Salários" no site (categoria vazia em 2026-11); usamos a Tabela Salarial do eCrie.')
    avisos.append('A Câmara passou a publicar despesas detalhadas em portal SmarAPD próprio a partir de 22/05/2026 (transparencia-cmsaojoaoboavista.smarapd.com.br); aqui usamos o TCE-SP.')

    return {
        'fontes': {
            'sapl': 'https://sapl.saojoaodaboavista.sp.leg.br/api/norma/normajuridica/',
            'camara': CAMARA_TRANSP,
            'prefeitura': f'{ECRIE}Default.aspx?pasta={urllib.parse.quote(PASTA_QUADRO)}',
            'tce': 'https://transparencia.tce.sp.gov.br/api/json/despesas/sao-joao-da-boa-vista/{ano}/{mes}',
        },
        'subsidios': {**sub, 'historico': normas[:60]},
        'camara': {**tce_cam, 'cargos': cargos_cam, 'niveisSalariais': niveis_cam, 'documentos': docs_cam},
        'prefeitura': {**tce_pref, 'tabelaSalarial': tabela, 'diretores': diretores, 'quadroPessoal': quadro, 'documentos': docs_pref},
        'avisos': avisos,
    }


def _tipo_nome(tipo_id):
    return {1: 'Lei', 2: 'Lei Complementar', 3: 'Decreto Legislativo', 4: 'Emenda à Lei Orgânica',
            5: 'Lei Orgânica', 6: 'Resolução', 7: 'Regimento Interno', 8: 'Decreto Lei', 9: 'Emenda Impositiva'}.get(tipo_id, 'Norma')
