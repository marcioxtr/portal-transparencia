"""Indicadores: série histórica, mandatos, LRF (pessoal), mínimos constitucionais,
comparação com vizinhos e "o que mudou".

Fontes: dados/{ano}.json (já agregados do TCE-SP + SICONFI), SICONFI RGF/RREO,
TCE-SP (vizinhos, com cache em dados/vizinhos-cache/).

Saída (dados/indicadores.json):
{
  "anos": [ {ano, parcial, meses, receita, empenhado, pago, populacao,
             receitaPorHabitante, pagoPorHabitante, funcoesTop: [{codigo,nome,valor,percentual}],
             fornecedoresTop: [{nome,empenhado}], receitas: {iptu: v, fpm: v, ...}} ],
  "mandatos": [ {periodo:"2021-2024", anos:[...], prefeito|null, receita, pago,
                 receitaPorHabitanteMedia, pagoPorHabitanteMedia, completo} ],
  "lrf": [ {ano, periodo, pessoalPercentual, limiteMaximo, limitePrudencial, limiteAlerta, rcl, dtp} ],
  "minimos": [ {ano, periodo, educacaoPercentual|null, saudePercentual|null, minimoEducacao, minimoSaude,
                aproximacao: {educacaoShare, saudeShare}} ],
  "vizinhos": {ano, municipios: [{slug, nome, codIbge, populacao, receita, pago, receitaPorHabitante, pagoPorHabitante, eSjbv}]},
  "mudancas": [ {tipo, titulo, descricao, variacao, de, para, valorAntes, valorDepois} ],
  "avisos": [ "..." ]
}
"""
import json
import re
import urllib.parse
from datetime import date
from pathlib import Path

from . import comum

SICONFI = 'https://apidatalake.tesouro.gov.br/ords/siconfi/tt'
TCE = 'https://transparencia.tce.sp.gov.br/api/json'
COD_IBGE = 3549102
SJBV = 'sao-joao-da-boa-vista'

MANDATOS = [('2013-2016', 2013, 2016), ('2017-2020', 2017, 2020), ('2021-2024', 2021, 2024), ('2025-2028', 2025, 2028)]

VIZINHOS = [  # (slug TCE, nome, cod IBGE) — confirmados em 2026-11-09 via SICONFI /entes
    (SJBV, 'São João da Boa Vista', 3549102),
    ('aguai', 'Aguaí', 3500303),
    ('aguas-da-prata', 'Águas da Prata', 3500402),
    ('vargem-grande-do-sul', 'Vargem Grande do Sul', 3556404),
    ('espirito-santo-do-pinhal', 'Espírito Santo do Pinhal', 3515186),
    ('mogi-guacu', 'Mogi Guaçu', 3530706),
    ('sao-jose-do-rio-pardo', 'São José do Rio Pardo', 3549706),
]

LIM_MAX, LIM_PRUD, LIM_ALERTA = 54.0, 51.3, 48.6


def br(v):
    return float(str(v).replace('.', '').replace(',', '.')) if v else 0.0


def carregar_ano(ano):
    p = comum.RAIZ / f'{ano}.json'
    return json.loads(p.read_text(encoding='utf-8')) if p.exists() else None


def ler_prefeitos():
    """Nomes de prefeitos por mandato vêm de dados/camara.json (gestoes), se existir."""
    p = comum.RAIZ / 'camara.json'
    if not p.exists():
        return {}
    try:
        g = json.loads(p.read_text(encoding='utf-8')).get('gestoes') or []
        out = {}
        for x in g:
            per = x.get('periodo') or f"{x.get('inicio')}-{x.get('fim')}"
            if x.get('prefeito'):
                out[per] = x['prefeito']
        return out
    except Exception:  # noqa: BLE001
        return {}


# ── série por ano ──────────────────────────────────────────────────────────

