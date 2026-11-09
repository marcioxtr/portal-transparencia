import json
"""Câmara Municipal — vereadores, mandatos, sessões, matérias, votos nominais e
leis, via API REST aberta do SAPL (sapl.saojoaodaboavista.sp.leg.br/api).

Saída (dados/camara.json):
  legislaturas: [{id, numero, inicio, fim, atual}]
  vereadores: [{id, nome, nomeCompleto, partido, foto, ativo,
                mandatos: [{legislatura, inicio, fim, titular, afastado}],
                estatisticas: {"<legislaturaId>": {total, porTipo: {SIGLA: n}, emendasImpositivas,
                               votos: {sim, nao, abstencao, naoVotou}, presencas, sessoes}},
                ultimasMaterias: [...]}]
  sessoes: {ultimas: [...], proximas: [...]}
  materiasRecentes: [...]
  leisRecentes: [...]; leisPorTipoAno: {"<ano>": {"<tipo>": n}}
  emendasImpositivas: [...]
  gestoes: [{inicio, fim, legislatura, prefeito|null, vereadores: [ids]}]
  avisos: [str]
Fonte da verdade: o SAPL. Nada aqui é digitado à mão.
"""
import re
from collections import Counter, defaultdict
from datetime import date

from . import comum
from .comum import SAPL, get_json, sapl_todos, log

ANO_MIN = 2013
TIPO_EMENDA_IMPOSITIVA = 9
URL_SAPL_PUBLICO = 'https://sapl.saojoaodaboavista.sp.leg.br'
URL_CAMARA = 'https://www.saojoaodaboavista.sp.leg.br'


def _voto(v):
    v = (v or '').strip().lower()
    if v.startswith('sim'):
        return 'sim'
    if v.startswith('n') and 'vot' not in v:
        return 'nao'
    if v.startswith('abst'):
        return 'abstencao'
    return 'naoVotou'


def _legislatura_de(data_iso, legislaturas):
    if not data_iso:
        return None
    for l in legislaturas:
        if l['inicio'] <= data_iso <= l['fim']:
            return l['id']
    return None


def https_sapl(obj):
    """O SAPL devolve URLs http://; o Android bloqueia conteúdo não-HTTPS (fotos, PDFs)."""
    return json.loads(json.dumps(obj, ensure_ascii=False).replace('http://sapl.', 'https://sapl.'))


from . import fotos as _fotos


