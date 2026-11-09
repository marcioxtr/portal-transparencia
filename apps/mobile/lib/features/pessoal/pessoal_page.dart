import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../glossario/glossario_page.dart' show abrirTermo;

/// Pessoal e salários: quanto ganham prefeito, vice, vereadores e diretores;
/// quanto a Câmara gasta e com quem; folha e quadro de pessoal da Prefeitura.
/// Tudo de `dados/pessoal.json` (SAPL, Câmara, eCrie, TCE-SP). Só cargos e
/// valores — nomes de pessoas ficam nos documentos oficiais linkados.
class PessoalPage extends ConsumerWidget {
  const PessoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dados = ref.watch(dadosProvider('pessoal'));
    return Scaffold(
      appBar: AppBar(title: const Text('Salários e pessoal')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dadosProvider('pessoal').future),
        child: Async(
          valor: dados,
          aoTentarDeNovo: () => ref.invalidate(dadosProvider('pessoal')),
          dado: (j) => _Corpo(j: j),
        ),
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.j});
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sub = j.mapa('subsidios');
    final cam = j.mapa('camara');
    final pref = j.mapa('prefeitura');
    final fontes = j.mapa('fontes');
    final secoes = <Widget>[
      Text('Quanto ganham e quanto custam os que decidem pela cidade', style: tt.titleMedium),
      _QuantoGanham(sub: sub),
      _CamaraGasta(cam: cam),
      _FolhaPrefeitura(pref: pref),
      _CargosCamara(cam: cam),
      _QuadroPrefeitura(pref: pref),
      _Documentos(cam: cam, pref: pref),
      if (j.lista('avisos').isNotEmpty || (j['avisos'] as List?)?.isNotEmpty == true)
        CartaoVidro(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final a in (j['avisos'] as List? ?? const []))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('• $a', style: tt.bodySmall),
                ),
            ],
          ),
        ),
      CardProcedencia(url: Uri.parse(fontes.str('camara', 'https://www.saojoaodaboavista.sp.leg.br')), obtidoEm: geradoEm(j)),
      const SizedBox(height: 24),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: secoes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => Aparecer(indice: i, child: secoes[i]),
    );
  }
}

// ── Quanto ganham ──────────────────────────────────────────────────────────

class _QuantoGanham extends StatelessWidget {
  const _QuantoGanham({required this.sub});
  final Map<String, dynamic> sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final itens = <(String, String, Color, Map<String, dynamic>?)>[
      ('Prefeito', 'subsídio mensal', Cores.violeta, sub['prefeito'] as Map<String, dynamic>?),
      ('Vice-prefeito', 'subsídio mensal', Cores.azulCeu, sub['vice'] as Map<String, dynamic>?),
      ('Vereador', 'subsídio mensal (15 cadeiras)', Cores.verde, sub['vereador'] as Map<String, dynamic>?),
      ('Presidente da Câmara', 'subsídio mensal', Cores.laranja, sub['presidenteCamara'] as Map<String, dynamic>?),
      ('Diretor de departamento', 'o "secretário" municipal · valor inicial', Cores.rosa, sub['diretorDepartamento'] as Map<String, dynamic>?),
    ];
    return CartaoVidro(
      forte: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Quanto ganham', subtitulo: 'valores brutos fixados em lei · toque para ver a lei'),
          for (final (cargo, sub_, cor, d) in itens)
            InkWell(
              onTap: d == null ? null : () => _detalheSubsidio(context, cargo, d),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 36, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(5))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cargo, style: tt.titleSmall),
                          Text(sub_, style: tt.bodySmall),
                          if (d != null && d['lei'] != null) Text(d.str('lei'), style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    d == null
                        ? Text('—', style: tt.titleMedium)
                        : d['valor'] == null
                            ? Text('ver lei', style: tt.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary))
                            : NumeroAnimado(
                                valor: d.num_('valor'),
                                formatar: (v) => reais((v * 100).round()),
                                estilo: tt.titleMedium?.copyWith(color: cor, fontWeight: FontWeight.w800),
                              ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Subsídio é a remuneração única dos agentes políticos, fixada por lei para cada mandato (CF art. 39 §4º). '
            'O subsídio de prefeito é o teto para todos os servidores do município.',
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }

  void _detalheSubsidio(BuildContext context, String cargo, Map<String, dynamic> d) {
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cargo, style: tt.headlineSmall),
            if (d['valor'] != null) ...[
              const SizedBox(height: 4),
              Text('${reais((d.num_('valor') * 100).round())} por mês', style: tt.titleLarge),
            ],
            if (d['fonteValor'] != null) Campo('Valor conforme', d.str('fonteValor')),
            if (d['lei'] != null) Campo('Norma que fixou', d.str('lei')),
            if (d['ementa'] != null) Campo('Ementa', d.str('ementa')),
            if ((d['valoresNoTexto'] as List?)?.isNotEmpty == true)
              Campo('Valores citados no texto da lei', (d['valoresNoTexto'] as List).map((v) => reais(((v as num) * 100).round())).join(' · ')),
            if ((d['cargos'] as List?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Cargos de direção e assessoria (valor inicial)', style: tt.titleSmall),
              for (final c in (d['cargos'] as List).cast<Map<String, dynamic>>().take(40))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Expanded(child: Text(c.str('funcao'), style: tt.bodySmall)),
                    Text(reais((c.num_('valorInicial') * 100).round()), style: tt.labelLarge),
                  ]),
                ),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (d['textoUrl'] != null)
                FilledButton.tonalIcon(
                  onPressed: () => abrirUrl(Uri.parse(d.str('textoUrl'))),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Texto da lei (PDF)'),
                ),
              if (d['saplUrl'] != null)
                OutlinedButton.icon(
                  onPressed: () => abrirUrl(Uri.parse(d.str('saplUrl'))),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ficha no SAPL'),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Quanto a Câmara gasta ──────────────────────────────────────────────────

class _CamaraGasta extends StatefulWidget {
  const _CamaraGasta({required this.cam});
  final Map<String, dynamic> cam;

  @override
  State<_CamaraGasta> createState() => _CamaraGastaState();
}

class _CamaraGastaState extends State<_CamaraGasta> {
  String? _ano;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final gasto = widget.cam.mapa('gastoAno').map((k, v) => MapEntry(k, (v as num).toDouble()));
    final folha = widget.cam.mapa('folhaAno').map((k, v) => MapEntry(k, (v as num).toDouble()));
    final anos = gasto.keys.toList()..sort();
    if (anos.isEmpty) return const SizedBox.shrink();
    final topPorAno = widget.cam.mapa('topFornecedores');
    final anosComTop = topPorAno.keys.toList()..sort();
    final anoSel = _ano ?? (anosComTop.isNotEmpty ? anosComTop.last : anos.last);
    final top = (topPorAno[anoSel] as List? ?? const []).cast<Map<String, dynamic>>();
    final maxY = gasto.values.fold<double>(0, (m, v) => v > m ? v : m);

    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Quanto a Câmara gasta', subtitulo: 'empenhado por ano · em milhões · toque numa barra'),
          SizedBox(
            height: 180,
            child: BarChart(
              duration: const Duration(milliseconds: 600),
              BarChartData(
                maxY: maxY / 1e6 * 1.15,
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Vidro.of(context).borda, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: tt.labelSmall))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= anos.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 4), child: Text(anos[i].substring(2), style: tt.labelSmall));
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  longPressDuration: const Duration(milliseconds: 220),
                  touchCallback: (e, r) {
                    final i = r?.spot?.touchedBarGroupIndex;
                    if (i != null && e.isInterestedForInteractions && topPorAno.containsKey(anos[i])) setState(() => _ano = anos[i]);
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, _, rod, __) => BarTooltipItem('${anos[g.x]}\n${reaisCurto((rod.toY * 1e6 * 100).round())}', TextStyle(color: tt.bodyMedium?.color, fontWeight: FontWeight.w700)),
                  ),
                ),
                barGroups: [
                  for (final (i, a) in anos.indexed)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: gasto[a]! / 1e6,
                        width: 14,
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Cores.violeta, a == anoSel ? Cores.rosa : Cores.violeta.withValues(alpha: 0.6)]),
                        rodStackItems: folha[a] != null
                            ? [BarChartRodStackItem(0, folha[a]! / 1e6, Cores.azulCeu.withValues(alpha: 0.9))]
                            : const [],
                      ),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 14, children: [
            _Legenda(Cores.violeta, 'Total empenhado'),
            _Legenda(Cores.azulCeu, 'Folha e encargos (quando detalhado)'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('Em $anoSel: ${reaisCurto((gasto[anoSel]! * 100).round())}${folha[anoSel] != null ? ' · folha ${reaisCurto((folha[anoSel]! * 100).round())} (${(folha[anoSel]! / gasto[anoSel]! * 100).toStringAsFixed(0)}%)' : ''}', style: tt.bodyMedium)),
            IconButton(icon: const Icon(Icons.info_outline, size: 20), tooltip: 'O que é duodécimo?', onPressed: () => abrirTermo(context, 'duodecimo')),
          ]),
          if (top.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Com quem a Câmara gastou em $anoSel', style: tt.titleSmall),
            for (final (i, f) in top.take(10).indexed)
              BarraProporcao(
                rotulo: _titulo(f.str('nome')),
                valor: reaisCurto((f.num_('empenhado') * 100).round()),
                sub: f.bool_('folha') ? 'folha / encargos' : 'empresa ou serviço',
                proporcao: f.num_('empenhado') / top.first.num_('empenhado'),
                cor: f.bool_('folha') ? Cores.azulCeu : Cores.serie(i),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Folha da Prefeitura ────────────────────────────────────────────────────

class _FolhaPrefeitura extends StatelessWidget {
  const _FolhaPrefeitura({required this.pref});
  final Map<String, dynamic> pref;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final folhaAno = pref.mapa('folhaAno').map((k, v) => MapEntry(k, (v as num).toDouble()));
    final gastoAno = pref.mapa('gastoAno').map((k, v) => MapEntry(k, (v as num).toDouble()));
    final porMes = pref.mapa('folhaPorMes');
    if (folhaAno.isEmpty) return const SizedBox.shrink();
    final anos = folhaAno.keys.toList()..sort();
    final ano = anos.last;
    final meses = (porMes[ano] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
    final mesesOrd = meses.keys.toList()..sort();
    const nomes = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    final topFolha = pref.mapa('topFornecedoresFolha')[ano] as List? ?? const [];

    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Folha da Prefeitura', subtitulo: 'empenhos classificados como folha, encargos e previdência · TCE-SP'),
          Row(children: [
            for (final a in anos)
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a, style: tt.labelLarge),
                  Text(reaisCurto((folhaAno[a]! * 100).round()), style: tt.titleMedium?.copyWith(color: Cores.azulCeu, fontWeight: FontWeight.w800)),
                  if (gastoAno[a] != null) Text('${(folhaAno[a]! / gastoAno[a]! * 100).toStringAsFixed(0)}% do gasto da Prefeitura', style: tt.bodySmall),
                ]),
              ),
          ]),
          if (mesesOrd.length >= 2) ...[
            const SizedBox(height: 12),
            Text('Mês a mês em $ano (milhões)', style: tt.labelMedium),
            const SizedBox(height: 6),
            SizedBox(
              height: 110,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      return i >= 0 && i < mesesOrd.length ? Text(nomes[mesesOrd[i] - 1], style: tt.labelSmall) : const SizedBox.shrink();
                    })),
                  ),
                  barTouchData: BarTouchData(
                    longPressDuration: const Duration(milliseconds: 220),
                    touchTooltipData: BarTouchTooltipData(getTooltipItem: (g, _, rod, __) => BarTooltipItem(reaisCurto((rod.toY * 1e6 * 100).round()), TextStyle(color: tt.bodyMedium?.color, fontWeight: FontWeight.w700))),
                  ),
                  barGroups: [
                    for (final (i, m) in mesesOrd.indexed)
                      BarChartGroupData(x: i, barRods: [BarChartRodData(toY: meses[m]! / 1e6, width: 12, color: Cores.azulCeu, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
          ],
          if (topFolha.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Para onde vai a folha em $ano', style: tt.titleSmall),
            for (final (i, f) in topFolha.cast<Map<String, dynamic>>().take(6).indexed)
              BarraProporcao(
                rotulo: _titulo(f.str('nome')),
                valor: reaisCurto((f.num_('empenhado') * 100).round()),
                proporcao: f.num_('empenhado') / (topFolha.first as Map<String, dynamic>).num_('empenhado'),
                cor: Cores.serie(i),
              ),
          ],
          const SizedBox(height: 6),
          TextButton(onPressed: () => abrirTermo(context, 'lrf'), child: const Text('Limite de gasto com pessoal (LRF)')),
        ],
      ),
    );
  }
}