def serie_anos(hoje):
    anos = []
    for ano in range(2014, hoje.year + 1):
        d = carregar_ano(ano)
        if not d:
            continue
        pop = d.get('populacao')
        rec = d['receitas']['total']
        emp = d['despesas']['total'].get('empenhado', 0)
        pago = d['despesas']['total'].get('pago', 0)
        funcoes = sorted([f for f in d['despesas'].get('porFuncao', []) if f.get('empenhado')], key=lambda f: -f['empenhado'])
        tot_f = sum(f['empenhado'] for f in funcoes) or 1
        anos.append({
            'ano': ano,
            'parcial': len(d.get('mesesDisponiveis', [])) < 12,
            'meses': len(d.get('mesesDisponiveis', [])),
            'receita': rec, 'empenhado': emp, 'pago': pago, 'populacao': pop,
            'receitaPorHabitante': round(rec / pop, 2) if pop else None,
            'pagoPorHabitante': round(pago / pop, 2) if pop else None,
            'funcoesTop': [{'codigo': f['codigo'], 'nome': f['nome'], 'valor': f['empenhado'],
                            'percentual': round(f['empenhado'] / tot_f * 100, 1)} for f in funcoes[:3]],
            'fornecedoresTop': [{'nome': f['nome'], 'empenhado': f['empenhado']}
                                for f in d['despesas']['topFornecedores'] if not f.get('interno')][:5],
            'receitas': {c['id']: c['valor'] for c in d['receitas']['porCategoria']},
            'funcoes': {f['codigo']: f['empenhado'] for f in funcoes},
        })
    return anos


def mandatos(anos, prefeitos):
    por_ano = {a['ano']: a for a in anos}
    out = []
    for per, ini, fim in MANDATOS:
        disp = [por_ano[a] for a in range(ini, fim + 1) if a in por_ano]
        if not disp:
            continue
        rec = sum(a['receita'] for a in disp)
        pago = sum(a['pago'] for a in disp)
        rph = [a['receitaPorHabitante'] for a in disp if a['receitaPorHabitante']]
        pph = [a['pagoPorHabitante'] for a in disp if a['pagoPorHabitante']]
        out.append({
            'periodo': per, 'inicio': ini, 'fim': fim,
            'anos': [a['ano'] for a in disp],
            'prefeito': prefeitos.get(per),
            'receita': round(rec, 2), 'pago': round(pago, 2),
            'receitaPorHabitanteMedia': round(sum(rph) / len(rph), 2) if rph else None,
            'pagoPorHabitanteMedia': round(sum(pph) / len(pph), 2) if pph else None,
            'completo': len(disp) == 4 and not any(a['parcial'] for a in disp),
        })
    return out


# ── SICONFI ────────────────────────────────────────────────────────────────

def _siconfi(recurso, **params):
    q = urllib.parse.urlencode(params)
    d = comum.get_json(f'{SICONFI}/{recurso}?{q}', timeout=120)
    return (d or {}).get('items') or []


def lrf(hoje):
    """RGF Anexo 01 (Poder Executivo), 3º quadrimestre; para o ano corrente, o último publicado."""
    out = []
    for ano in range(2014, hoje.year + 1):
        for periodo in (3, 2, 1):
            itens = _siconfi('rgf', an_exercicio=ano, in_periodicidade='Q', nr_periodo=periodo,
                             co_tipo_demonstrativo='RGF', no_anexo='RGF-Anexo 01', co_esfera='M', co_poder='E', id_ente=COD_IBGE)
            if not itens:
                continue
            reg = {'ano': ano, 'periodo': f'{periodo}º quadrimestre', 'limiteMaximo': LIM_MAX,
                   'limitePrudencial': LIM_PRUD, 'limiteAlerta': LIM_ALERTA, 'pessoalPercentual': None, 'rcl': None, 'dtp': None}
            for it in itens:
                conta, col, val = it.get('conta', ''), it.get('coluna', ''), it.get('valor')
                if conta.startswith('DESPESA TOTAL COM PESSOAL - DTP'):
                    if col.startswith('% sobre a RCL'):
                        reg['pessoalPercentual'] = round(float(val), 2)
                    elif col == 'Valor':
                        reg['dtp'] = round(float(val), 2)
                elif conta.startswith('RECEITA CORRENTE LIQUIDA - RCL') or conta.startswith('RECEITA CORRENTE LÍQUIDA - RCL'):
                    if col == 'Valor':
                        reg['rcl'] = round(float(val), 2)
                elif conta.startswith('LIMITE MÁXIMO') and col.startswith('% sobre a RCL'):
                    reg['limiteMaximo'] = round(float(val), 2)
                elif conta.startswith('LIMITE PRUDENCIAL') and col.startswith('% sobre a RCL'):
                    reg['limitePrudencial'] = round(float(val), 2)
                elif conta.startswith('LIMITE DE ALERTA') and col.startswith('% sobre a RCL'):
                    reg['limiteAlerta'] = round(float(val), 2)
            if reg['pessoalPercentual'] is None and reg['dtp'] and reg['rcl']:
                reg['pessoalPercentual'] = round(reg['dtp'] / reg['rcl'] * 100, 2)
            out.append(reg)
            break
    return out


