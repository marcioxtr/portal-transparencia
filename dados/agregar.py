#!/usr/bin/env python3
"""Agrega dados oficiais de um exercício em um JSON compacto para o painel do app.

Fontes (ambas oficiais, públicas, sem autenticação):
  • TCE-SP  — https://transparencia.tce.sp.gov.br/api/json/{despesas|receitas}/{municipio}/{ano}/{mes}
              lançamento a lançamento (~2.400 despesas/mês). Pesado demais para o
              celular baixar; por isso agregamos aqui e publicamos o resultado.
  • SICONFI — https://apidatalake.tesouro.gov.br/ords/siconfi/tt/{dca|rreo}
              despesa por função (saúde, educação…) e população.

Uso:  python3 -I dados/agregar.py 2025            → dados/2025.json
      python3 -I dados/agregar.py 2025 --so-tce    (pula SICONFI)

Rodado diariamente pelo workflow .github/workflows/agregar-dados.yml.
"""
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from collections import defaultdict
from datetime import date, datetime, timezone
from pathlib import Path

MUNICIPIO = 'sao-joao-da-boa-vista'
COD_IBGE = 3549102
UA = 'TransparenciaSJBV-agregador/0.1 (+https://github.com/marcioxtr/portal-transparencia)'
TCE = 'https://transparencia.tce.sp.gov.br/api/json'
SICONFI = 'https://apidatalake.tesouro.gov.br/ords/siconfi/tt'
TOP_N = 40

FUNCOES = {
    '01': 'Legislativa', '02': 'Judiciária', '03': 'Essencial à Justiça', '04': 'Administração',
    '05': 'Defesa Nacional', '06': 'Segurança Pública', '07': 'Relações Exteriores',
    '08': 'Assistência Social', '09': 'Previdência Social', '10': 'Saúde', '11': 'Trabalho',
    '12': 'Educação', '13': 'Cultura', '14': 'Direitos da Cidadania', '15': 'Urbanismo',
    '16': 'Habitação', '17': 'Saneamento', '18': 'Gestão Ambiental', '19': 'Ciência e Tecnologia',
    '20': 'Agricultura', '21': 'Organização Agrária', '22': 'Indústria', '23': 'Comércio e Serviços',
    '24': 'Comunicações', '25': 'Energia', '26': 'Transporte', '27': 'Desporto e Lazer',
    '28': 'Encargos Especiais', '99': 'Reserva de Contingência',
}

# Categorias amigáveis de receita por prefixo do código da alínea (classificação
# nacional pós-2018, 8 dígitos). Ordem importa: o primeiro prefixo que casar vence.
CATEGORIAS_RECEITA = [
    ('iptu', 'IPTU', 'Imposto sobre imóveis urbanos — o carnê que chega em casa.', ['111250']),
    ('itbi', 'ITBI', 'Imposto pago quando um imóvel é vendido.', ['111253']),
    ('iss', 'ISS', 'Imposto sobre serviços prestados na cidade (de oficina a hospital).', ['111451']),
    ('irrf', 'IR retido na fonte', 'Imposto de renda descontado da folha dos próprios servidores, que fica com o município.', ['111303']),
    ('taxas', 'Taxas municipais', 'Cobranças por um serviço específico: coleta de lixo, licenças, alvarás, fiscalização.', ['1121', '1122']),
    ('cosip', 'Iluminação pública (COSIP)', 'Contribuição que vem na conta de luz para custear a iluminação das ruas.', ['124150']),
    ('multas_transito', 'Multas de trânsito', 'Arrecadação com infrações de trânsito — por lei, só pode ser gasta em trânsito.', ['19100', '19101', '19109']),
    ('fpm', 'FPM (União)', 'Fundo de Participação dos Municípios: fatia do IR e IPI federais repassada pela União.', ['171151']),
    ('icms', 'ICMS (Estado)', 'Fatia do ICMS estadual que volta para o município.', ['172150']),
    ('ipva', 'IPVA (Estado)', 'Metade do IPVA dos veículos da cidade volta para o município.', ['172151']),
    ('fundeb', 'FUNDEB', 'Fundo nacional da educação básica — só pode ser gasto em educação.', ['175150', '1751']),
    ('sus', 'SUS', 'Repasses federais e estaduais para a saúde.', ['171350', '172350', '1713', '1723']),
    ('salario_educacao', 'Salário-Educação', 'Contribuição federal destinada ao ensino fundamental.', ['171450', '1714']),
    ('convenios', 'Convênios e emendas', 'Transferências voluntárias da União e do Estado para obras e projetos específicos.', ['2414', '2424', '171', '172', '173', '175', '176', '177', '178', '17']),
    ('previdencia', 'Contribuições previdenciárias', 'Descontos de servidores e contribuição patronal para o instituto de previdência municipal.', ['1215', '1210', '72', '12']),
    ('financeiras', 'Rendimentos financeiros', 'Juros de aplicações do dinheiro em caixa.', ['13']),
    ('servicos', 'Serviços próprios', 'Receita por serviços prestados diretamente pela Prefeitura.', ['16']),
]


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def br(v):
    """'6.581,97' → 6581.97; '5830,00' → 5830.0"""
    if not v:
        return 0.0
    return float(str(v).replace('.', '').replace(',', '.'))