def coletar():
    avisos = []

    # ── legislaturas, partidos, parlamentares, mandatos, filiações ──────────
    legs_raw = sapl_todos('parlamentares/legislatura')
    legislaturas = sorted([{
        'id': l['id'], 'numero': l['numero'], 'inicio': l['data_inicio'], 'fim': l['data_fim'],
        'atual': l['data_inicio'] <= date.today().isoformat() <= l['data_fim'],
    } for l in legs_raw if l['data_fim'] >= f'{ANO_MIN}-01-01'], key=lambda l: l['inicio'])
    leg_ids = {l['id'] for l in legislaturas}

    partidos = {p['id']: p['sigla'] for p in sapl_todos('parlamentares/partido')}
    parl_raw = {p['id']: p for p in sapl_todos('parlamentares/parlamentar')}
    mandatos = [m for m in sapl_todos('parlamentares/mandato') if m['legislatura'] in leg_ids]
    filiacoes = defaultdict(list)
    for f in sapl_todos('parlamentares/filiacao'):
        filiacoes[f['parlamentar']].append(f)
    autores_raw = sapl_todos('base/autor', {'ordering': 'id'})
    autores = {a['id']: a['object_id'] for a in autores_raw if a.get('content_type') == 26 and a.get('object_id')}
    autor_nome = {a['id']: a.get('nome', '') for a in autores_raw}
    autor_de_parl = defaultdict(list)
    for aid, pid in autores.items():
        autor_de_parl[pid].append(aid)
    log(f'legislaturas={len(legislaturas)} parlamentares={len(parl_raw)} mandatos={len(mandatos)} autores={len(autores)}')

    # ── tipos ───────────────────────────────────────────────────────────────
    tipos_materia = {t['id']: (t['sigla'], t['descricao']) for t in sapl_todos('materia/tipomaterialegislativa')}
    tipos_norma = {t['id']: (t['sigla'], t['descricao']) for t in sapl_todos('norma/tiponormajuridica')}
    tipos_sessao = {t['id']: t['nome'] for t in sapl_todos('sessao/tiposessaoplenaria')}
    resultados = {t['id']: t['nome'] for t in sapl_todos('sessao/tiporesultadovotacao')}

    # ── matérias (por ano, desde ANO_MIN) e autorias ────────────────────────
    materias = {}
    for ano in range(ANO_MIN, date.today().year + 1):
        for m in sapl_todos('materia/materialegislativa', {'ano': ano, 'ordering': 'id'}):
            materias[m['id']] = m
    log(f'materias={len(materias)}')
    # Autoria: o próprio objeto da matéria traz `autores` (ids de base/autor) —
    # completo e sem paginar os 28 mil registros de materia/autoria.
    autoria = defaultdict(list)  # materia → [parlamentar_id]
    autoria_nomes = defaultdict(list)  # materia → [nome do autor (inclui comissões/Executivo)]
    for mid, m in materias.items():
        for aid in m.get('autores') or []:
            pid = autores.get(aid)
            if pid:
                autoria[mid].append(pid)
            nome = autor_nome.get(aid)
            if nome:
                autoria_nomes[mid].append(nome)

    # ── sessões, presenças, votações, votos ─────────────────────────────────
    sessoes_raw = {s['id']: s for s in sapl_todos('sessao/sessaoplenaria', {'ordering': 'id'}) if s['legislatura'] in leg_ids}
    presenca = Counter()  # (parlamentar, legislatura) → n
    for p in sapl_todos('sessao/sessaoplenariapresenca', {'ordering': 'id'}):
        s = sessoes_raw.get(p['sessao_plenaria'])
        if s:
            presenca[(p['parlamentar'], s['legislatura'])] += 1
    sessoes_por_leg = Counter(s['legislatura'] for s in sessoes_raw.values())

    votacoes = {v['id']: v for v in sapl_todos('sessao/registrovotacao', {'ordering': 'id'})}
    votos = Counter()  # (parlamentar, legislatura, tipo) → n
    voto_valores = Counter()
    for v in sapl_todos('sessao/votoparlamentar', {'ordering': 'id'}):
        vt = votacoes.get(v['votacao'])
        m = materias.get(vt['materia']) if vt else None
        leg = _legislatura_de(m['data_apresentacao'], legislaturas) if m else None
        if leg is None:
            continue
        voto_valores[v['voto']] += 1
        votos[(v['parlamentar'], leg, _voto(v['voto']))] += 1
    log(f'sessoes={len(sessoes_raw)} votacoes={len(votacoes)} votos valores={dict(voto_valores)}')

    # ── normas (leis) ───────────────────────────────────────────────────────
    normas = [n for n in sapl_todos('norma/normajuridica', {'ordering': 'id'}) if (n.get('ano') or 0) >= ANO_MIN]
    normas.sort(key=lambda n: n.get('data') or '', reverse=True)
    leis_tipo_ano = defaultdict(Counter)
    for n in normas:
        leis_tipo_ano[str(n['ano'])][tipos_norma.get(n['tipo'], ('?', '?'))[0]] += 1

    def norma_json(n):
        return {
            'id': n['id'], 'tipo': tipos_norma.get(n['tipo'], ('?', '?'))[1], 'sigla': tipos_norma.get(n['tipo'], ('?', '?'))[0],
            'numero': n['numero'], 'ano': n['ano'], 'data': n.get('data'), 'dataPublicacao': n.get('data_publicacao'),
            'veiculo': n.get('veiculo_publicacao'), 'ementa': n.get('ementa', ''), 'textoUrl': n.get('texto_integral'),
            'url': f"{URL_SAPL_PUBLICO}/norma/{n['id']}", 'materia': n.get('materia'),
        }

    emendas_impositivas = []
    for n in normas:
        if n['tipo'] != TIPO_EMENDA_IMPOSITIVA:
            continue
        e = norma_json(n)
        pids = autoria.get(n.get('materia'), [])
        e['autores'] = autoria_nomes.get(n.get('materia'), []) or [parl_raw[p]['nome_parlamentar'] for p in pids if p in parl_raw]
        e['autoresIds'] = pids
        val = re.search(r'R\$\s*([\d.]+,\d{2})', n.get('ementa', ''))
        e['valor'] = comum.reais(val.group(1)) if val else None
        emendas_impositivas.append(e)

    # ── vereadores + estatísticas por legislatura ───────────────────────────
    materias_por_parl = defaultdict(list)
    for mid, pids in autoria.items():
        for pid in pids:
            materias_por_parl[pid].append(mid)

    def materia_json(m):
        sigla, desc = tipos_materia.get(m['tipo'], ('?', '?'))
        return {
            'id': m['id'], 'tipo': desc, 'sigla': sigla, 'numero': m['numero'], 'ano': m['ano'],
            'ementa': m.get('ementa', ''), 'data': m.get('data_apresentacao'), 'textoUrl': m.get('texto_original'),
            'emTramitacao': m.get('em_tramitacao'), 'url': f"{URL_SAPL_PUBLICO}/materia/{m['id']}",
        }

    vereadores = []
    parl_com_mandato = {m['parlamentar'] for m in mandatos}
    for pid in parl_com_mandato:
        p = parl_raw.get(pid)
        if not p:
            continue
        fil = sorted(filiacoes.get(pid, []), key=lambda f: f['data'])
        partido = partidos.get(fil[-1]['partido']) if fil else None
        mands = sorted([{
            'legislatura': m['legislatura'], 'inicio': m['data_inicio_mandato'], 'fim': m['data_fim_mandato'],
            'titular': m['titular'], 'afastado': bool(m.get('tipo_afastamento')),
        } for m in mandatos if m['parlamentar'] == pid], key=lambda m: m['inicio'] or '')
        est = {}
        for l in legislaturas:
            mats = [materias[mid] for mid in materias_por_parl.get(pid, []) if _legislatura_de(materias[mid]['data_apresentacao'], legislaturas) == l['id']]
            if not mats and not any(md['legislatura'] == l['id'] for md in mands):
                continue
            por_tipo = Counter(tipos_materia.get(m['tipo'], ('?', '?'))[0] for m in mats)
            emi = sum(1 for e in emendas_impositivas if pid in e['autoresIds'] and _legislatura_de(e['data'], legislaturas) == l['id'])
            est[str(l['id'])] = {
                'total': len(mats), 'porTipo': dict(por_tipo.most_common()), 'emendasImpositivas': emi,
                'votos': {k: votos.get((pid, l['id'], k), 0) for k in ('sim', 'nao', 'abstencao', 'naoVotou')},
                'presencas': presenca.get((pid, l['id']), 0), 'sessoes': sessoes_por_leg.get(l['id'], 0),
            }
        ultimas = sorted((materias[mid] for mid in materias_por_parl.get(pid, [])), key=lambda m: m.get('data_apresentacao') or '', reverse=True)[:8]
        vereadores.append({
            'id': pid, 'nome': p['nome_parlamentar'], 'nomeCompleto': p.get('nome_completo', ''), 'partido': partido,
            'foto': p.get('fotografia'), 'ativo': p.get('ativo', False),
            'url': f'{URL_SAPL_PUBLICO}/parlamentar/{pid}',
            'mandatos': mands, 'estatisticas': est, 'ultimasMaterias': [materia_json(m) for m in ultimas],
        })
    vereadores.sort(key=lambda v: (not v['ativo'], v['nome']))

    # ── sessões: últimas e próximas ─────────────────────────────────────────
    def sessao_json(s):
        return {
            'id': s['id'], 'titulo': s['__str__'], 'data': s['data_inicio'], 'horaInicio': s.get('hora_inicio'),
            'tipo': tipos_sessao.get(s['tipo'], ''), 'video': s.get('url_video') or None, 'ata': s.get('upload_ata'),
            'pauta': s.get('upload_pauta'), 'legislatura': s['legislatura'], 'tema': s.get('tema_solene') or None,
            'url': f"{URL_SAPL_PUBLICO}/sessao/{s['id']}",
        }
    ultimas_sessoes = sorted(sessoes_raw.values(), key=lambda s: (s['data_inicio'], s.get('hora_inicio') or ''), reverse=True)[:60]

    proximas = []
    html = comum.get(URL_CAMARA + '/') or comum.get(URL_CAMARA + '/cadastro-de-eventos') or ''
    for m in re.finditer(r'href="(https?://www\.saojoaodaboavista\.sp\.leg\.br/cadastro-de-eventos/[^"]+?/(\d{4}-\d{2}-\d{2}))"[^>]*>(.*?)</a>', html, re.S):
        d = m.group(2)
        if d >= date.today().isoformat():
            proximas.append({'titulo': comum.texto(m.group(3)) or 'Sessão', 'data': d, 'url': m.group(1)})
    proximas = sorted({p['url']: p for p in proximas}.values(), key=lambda p: p['data'])[:10]
    if not proximas:
        avisos.append('Não foi possível ler as próximas sessões do site da Câmara; veja a agenda em ' + URL_CAMARA)

    # ── matérias recentes com votação ───────────────────────────────────────
    votacao_por_materia = {}
    for v in votacoes.values():
        votacao_por_materia[v['materia']] = v  # fica a última
    recentes = sorted(materias.values(), key=lambda m: m.get('data_apresentacao') or '', reverse=True)[:100]
    materias_recentes = []
    for m in recentes:
        j = materia_json(m)
        j['autores'] = autoria_nomes.get(m['id'], []) or [parl_raw[p]['nome_parlamentar'] for p in autoria.get(m['id'], []) if p in parl_raw]
        j['autoresIds'] = autoria.get(m['id'], [])
        v = votacao_por_materia.get(m['id'])
        if v:
            j['votacao'] = {'resultado': resultados.get(v['tipo_resultado_votacao'], ''), 'sim': v['numero_votos_sim'],
                            'nao': v['numero_votos_nao'], 'abstencoes': v['numero_abstencoes']}
        materias_recentes.append(j)

    # ── gestões (prefeitos por mandato) ─────────────────────────────────────
    gestoes = []
    for l in legislaturas:
        gestoes.append({
            'legislatura': l['id'], 'numero': l['numero'], 'inicio': l['inicio'], 'fim': l['fim'], 'atual': l['atual'],
            'prefeito': None,
            'vereadores': [v['id'] for v in vereadores if any(m['legislatura'] == l['id'] for m in v['mandatos'])],
            'sessoes': sessoes_por_leg.get(l['id'], 0),
            'materias': sum(1 for m in materias.values() if _legislatura_de(m['data_apresentacao'], legislaturas) == l['id']),
            'leis': sum(1 for n in normas if _legislatura_de(n.get('data'), legislaturas) == l['id']),
        })
    tse = _prefeitos_tse()
    if tse:
        for g in gestoes:
            g['prefeito'] = tse.get(g['inicio'][:4])
    else:
        avisos.append('Nomes dos prefeitos indisponíveis: a API do TSE (DivulgaCandContas) recusa acesso automatizado (HTTP 403). '
                      'Períodos de gestão vêm das legislaturas do SAPL; o nome fica em branco em vez de ser digitado à mão.')

    return _fotos.espelhar(https_sapl({
        'fonte': {'sapl': SAPL, 'camara': URL_CAMARA},
        'legislaturas': legislaturas,
        'vereadores': vereadores,
        'sessoes': {'ultimas': [sessao_json(s) for s in ultimas_sessoes], 'proximas': proximas},
        'materiasRecentes': materias_recentes,
        'leisRecentes': [norma_json(n) for n in normas[:100]],
        'leisPorTipoAno': {a: dict(c) for a, c in sorted(leis_tipo_ano.items())},
        'emendasImpositivas': emendas_impositivas,
        'gestoes': gestoes,
        'metadados': {'materias': len(materias), 'votacoes': len(votacoes), 'votosNominais': sum(voto_valores.values()),
                      'votoValores': dict(voto_valores), 'normas': len(normas), 'sessoes': len(sessoes_raw)},
        'avisos': avisos,
    }))


