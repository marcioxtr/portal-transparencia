import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../data/painel.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// Comparar anos e mandatos: mesma métrica lado a lado, 2014 → hoje.
/// Só números e variações — o julgamento é do cidadão.
class CompararPage extends ConsumerStatefulWidget {
  const CompararPage({super.key});

  @override
  ConsumerState<CompararPage> createState() => _CompararPageState();
}

class _CompararPageState extends ConsumerState<CompararPage> {
  bool _porMandato = false;

  @override
  Widget build(BuildContext context) {
    final dados = ref.watch(dadosProvider('indicadores'));
    return Scaffold(
      appBar: AppBar(title: const Text('Comparar anos e mandatos')),
      body: Async(
        valor: dados,
        aoTentarDeNovo: () => ref.invalidate(dadosProvider('indicadores')),
        dado: (j) {
          final anos = j.lista('anos');
          final mandatos = j.lista('mandatos');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              Aparecer(
                child: Row(
                  children: [
                    PilulaVidro(
                      rotulo: 'Por ano',
                      icone: Icons.calendar_today_outlined,
                      selecionada: !_porMandato,
                      onTap: () => setState(() => _porMandato = false),
                    ),
                    const SizedBox(width: 8),
                    PilulaVidro(
                      rotulo: 'Por mandato',
                      icone: Icons.how_to_vote_outlined,
                      selecionada: _porMandato,
                      onTap: () => setState(() => _porMandato = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!_porMandato) ...[
                Aparecer(indice: 1, child: _GraficoAnos(anos: anos)),
                const SizedBox(height: 14),
                Aparecer(indice: 2, child: _PorMorador(anos: anos)),
                const SizedBox(height: 14),
                Aparecer(indice: 3, child: _TabelaAnos(anos: anos)),
              ] else ...[
                Aparecer(indice: 1, child: _Mandatos(mandatos: mandatos)),
              ],
              const SizedBox(height: 14),
              Aparecer(
                indice: 4,
                child: CardProcedencia(
                  url: Uri.parse('https://transparencia.tce.sp.gov.br/municipio/sao-joao-da-boa-vista'),
                  obtidoEm: geradoEm(j),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GraficoAnos extends StatelessWidget {
  const _GraficoAnos({required this.anos});
  final List<Map<String, dynamic>> anos;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final maxY = anos.fold<double>(0, (m, a) => [m, a.num_('receita'), a.num_('pago')].reduce((x, y) => x > y ? x : y)) / 1e6;
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Arrecadado × pago por ano', style: tt.titleMedium),
          Text('em milhões de reais · anos parciais marcados com *', style: tt.bodySmall),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: BarChart(
              duration: const Duration(milliseconds: 600),
              BarChartData(
                maxY: maxY * 1.12,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Vidro.of(context).borda, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  longPressDuration: const Duration(milliseconds: 220),
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                      reaisCurto((rod.toY * 1e6 * 100).round()),
                      TextStyle(color: rod.color, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('${v.round()}', style: tt.labelSmall),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i >= anos.length) return const SizedBox.shrink();
                        final a = anos[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "'${'${a.int_('ano')}'.substring(2)}${a.bool_('parcial') ? '*' : ''}",
                            style: tt.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (final (i, a) in anos.indexed)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: a.num_('receita') / 1e6,
                          color: Cores.receita,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: a.num_('pago') / 1e6,
                          color: Cores.despesa,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 14, children: const [
            _Legenda(Cores.receita, 'Arrecadado'),
            _Legenda(Cores.despesa, 'Pago'),
          ]),
        ],
      ),
    );
  }
}

class _PorMorador extends StatelessWidget {
  const _PorMorador({required this.anos});
  final List<Map<String, dynamic>> anos;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pontos = anos.where((a) => a.numOuNulo('pagoPorHabitante') != null).toList();
    if (pontos.length < 2) return const SizedBox.shrink();
    final maxY = pontos.fold<double>(0, (m, a) => [m, a.num_('receitaPorHabitante'), a.num_('pagoPorHabitante')].reduce((x, y) => x > y ? x : y));
    LineChartBarData serie(String k, Color c) => LineChartBarData(
          spots: [for (final (i, a) in pontos.indexed) FlSpot(i.toDouble(), a.num_(k))],
          isCurved: true,
          color: c,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        );
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Por morador', style: tt.titleMedium),
          Text('reais por habitante · população do IBGE via SICONFI', style: tt.bodySmall),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: LineChart(
              duration: const Duration(milliseconds: 600),
              LineChartData(
                minY: 0,
                maxY: maxY * 1.15,
                gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Vidro.of(context).borda, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  longPressDuration: const Duration(milliseconds: 220),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (s) => [for (final p in s) LineTooltipItem(reais((p.y * 100).round()), TextStyle(color: p.bar.color, fontWeight: FontWeight.w700))],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text('${(v / 1000).toStringAsFixed(1)}k', style: tt.labelSmall))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i >= pontos.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 6), child: Text("'${'${pontos[i].int_('ano')}'.substring(2)}", style: tt.labelSmall));
                      },
                    ),
                  ),
                ),
                lineBarsData: [serie('receitaPorHabitante', Cores.receita), serie('pagoPorHabitante', Cores.despesa)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabelaAnos extends ConsumerWidget {
  const _TabelaAnos({required this.anos});
  final List<Map<String, dynamic>> anos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final ordenados = [...anos]..sort((a, b) => b.int_('ano').compareTo(a.int_('ano')));
    return CartaoVidro(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ano a ano', style: tt.titleMedium),
          Text('toque para abrir o painel daquele ano', style: tt.bodySmall),
          const SizedBox(height: 8),
          for (final (i, a) in ordenados.indexed) ...[
            _LinhaAno(
              a: a,
              anterior: i + 1 < ordenados.length ? ordenados[i + 1] : null,
              onTap: () {
                ref.read(anoPainelProvider.notifier).definir(a.int_('ano'));
                context.go(Rotas.inicio);
              },
            ),
            if (i < ordenados.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _LinhaAno extends StatelessWidget {
  const _LinhaAno({required this.a, required this.anterior, required this.onTap});
  final Map<String, dynamic> a;
  final Map<String, dynamic>? anterior;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final rec = a.num_('receita');
    final pago = a.num_('pago');
    final varRec = anterior == null || anterior!.num_('receita') == 0 ? null : (rec - anterior!.num_('receita')) / anterior!.num_('receita') * 100;
    final top = a.lista('funcoesTop');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${a.int_('ano')}${a.bool_('parcial') ? ' (até mês ${a.int_('meses')})' : ''}', style: tt.titleMedium),
                const Spacer(),
                if (varRec != null && !a.bool_('parcial'))
                  Text(
                    '${varRec >= 0 ? '+' : ''}${varRec.toStringAsFixed(1)}% receita',
                    style: tt.labelMedium?.copyWith(color: varRec >= 0 ? Cores.receita : Cores.despesa),
                  ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                Text('Entrou ${reaisCurto((rec * 100).round())}', style: tt.bodySmall),
                Text('Pagou ${reaisCurto((pago * 100).round())}', style: tt.bodySmall),
                if (a.numOuNulo('pagoPorHabitante') != null)
                  Text('${reais((a.num_('pagoPorHabitante') * 100).round())}/morador', style: tt.bodySmall),
              ],
            ),
            if (top.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  top.map((f) => '${f.str('nome')} ${f.num_('percentual').toStringAsFixed(0)}%').join(' · '),
                  style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Mandatos extends StatelessWidget {
  const _Mandatos({required this.mandatos});
  final List<Map<String, dynamic>> mandatos;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final ordenados = [...mandatos]..sort((a, b) => b.int_('inicio').compareTo(a.int_('inicio')));
    final maxPh = ordenados.fold<double>(0, (m, x) => x.num_('pagoPorHabitanteMedia') > m ? x.num_('pagoPorHabitanteMedia') : m);
    return Column(
      children: [
        CartaoVidro(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mandatos', style: tt.titleMedium),
              Text(
                'Totais do período e média por morador/ano. Nomes de prefeitos vêm dos dados abertos do TSE; quando ainda não estão disponíveis aparece "—".',
                style: tt.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final (i, m) in ordenados.indexed)
                BarraProporcao(
                  rotulo: '${m.str('periodo')} · ${m.strOuNulo('prefeito') ?? '—'}',
                  valor: '${reais((m.num_('pagoPorHabitanteMedia') * 100).round())}/morador·ano',
                  sub: 'Entrou ${reaisCurto((m.num_('receita') * 100).round())} · pagou ${reaisCurto((m.num_('pago') * 100).round())}'
                      '${m.bool_('completo') ? '' : ' · período incompleto (${(m['anos'] as List).join(', ')})'}',
                  proporcao: maxPh == 0 ? 0 : m.num_('pagoPorHabitanteMedia') / maxPh,
                  cor: Cores.serie(i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Aviso(
          'Comparar mandatos exige cuidado: inflação, repasses federais e a pandemia mudam muito o contexto de cada período. '
          'O app mostra os números; a avaliação é sua.',
          icone: Icons.balance_outlined,
        ),
      ],
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