// ── Cargos da Câmara ───────────────────────────────────────────────────────

class _CargosCamara extends StatelessWidget {
  const _CargosCamara({required this.cam});
  final Map<String, dynamic> cam;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cargos = cam.lista('cargos');
    if (cargos.isEmpty) return const SizedBox.shrink();
    final categorias = <String, List<Map<String, dynamic>>>{};
    for (final c in cargos) {
      categorias.putIfAbsent(c.str('categoria', 'Outros'), () => []).add(c);
    }
    final providos = cargos.fold<int>(0, (s, c) => s + c.int_('providos'));
    final vagos = cargos.fold<int>(0, (s, c) => s + c.int_('vagos'));
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Cargos da Câmara', subtitulo: '$providos ocupados · $vagos vagos · valor base mensal'),
          for (final e in categorias.entries) ...[
            Padding(padding: const EdgeInsets.only(top: 8, bottom: 2), child: Text(e.key, style: tt.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary))),
            for (final c in e.value)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(c.str('cargo'), style: tt.bodyMedium)),
                  Text('${c.int_('providos')}', style: tt.labelMedium),
                  const SizedBox(width: 12),
                  SizedBox(width: 92, child: Text(reais((c.num_('valorBase') * 100).round()), textAlign: TextAlign.right, style: tt.labelLarge)),
                ]),
              ),
          ],
          const SizedBox(height: 4),
          Text('Quantidade = ocupados. Cargo em comissão é de livre nomeação (sem concurso).', style: tt.bodySmall),
        ],
      ),
    );
  }
}