def _prefeitos_tse():
    """Tenta a API pública do TSE. Em 2026-11-09 responde 403 a clientes não-navegador;
    devolvemos None e NÃO inventamos nomes."""
    base = 'https://divulgacandcontas.tse.jus.br/divulga/rest/v1'
    ordinarias = get_json(f'{base}/eleicao/ordinarias', tentativas=1, timeout=30)
    if not isinstance(ordinarias, list):
        return None
    out = {}
    for el in ordinarias:
        ano = el.get('ano')
        if ano not in (2012, 2016, 2020, 2024):
            continue
        muns = get_json(f"{base}/eleicao/buscar/SP/{el['id']}/municipios", tentativas=1, timeout=30) or {}
        cod = next((m['codigo'] for m in muns.get('municipios', []) if 'BOA VISTA' in m.get('nome', '').upper() and 'JO' in m.get('nome', '').upper()), None)
        if not cod:
            continue
        cands = get_json(f"{base}/candidatura/listar/{ano}/{cod}/{el['id']}/11/candidatos", tentativas=1, timeout=30) or {}
        for c in cands.get('candidatos', []):
            if 'eleito' in (c.get('descricaoTotalizacao') or '').lower():
                out[str(ano + 1)] = {'nome': c.get('nomeUrna'), 'partido': c.get('partido', {}).get('sigla'), 'fonte': 'TSE DivulgaCandContas'}
    return out or None
