/*
  Captura amostras reais da API do SmarAPD PAI (Portal da Transparência 2026+).

  COMO USAR (2 minutos):
    1. Abra https://transparencia-saojoaodaboavista.smarapd.com.br/#/ no Chrome.
    2. Aperte F12 (ou Cmd+Option+I no Mac) → aba "Console".
    3. Cole este arquivo inteiro e aperte Enter.
    4. Aguarde a mensagem "✅ pronto" — o navegador vai baixar
       `smarapd-amostras-AAAA-MM-DD.json`. Coloque-o nesta pasta (docs/api/samples/).

  O que ele faz: chama os mesmos endpoints que o portal chama, um de cada vez
  (sem paralelismo, com pausa entre chamadas), e salva as respostas. Não envia
  nada para lugar nenhum além do próprio portal. Não chama `POST Estatistica`.
*/
(async () => {
  const BASE = `${location.origin}/paiportalserver`;
  const pausa = (ms) => new Promise((r) => setTimeout(r, ms));
  const saida = { capturadoEm: new Date().toISOString(), origem: location.origin, get: {}, post: {}, erros: [] };

  async function get(caminho) {
    try {
      const r = await fetch(`${BASE}/${caminho}`, { headers: { Accept: 'application/json' } });
      const texto = await r.text();
      let corpo; try { corpo = JSON.parse(texto); } catch { corpo = texto; }
      saida.get[caminho] = { status: r.status, corpo };
      console.log(`GET ${caminho} → ${r.status}`);
      await pausa(400);
      return r.ok ? corpo : null;
    } catch (e) { saida.erros.push({ caminho, erro: String(e) }); return null; }
  }
  async function post(caminho, body) {
    try {
      const r = await fetch(`${BASE}/${caminho}`, {
        method: 'POST', headers: { Accept: 'application/json', 'Content-Type': 'application/json' }, body: JSON.stringify(body),
      });
      const texto = await r.text();
      let corpo; try { corpo = JSON.parse(texto); } catch { corpo = texto; }
      saida.post[caminho] = saida.post[caminho] || [];
      saida.post[caminho].push({ status: r.status, body, corpo });
      console.log(`POST ${caminho} → ${r.status}`);
      await pausa(600);
      return r.ok ? corpo : null;
    } catch (e) { saida.erros.push({ caminho, body, erro: String(e) }); return null; }
  }

  // 1) Bootstrap
  await get('cliente');
  await get('configuracaoaparencia');
  const menu = await get('MenuPortal');
  const exercicios = await get('exercicio');
  for (const k of ['sumario', 'faleconosco', 'autenticidade', 'busca_documentos']) await get(`Modulo/habilitado/${k}`);

  // 2) Home do ano atual (tenta o maior exercício; senão o ano corrente)
  const anos = Array.isArray(exercicios) ? exercicios.map((e) => (typeof e === 'number' ? e : e?.Ano ?? e?.Exercicio ?? e?.Valor)).filter(Number.isFinite) : [];
  const ano = anos.length ? Math.max(...anos) : new Date().getFullYear();
  await get(`home/${ano}`);

  // 3) Institucional
  for (const c of ['DadosAbertos', 'estruturaOrganizacional', 'glossario', 'faq', 'periodicidade', 'periodicidade/periodos',
                   'BuscaDocumento/modulos', 'esic/configuracoes', 'esic/exercicios', `esic/visoes/exercicio/${ano}`,
                   'estatistica/anos', 'autenticidade/configuracoes']) await get(c);

  // 4) Visões dinâmicas: percorre o menu e pega config + 1ª página de cada uma (máx. 12)
  const visoes = [];
  (function andar(n) {
    if (!n) return;
    if (Array.isArray(n)) return n.forEach(andar);
    if (typeof n === 'object') {
      const uri = n.URI || n.Uri || n.uri || n.Link || '';
      const m = /\/(dinamico|fixo)\/([^/]+)\/([^/?#]+)/.exec(uri);
      if (m) visoes.push({ tipo: m[1], modulo: m[2], visao: m[3], titulo: n.Titulo || n.titulo || '' });
      Object.values(n).forEach(andar);
    }
  })(menu);
  saida.visoesEncontradas = visoes;
  console.log(`${visoes.length} visões encontradas no menu`);

  for (const v of visoes.slice(0, 12)) {
    if (v.tipo === 'dinamico') {
      await get(`modulovisao/${v.modulo}/${v.visao}/configuracao`);
      await get(`Modulo/${v.modulo}/colunasfiltro`);
      const filtro = { ChaveModulo: v.modulo, NomeVisao: v.visao, Filtros: [], Periodicidade: null, Periodo: null,
                       Exercicio: ano, Pagina: 1, QuantidadeRegistros: 10, Ordenacao: [], FiltroRedirecionaVisao: null };
      await post('modulovisao/filter', filtro);
      await post('modulovisao/colunasTotalizadoras', filtro);
    } else {
      await get(`modulovisao/fixo/${v.modulo}/${v.visao}`);
    }
  }

  // 5) Busca de documentos (um termo genérico)
  await post('BuscaDocumento/busca', { Termo: 'contrato', Periodo: null, Inicio: null, Fim: null, ChaveModulo: null });

  // 6) Baixa o arquivo
  const blob = new Blob([JSON.stringify(saida, null, 2)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `smarapd-amostras-${new Date().toISOString().slice(0, 10)}.json`;
  document.body.appendChild(a); a.click(); a.remove();
  console.log('✅ pronto — arquivo baixado. Erros:', saida.erros.length);
})();