def get_json(url, tentativas=4):
    req = urllib.request.Request(url, headers={'User-Agent': UA, 'Accept': 'application/json'})
    for i in range(tentativas):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.load(r)
        except Exception as e:  # noqa: BLE001
            log(f'  tentativa {i + 1} falhou em {url}: {e}')
            time.sleep(3 * (i + 1))
    return None


def categoria_receita(codigo):
    for cid, nome, expl, prefixos in CATEGORIAS_RECEITA:
        if any(codigo.startswith(p) for p in prefixos):
            return cid
    return 'outras'


def agregar_tce(ano):
    hoje = date.today()
    ultimo_mes = 12 if ano < hoje.year else hoje.month
    desp_mes, rec_mes = [], []
    forn_emp, forn_pago, forn_id = defaultdict(float), defaultdict(float), {}
    forn_orgao = defaultdict(lambda: defaultdict(float))  # fornecedor → órgão → empenhado
    orgao_emp = defaultdict(float)
    cat_total, alinea_total = defaultdict(float), defaultdict(float)
    meses_ok = []

    for mes in range(1, ultimo_mes + 1):
        log(f'TCE {ano}/{mes:02d}')
        d = get_json(f'{TCE}/despesas/{MUNICIPIO}/{ano}/{mes}')
        r = get_json(f'{TCE}/receitas/{MUNICIPIO}/{ano}/{mes}')
        if not d and not r:
            continue
        meses_ok.append(mes)

        tot = defaultdict(float)
        for x in d or []:
            v = br(x.get('vl_despesa'))
            ev = x.get('evento', '')
            nome = (x.get('nm_fornecedor') or '').strip()
            if ev == 'Empenhado':
                tot['empenhado'] += v
                forn_emp[nome] += v
                orgao_emp[x.get('orgao', '')] += v
                forn_orgao[nome][x.get('orgao', '')] += v
                forn_id.setdefault(nome, x.get('id_fornecedor', ''))
            elif ev == 'Valor Liquidado':
                tot['liquidado'] += v
            elif ev == 'Valor Pago':
                tot['pago'] += v
                forn_pago[nome] += v
            elif ev == 'Anulação':
                tot['anulado'] += v
        desp_mes.append({'mes': mes, **{k: round(v, 2) for k, v in tot.items()}})

        rtot, rcat = 0.0, defaultdict(float)
        for x in r or []:
            v = br(x.get('vl_arrecadacao'))
            alinea = (x.get('ds_alinea') or '').strip()
            cod = alinea.split(' - ')[0].strip()
            cid = categoria_receita(cod)
            rtot += v
            rcat[cid] += v
            cat_total[cid] += v
            alinea_total[alinea] += v
        rec_mes.append({'mes': mes, 'total': round(rtot, 2),
                        'categorias': {k: round(v, 2) for k, v in rcat.items()}})

    top = sorted(forn_emp.items(), key=lambda kv: kv[1], reverse=True)[:TOP_N]
    fornecedores = [{
        'nome': n, 'id': forn_id.get(n, ''),
        'orgao': max(forn_orgao[n].items(), key=lambda kv: kv[1])[0] if forn_orgao.get(n) else '',
        'empenhado': round(v, 2), 'pago': round(forn_pago.get(n, 0.0), 2),
        'interno': bool(re.search(r'PREFEITURA MUNICIPAL|INST.*PREV|C[ÂA]MARA MUNICIPAL|FOLHA DE PAGAMENTO', n, re.I)),
    } for n, v in top]

    categorias = []
    for cid, nome, expl, _ in CATEGORIAS_RECEITA + [('outras', 'Outras receitas', 'Tudo o que não se encaixa nas categorias acima.', [])]:
        if cat_total.get(cid):
            categorias.append({'id': cid, 'nome': nome, 'explicacao': expl, 'valor': round(cat_total[cid], 2)})
    categorias.sort(key=lambda c: c['valor'], reverse=True)

    return {
        'mesesDisponiveis': meses_ok,
        'despesas': {
            'porMes': desp_mes,
            'total': {k: round(sum(m.get(k, 0) for m in desp_mes), 2) for k in ('empenhado', 'liquidado', 'pago', 'anulado')},
            'topFornecedores': fornecedores,
            'porOrgao': [{'orgao': o, 'empenhado': round(v, 2)} for o, v in sorted(orgao_emp.items(), key=lambda kv: kv[1], reverse=True)],
        },
        'receitas': {
            'porMes': rec_mes,
            'total': round(sum(m['total'] for m in rec_mes), 2),
            'porCategoria': categorias,
            'topAlineas': [{'alinea': a, 'valor': round(v, 2)} for a, v in sorted(alinea_total.items(), key=lambda kv: kv[1], reverse=True)[:25]],
        },
    }