def _percentual_anexo(itens, padrao):
    for it in itens:
        if re.search(padrao, it.get('conta', ''), re.I) and ('%' in it.get('coluna', '') or re.search(r'percentual|aplicado', it.get('coluna', ''), re.I)):
            try:
                return round(float(it.get('valor')), 2), it['conta'], it['coluna']
            except (TypeError, ValueError):
                pass
    return None, None, None


def minimos(anos, hoje, avisos):
    """Educação (≥25%) e Saúde (≥15%): RREO Anexos 08 e 12 quando o município os
    publica no SICONFI; senão, aproximação pela fatia das funções 12 e 10 na despesa total."""
    out = []
    faltou = []
    for a in anos:
        ano = a['ano']
        reg = {'ano': ano, 'periodo': None, 'educacaoPercentual': None, 'saudePercentual': None,
               'minimoEducacao': 25.0, 'minimoSaude': 15.0, 'fonte': None, 'aproximacao': None}
        for periodo in (6, 5, 4, 3, 2, 1):
            e = _siconfi('rreo', an_exercicio=ano, nr_periodo=periodo, co_tipo_demonstrativo='RREO', no_anexo='RREO-Anexo 08', id_ente=COD_IBGE)
            s = _siconfi('rreo', an_exercicio=ano, nr_periodo=periodo, co_tipo_demonstrativo='RREO', no_anexo='RREO-Anexo 12', id_ente=COD_IBGE)
            if not e and not s:
                if periodo == 1:
                    break
                continue
            ev, ec, ecol = _percentual_anexo(e, r'm[ií]nimo.*25|25%|aplica')
            sv, sc, scol = _percentual_anexo(s, r'm[ií]nimo.*15|15%|aplica')
            reg.update({'periodo': f'{periodo}º bimestre', 'educacaoPercentual': ev, 'saudePercentual': sv,
                        'fonte': f'SICONFI RREO {ano} ({ec or "-"} / {sc or "-"})'})
            break
        tot = sum(a['funcoes'].values()) or 0
        if tot:
            reg['aproximacao'] = {
                'educacaoShare': round(a['funcoes'].get('12', 0) / tot * 100, 1),
                'saudeShare': round(a['funcoes'].get('10', 0) / tot * 100, 1),
                'nota': 'fatia da despesa empenhada total por função (não é a base legal de impostos e transferências)',
            }
        if reg['educacaoPercentual'] is None and reg['saudePercentual'] is None:
            faltou.append(ano)
        out.append(reg)
    if faltou:
        avisos.append('Os anexos 08 (educação) e 12 (saúde) do RREO não constam no SICONFI para São João da Boa Vista '
                      f'({faltou[0]}–{faltou[-1]}); municípios paulistas prestam esses índices ao TCE-SP via AUDESP. '
                      'O app mostra a fatia da despesa por função como aproximação, claramente rotulada.')
    return out


# ── vizinhos (TCE-SP) ──────────────────────────────────────────────────────

def _populacao(cod_ibge, ano):
    for periodo in (6, 5, 4, 3, 2, 1):
        it = _siconfi('rreo', an_exercicio=ano, nr_periodo=periodo, co_tipo_demonstrativo='RREO', no_anexo='RREO-Anexo 01', id_ente=cod_ibge)
        if it:
            return it[0].get('populacao')
    return None