// ── Quadro da Prefeitura ───────────────────────────────────────────────────

class _QuadroPrefeitura extends StatefulWidget {
  const _QuadroPrefeitura({required this.pref});
  final Map<String, dynamic> pref;

  @override
  State<_QuadroPrefeitura> createState() => _QuadroPrefeituraState();
}

class _QuadroPrefeituraState extends State<_QuadroPrefeitura> {
  String _busca = '';
  bool _mostrarTabela = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final quadro = widget.pref['quadroPessoal'] as Map<String, dynamic>?;
    final tabela = widget.pref.lista('tabelaSalarial');
    final diretores = widget.pref.lista('diretores');
    if (quadro == null && tabela.isEmpty) return const SizedBox.shrink();

    final salarioPorFuncao = {for (final t in tabela) _norm(t.str('funcao')): t.num_('valorInicial')};
    final cargos = (quadro?.lista('cargos') ?? const <Map<String, dynamic>>[]).where((c) {
      if (_busca.isEmpty) return true;
      return c.str('cargo').toLowerCase().contains(_busca.toLowerCase());
    }).toList()
      ..sort((a, b) => b.int_('providos').compareTo(a.int_('providos')));
    final totais = quadro?.mapa('totais') ?? const <String, dynamic>{};

    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Quadro de pessoal da Prefeitura', subtitulo: quadro == null ? 'tabela salarial oficial' : 'referência ${quadro.str('referencia')} · ${totais['providos']} servidores em ${cargos.length} cargos'),
          if (quadro != null)
            Row(children: [
              _Kpi('Servidores', '${totais['providos']}', Cores.azulCeu),
              _Kpi('Vagos', '${totais['vagos']}', Cores.laranja),
              _Kpi('Em comissão*', '${totais['colunaB']}', Cores.rosa),
              _Kpi('Diretores/assessores', '${diretores.length}', Cores.violeta),
            ]),
          if (quadro != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('*coluna B do documento oficial (forma de provimento); confira a legenda no PDF.', style: tt.bodySmall)),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(hintText: 'Buscar cargo (ex.: professor, médico, diretor)', prefixIcon: Icon(Icons.search), isDense: true),
            onChanged: (v) => setState(() => _busca = v.trim()),
          ),
          const SizedBox(height: 8),
          for (final c in cargos.take(_busca.isEmpty ? 12 : 40))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(_titulo(c.str('cargo')), style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('${c.int_('providos')}', style: tt.labelLarge),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: Text(
                    salarioPorFuncao[_norm(c.str('cargo'))] != null ? reais((salarioPorFuncao[_norm(c.str('cargo'))]! * 100).round()) : '—',
                    textAlign: TextAlign.right,
                    style: tt.labelMedium,
                  ),
                ),
              ]),
            ),
          Text('quantidade de servidores · salário inicial (quando o nome do cargo coincide na Tabela Salarial)', style: tt.bodySmall),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _mostrarTabela = !_mostrarTabela),
            icon: Icon(_mostrarTabela ? Icons.expand_less : Icons.expand_more),
            label: Text(_mostrarTabela ? 'Ocultar tabela salarial' : 'Tabela salarial completa (${tabela.length} funções)'),
          ),
          if (_mostrarTabela)
            for (final t in tabela)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text(_titulo(t.str('funcao')), style: tt.bodySmall)),
                  Text(reais((t.num_('valorInicial') * 100).round()), style: tt.labelMedium),
                ]),
              ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.rotulo, this.valor, this.cor);
  final String rotulo, valor;
  final Color cor;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cor, fontWeight: FontWeight.w800)),
          Text(rotulo, style: Theme.of(context).textTheme.labelSmall, maxLines: 2),
        ]),
      );
}