def agregar_siconfi(ano):
    """Despesa por função. Tenta a DCA (anual, consolidada); se não houver (ano em
    curso), usa o RREO Anexo 02 do último bimestre publicado."""
    out = {'porFuncao': [], 'populacao': None, 'fonte': None}

    q = urllib.parse.urlencode({'an_exercicio': ano, 'no_anexo': 'DCA-Anexo I-E', 'id_ente': COD_IBGE})
    log(f'SICONFI DCA {ano}')
    dca = get_json(f'{SICONFI}/dca?{q}')
    itens = (dca or {}).get('items') or []
    if itens:
        por = defaultdict(dict)
        for it in itens:
            m = re.match(r'^(\d{2}) - (.+)$', it.get('conta', ''))
            if not m:
                continue
            col = it.get('coluna', '')
            chave = {'Despesas Empenhadas': 'empenhado', 'Despesas Liquidadas': 'liquidado', 'Despesas Pagas': 'pago'}.get(col)
            if chave:
                por[m.group(1)][chave] = round(float(it.get('valor') or 0), 2)
            out['populacao'] = it.get('populacao') or out['populacao']
        out['porFuncao'] = [{'codigo': c, 'nome': FUNCOES.get(c, c), **v} for c, v in sorted(por.items())]
        out['fonte'] = f'SICONFI DCA {ano} (Anexo I-E)'
        return out

    nomes = {v: k for k, v in FUNCOES.items()}
    for periodo in range(6, 0, -1):
        q = urllib.parse.urlencode({'an_exercicio': ano, 'nr_periodo': periodo, 'co_tipo_demonstrativo': 'RREO',
                                    'no_anexo': 'RREO-Anexo 02', 'id_ente': COD_IBGE})
        log(f'SICONFI RREO {ano} bimestre {periodo}')
        rreo = get_json(f'{SICONFI}/rreo?{q}')
        itens = (rreo or {}).get('items') or []
        if not itens:
            continue
        por = defaultdict(dict)
        for it in itens:
            if it.get('rotulo') != 'Total das Despesas Exceto Intra-Orçamentárias':
                continue
            cod = nomes.get(it.get('conta', ''))
            if not cod:
                continue
            col = it.get('coluna', '').upper()
            if 'EMPENHADAS' in col and 'ATÉ' in col:
                por[cod]['empenhado'] = round(float(it.get('valor') or 0), 2)
            elif 'LIQUIDADAS' in col and 'ATÉ' in col:
                por[cod]['liquidado'] = round(float(it.get('valor') or 0), 2)
            elif col.startswith('DOTAÇÃO ATUALIZADA'):
                por[cod]['dotacao'] = round(float(it.get('valor') or 0), 2)
            out['populacao'] = it.get('populacao') or out['populacao']
        out['porFuncao'] = [{'codigo': c, 'nome': FUNCOES.get(c, c), **v} for c, v in sorted(por.items())]
        out['fonte'] = f'SICONFI RREO {ano}, {periodo}º bimestre (Anexo 02)'
        return out
    return out


def main():
    if len(sys.argv) < 2:
        log(__doc__)
        sys.exit(2)
    ano = int(sys.argv[1])
    so_tce = '--so-tce' in sys.argv
    saida = Path(__file__).resolve().parent / f'{ano}.json'

    dados = {
        'municipio': MUNICIPIO, 'codIbge': COD_IBGE, 'ano': ano,
        'geradoEm': datetime.now(timezone.utc).isoformat(timespec='seconds'),
        'fontes': {
            'tce': f'{TCE}/{{despesas|receitas}}/{MUNICIPIO}/{ano}/{{mes}}',
            'siconfi': None,
        },
    }
    dados.update(agregar_tce(ano))
    if not so_tce:
        s = agregar_siconfi(ano)
        dados['despesas']['porFuncao'] = s['porFuncao']
        dados['populacao'] = s['populacao']
        dados['fontes']['siconfi'] = s['fonte']

    saida.write_text(json.dumps(dados, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    log(f'ok → {saida} ({saida.stat().st_size // 1024} KB)')


if __name__ == '__main__':
    main()