def vizinhos(hoje, avisos):
    ano = hoje.year - 1
    cache_dir = comum.RAIZ / 'vizinhos-cache'
    cache_dir.mkdir(exist_ok=True)
    municipios = []
    for slug, nome, cod in VIZINHOS:
        cache = cache_dir / f'{slug}-{ano}.json'
        if cache.exists():
            reg = json.loads(cache.read_text(encoding='utf-8'))
        else:
            if slug == SJBV and carregar_ano(ano):
                d = carregar_ano(ano)
                reg = {'receita': d['receitas']['total'], 'pago': d['despesas']['total'].get('pago', 0), 'populacao': d.get('populacao')}
            else:
                comum.log(f'  vizinho {nome} {ano}: 24 chamadas ao TCE-SP')
                rec = pago = 0.0
                ok = True
                for mes in range(1, 13):
                    r = comum.get_json(f'{TCE}/receitas/{slug}/{ano}/{mes}', timeout=180, pausa=0.6)
                    d = comum.get_json(f'{TCE}/despesas/{slug}/{ano}/{mes}', timeout=180, pausa=0.6)
                    if r is None or d is None:
                        ok = False
                        break
                    rec += sum(br(x.get('vl_arrecadacao')) for x in r)
                    pago += sum(br(x.get('vl_despesa')) for x in d if x.get('evento') == 'Valor Pago')
                if not ok:
                    avisos.append(f'TCE-SP indisponível para {nome} em {ano}; município omitido nesta rodada.')
                    continue
                reg = {'receita': round(rec, 2), 'pago': round(pago, 2), 'populacao': _populacao(cod, ano)}
            cache.write_text(json.dumps(reg), encoding='utf-8')
        pop = reg.get('populacao')
        municipios.append({
            'slug': slug, 'nome': nome, 'codIbge': cod, 'populacao': pop,
            'receita': reg['receita'], 'pago': reg['pago'],
            'receitaPorHabitante': round(reg['receita'] / pop, 2) if pop else None,
            'pagoPorHabitante': round(reg['pago'] / pop, 2) if pop else None,
            'eSjbv': slug == SJBV,
        })
    return {'ano': ano, 'municipios': municipios}


# ── o que mudou ────────────────────────────────────────────────────────────

def _var(a, b):
    return round((b - a) / a * 100, 1) if a else None


def _comparar(antes, depois, rotulo_antes, rotulo_depois, categorias_nome, funcoes_nome):
    m = []
    ra, rd = antes['receitas'], depois['receitas']
    for cid in set(ra) | set(rd):
        va, vd = ra.get(cid, 0), rd.get(cid, 0)
        nome = categorias_nome.get(cid, cid)
        if va < 1000 and vd >= 50000:
            m.append({'tipo': 'receita_nova', 'titulo': f'Nova fonte de receita: {nome}', 'descricao': f'Não existia em {rotulo_antes} e arrecadou em {rotulo_depois}.',
                      'variacao': None, 'de': rotulo_antes, 'para': rotulo_depois, 'valorAntes': va, 'valorDepois': vd})
        elif vd < 1000 and va >= 50000:
            m.append({'tipo': 'receita_sumiu', 'titulo': f'Receita que deixou de existir: {nome}', 'descricao': f'Arrecadava em {rotulo_antes} e zerou em {rotulo_depois}.',
                      'variacao': -100.0, 'de': rotulo_antes, 'para': rotulo_depois, 'valorAntes': va, 'valorDepois': vd})
    tops = sorted(rd.items(), key=lambda kv: -kv[1])[:8]
    for cid, vd in tops:
        va = ra.get(cid, 0)
        v = _var(va, vd)
        if v is not None and abs(v) >= 15:
            nome = categorias_nome.get(cid, cid)
            m.append({'tipo': 'receita_variou', 'titulo': f'{nome}: {"+" if v > 0 else ""}{v}%', 'descricao': f'{rotulo_antes} → {rotulo_depois}.',
                      'variacao': v, 'de': rotulo_antes, 'para': rotulo_depois, 'valorAntes': va, 'valorDepois': vd})
    fa = {f['nome'] for f in antes['fornecedoresTop']}
    for f in depois['fornecedoresTop']:
        if f['nome'] not in fa:
            m.append({'tipo': 'fornecedor_novo', 'titulo': f'Novo entre os maiores fornecedores: {f["nome"].title()}', 'descricao': f'Não estava entre os 5 maiores em {rotulo_antes}.',
                      'variacao': None, 'de': rotulo_antes, 'para': rotulo_depois, 'valorAntes': 0, 'valorDepois': f['empenhado']})
    fd = {f['nome'] for f in depois['fornecedoresTop']}
    for f in antes['fornecedoresTop']:
        if f['nome'] not in fd:
            m.append({'tipo': 'fornecedor_saiu', 'titulo': f'Saiu dos maiores fornecedores: {f["nome"].title()}', 'descricao': f'Estava entre os 5 maiores em {rotulo_antes}.',
                      'variacao': None, 'de': rotulo_antes, 'para': rotulo_depois, 'valorAntes': f['empenhado'], 'valorDepois': 0})
    fun_a, fun_d = antes['funcoes'], depois['funcoes']
    vars_ = []
    for cod in set(fun_a) | set(fun_d):
        va, vd = fun_a.get(cod, 0), fun_d.get(cod, 0)
        if max(va, vd) < 1_000_000:
            continue
        v = _var(va, vd)
        if v is not None:
            vars_.append((v, cod, va, vd))
    vars_.sort(key=lambda t: -abs(t[0]))
    for v, cod, va, vd in vars_[:4]:
        nome = funcoes_nome.get(cod, cod)
        m.append({'tipo': 'area_cresceu' if v > 0 else 'area_caiu', 'titulo': f'{nome}: {"+" if v > 0 else ""}{v}%', 'descricao': f'Despesa empenhada em {rotulo_antes} → {rotulo_depois}.',
                  'variacao': v, 'de': rotulo_antes, 'para': rotulo_depois, 'valorAntes': va, 'valorDepois': vd})
    return m