// ── Documentos ─────────────────────────────────────────────────────────────

class _Documentos extends StatelessWidget {
  const _Documentos({required this.cam, required this.pref});
  final Map<String, dynamic> cam, pref;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final docsCam = cam.lista('documentos');
    final docsPref = pref.lista('documentos');
    if (docsCam.isEmpty && docsPref.isEmpty) return const SizedBox.shrink();
    Widget item(Map<String, dynamic> d) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(d.str('url').toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.open_in_new, size: 20),
          title: Text(d.str('titulo'), style: tt.bodyMedium),
          subtitle: d['referencia'] != null ? Text('referência ${d.str('referencia')}', style: tt.bodySmall) : null,
          onTap: () => abrirUrl(Uri.parse(d.str('url'))),
        );
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Documentos oficiais', subtitulo: 'os PDFs de onde estes números saem — com nomes, quando o original traz'),
          if (docsPref.isNotEmpty) Text('Prefeitura', style: tt.labelLarge),
          for (final d in docsPref) item(d),
          if (docsCam.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Câmara Municipal', style: tt.labelLarge)),
          for (final d in docsCam.take(14)) item(d),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda(this.cor, this.texto);
  final Color cor;
  final String texto;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.labelMedium),
      ]);
}

String _norm(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-ZÀ-Ü]'), '');

String _titulo(String s) {
  const minus = {'de', 'da', 'do', 'das', 'dos', 'e', 'em', 'a', 'o', 'para'};
  return s.toLowerCase().split(RegExp(r'\s+')).map((w) => w.isEmpty || minus.contains(w) ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ').trim();
}
