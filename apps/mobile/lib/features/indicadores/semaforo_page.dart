import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../glossario/glossario_page.dart' show abrirTermo;

/// Mínimos constitucionais (saúde 15%, educação 25%) e limite de pessoal da
/// LRF (54%) com semáforo e série histórica. Fonte: SICONFI.
class SemaforoPage extends ConsumerWidget {
  const SemaforoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dados = ref.watch(dadosProvider('indicadores'));
    return Scaffold(
      appBar: AppBar(title: const Text('Limites legais')),
      body: Async(
        valor: dados,
        aoTentarDeNovo: () => ref.invalidate(dadosProvider('indicadores')),
        dado: (j) {
          final lrf = j.lista('lrf')..sort((a, b) => a.int_('ano').compareTo(b.int_('ano')));
          final minimos = j.lista('minimos')..sort((a, b) => a.int_('ano').compareTo(b.int_('ano')));
          final avisos = (j['avisos'] as List? ?? const []).cast<String>();
          final ultLrf = lrf.where((r) => r.numOuNulo('pessoalPercentual') != null).lastOrNull;
          final ultMin = minimos.lastOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              Aparecer(
                child: Text('Três regras que todo município tem de cumprir — e como São João está.',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 14),
              if (ultMin != null) ...[
                Aparecer(
                  indice: 1,
                  child: _Regra(
                    titulo: 'Saúde',
                    regra: 'pelo menos 15% da receita de impostos',
                    valor: ultMin.numOuNulo('saudePercentual'),
                    aproximado: ultMin.mapa('aproximacao').numOuNulo('saudeShare'),
                    minimo: true,
                    limite: 15,
                    ano: ultMin.int_('ano'),
                    periodo: ultMin.strOuNulo('periodo'),
                    termo: 'educacao_minimo',
                    cor: Cores.rosa,
                  ),
                ),
                const SizedBox(height: 14),
                Aparecer(
                  indice: 2,
                  child: _Regra(
                    titulo: 'Educação',
                    regra: 'pelo menos 25% da receita de impostos',
                    valor: ultMin.numOuNulo('educacaoPercentual'),
                    aproximado: ultMin.mapa('aproximacao').numOuNulo('educacaoShare'),
                    minimo: true,
                    limite: 25,
                    ano: ultMin.int_('ano'),
                    periodo: ultMin.strOuNulo('periodo'),
                    termo: 'educacao_minimo',
                    cor: Cores.laranja,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (ultLrf != null) ...[
                Aparecer(
                  indice: 3,
                  child: _Regra(
                    titulo: 'Gasto com pessoal (LRF)',
                    regra: 'no máximo ${ultLrf.num_('limiteMaximo', 54).toStringAsFixed(0)}% da receita corrente líquida',
                    valor: ultLrf.numOuNulo('pessoalPercentual'),
                    minimo: false,
                    limite: ultLrf.num_('limiteMaximo', 54),
                    alerta: ultLrf.num_('limiteAlerta', 48.6),
                    ano: ultLrf.int_('ano'),
                    periodo: ultLrf.strOuNulo('periodo'),
                    termo: 'lrf',
                    cor: Cores.violeta,
                  ),
                ),
                const SizedBox(height: 14),
                Aparecer(indice: 4, child: _SerieLrf(lrf: lrf)),
                const SizedBox(height: 14),
              ],
              for (final a in avisos) ...[
                Aparecer(indice: 5, child: Aviso(a, icone: Icons.info_outline)),
                const SizedBox(height: 14),
              ],
              Aparecer(
                indice: 6,
                child: CardProcedencia(
                  url: Uri.parse('https://siconfi.tesouro.gov.br/siconfi/pages/public/consulta_finbra/finbra_list.jsf'),
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

class _Regra extends StatelessWidget {
  const _Regra({
    required this.titulo,
    required this.regra,
    required this.valor,
    required this.minimo,
    required this.limite,
    required this.ano,
    required this.termo,
    required this.cor,
    this.aproximado,
    this.alerta,
    this.periodo,
  });

  final String titulo, regra, termo;
  final double? valor, aproximado, alerta;
  final bool minimo;
  final double limite;
  final int ano;
  final String? periodo;
  final Color cor;

  (Color, String, IconData) _estado() {
    final v = valor;
    if (v == null) {
      return (Colors.grey, 'Índice oficial não publicado no SICONFI', Icons.help_outline);
    }
    if (minimo) {
      if (v >= limite) return (Cores.verde, 'Cumpre o mínimo', Icons.check_circle_outline);
      if (v >= limite * 0.95) return (Cores.amarelo, 'No limite', Icons.warning_amber_rounded);
      return (Cores.rosa, 'Abaixo do mínimo', Icons.error_outline);
    }
    if (v > limite) return (Cores.rosa, 'Acima do limite máximo', Icons.error_outline);
    if (alerta != null && v >= alerta!) return (Cores.amarelo, 'Zona de alerta', Icons.warning_amber_rounded);
    return (Cores.verde, 'Dentro do limite', Icons.check_circle_outline);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (corEstado, rotulo, icone) = _estado();
    return CartaoVidro(
      cor: cor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(titulo, style: tt.titleLarge)),
            IconButton(
              tooltip: 'Entenda a regra',
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => abrirTermo(context, termo),
            ),
          ]),
          Text(regra, style: tt.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: corEstado.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(icone, color: corEstado, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (valor != null)
                      NumeroAnimado(
                        valor: valor!,
                        formatar: (v) => '${v.toStringAsFixed(1)}%',
                        estilo: tt.headlineMedium?.copyWith(color: corEstado),
                      )
                    else if (aproximado != null)
                      Text('≈ ${aproximado!.toStringAsFixed(1)}% da despesa total',
                          style: tt.titleLarge?.copyWith(color: tt.bodyMedium?.color)),
                    Text(rotulo, style: tt.labelLarge?.copyWith(color: corEstado)),
                    Text('$ano${periodo != null ? ' · $periodo' : ''}', style: tt.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (valor != null) ...[
            const SizedBox(height: 12),
            _Medidor(valor: valor!, limite: limite, minimo: minimo, cor: corEstado),
          ],
          if (valor == null && aproximado != null) ...[
            const SizedBox(height: 10),
            Text(
              'Aproximação: fatia da função "$titulo" na despesa empenhada total (DCA/RREO). '
              'A base legal é a receita de impostos e transferências, não a despesa — por isso não dá semáforo.',
              style: tt.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Medidor extends StatelessWidget {
  const _Medidor({required this.valor, required this.limite, required this.minimo, required this.cor});
  final double valor, limite;
  final bool minimo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final escala = (limite * 1.6).clamp(1, 100).toDouble();
    final v = Vidro.of(context);
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Container(height: 12, decoration: BoxDecoration(color: v.superficie, borderRadius: BorderRadius.circular(6))),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (valor / escala).clamp(0, 1)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, f, __) => Container(
              height: 12,
              width: c.maxWidth * f,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(colors: [cor, cor.withValues(alpha: 0.6)]),
              ),
            ),
          ),
          Positioned(
            left: c.maxWidth * (limite / escala).clamp(0, 1) - 1,
            top: -4,
            child: Column(children: [
              Container(width: 2, height: 20, color: Theme.of(context).colorScheme.onSurface),
              Text('${minimo ? 'mín' : 'máx'} ${limite.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.labelSmall),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SerieLrf extends StatelessWidget {
  const _SerieLrf({required this.lrf});
  final List<Map<String, dynamic>> lrf;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pts = lrf.where((r) => r.numOuNulo('pessoalPercentual') != null).toList();
    if (pts.length < 2) return const SizedBox.shrink();
    final lim = pts.last.num_('limiteMaximo', 54);
    final alerta = pts.last.num_('limiteAlerta', 48.6);
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gasto com pessoal ao longo dos anos', style: tt.titleMedium),
          Text('% da receita corrente líquida · linhas: alerta ${alerta.toStringAsFixed(1)}% e máximo ${lim.toStringAsFixed(0)}%', style: tt.bodySmall),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: LineChart(
              duration: const Duration(milliseconds: 600),
              LineChartData(
                minY: 30,
                maxY: 60,
                gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Vidro.of(context).borda, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(y: lim, color: Cores.rosa, strokeWidth: 1.5, dashArray: [6, 4]),
                  HorizontalLine(y: alerta, color: Cores.amarelo, strokeWidth: 1.5, dashArray: [6, 4]),
                ]),
                lineTouchData: LineTouchData(
                  longPressDuration: const Duration(milliseconds: 220),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (s) => [for (final p in s) LineTooltipItem('${p.y.toStringAsFixed(1)}%', const TextStyle(fontWeight: FontWeight.w700))],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34, interval: 10, getTitlesWidget: (v, _) => Text('${v.round()}%', style: tt.labelSmall))),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i >= pts.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 6), child: Text("'${'${pts[i].int_('ano')}'.substring(2)}", style: tt.labelSmall));
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (final (i, r) in pts.indexed) FlSpot(i.toDouble(), r.num_('pessoalPercentual'))],
                    isCurved: true,
                    color: Cores.violeta,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Cores.violeta.withValues(alpha: 0.25), Cores.violeta.withValues(alpha: 0)]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