def mudancas(anos, hoje):
    por_ano = {a['ano']: a for a in anos}
    nomes_cat, nomes_fun = {}, {}
    for ano in por_ano:
        d = carregar_ano(ano)
        for c in d['receitas']['porCategoria']:
            nomes_cat[c['id']] = c['nome']
        for f in d['despesas'].get('porFuncao', []):
            nomes_fun[f['codigo']] = f['nome']
    out = []
    y = hoje.year
    if y - 1 in por_ano and y - 2 in por_ano:
        out += _comparar(por_ano[y - 2], por_ano[y - 1], str(y - 2), str(y - 1), nomes_cat, nomes_fun)
    # ano corrente (parcial) vs anterior no mesmo número de meses
    if y in por_ano and y - 1 in por_ano and por_ano[y]['parcial']:
        meses = por_ano[y]['meses']
        d_ant, d_atu = carregar_ano(y - 1), carregar_ano(y)

        def recorte(d):
            rec = {}
            for m in d['receitas']['porMes']:
                if m['mes'] <= meses:
                    for k, v in m.get('categorias', {}).items():
                        rec[k] = rec.get(k, 0) + v
            return rec
        antes = dict(por_ano[y - 1]); antes['receitas'] = recorte(d_ant); antes['funcoes'] = {}
        depois = dict(por_ano[y]); depois['receitas'] = recorte(d_atu); depois['funcoes'] = {}
        out += _comparar(antes, depois, f'{y - 1} (até mês {meses})', f'{y} (até mês {meses})', nomes_cat, nomes_fun)
    return out


def coletar():
    hoje = date.today()
    avisos = []
    anos = serie_anos(hoje)
    comum.log(f'  {len(anos)} anos; LRF…')
    dados_lrf = lrf(hoje)
    comum.log('  mínimos…')
    dados_min = minimos(anos, hoje, avisos)
    comum.log('  vizinhos…')
    viz = vizinhos(hoje, avisos)
    comum.log('  mudanças…')
    mud = mudancas(anos, hoje)
    for a in anos:  # campos auxiliares não vão para o JSON final
        a.pop('funcoes', None)
    return {
        'fontes': {
            'serie': 'TCE-SP + SICONFI via dados/{ano}.json',
            'lrf': 'SICONFI RGF Anexo 01 (Executivo) — conta "DESPESA TOTAL COM PESSOAL - DTP", coluna "% sobre a RCL Ajustada"',
            'minimos': 'SICONFI RREO Anexos 08 e 12 quando disponíveis; aproximação por função (DCA/RREO Anexo 02)',
            'vizinhos': 'TCE-SP receitas/despesas mensais; população SICONFI',
        },
        'anos': anos,
        'mandatos': mandatos(anos, ler_prefeitos()),
        'lrf': dados_lrf,
        'minimos': dados_min,
        'vizinhos': viz,
        'mudancas': mud,
        'avisos': avisos,
    }
