import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../app/tema.dart';
import '../../data/painel.dart';
import '../../data/dados_remotos.dart';
import '../../data/providers.dart';
import '../../widgets/botao_menu.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../glossario/glossario_page.dart' show abrirTermo;

const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

/// Tela inicial: o painel que responde "para onde vai o dinheiro?".
class PainelPage extends ConsumerWidget {
  const PainelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ano = ref.watch(anoPainelProvider);
    final painel = ref.watch(painelProvider(ano));
    final anos = ref.watch(anosPainelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BotaoMenu(),
        titleSpacing: 0,
        title: Row(
          children: [
            SvgPicture.asset('assets/logo/logo.svg', height: 28),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('Tô de Olho', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'O que significa cada termo?',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.push(Rotas.glossario),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(painelProvider(ano).future),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Aparecer(
                      child: Text('Para onde vai o dinheiro de\nSão João da Boa Vista?',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    const SizedBox(height: 14),
                    Aparecer(
                      indice: 1,
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: anos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => PilulaVidro(
                            rotulo: '${anos[i]}',
                            selecionada: anos[i] == ano,
                            onTap: () => ref.read(anoPainelProvider.notifier).definir(anos[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            painel.when(
              skipLoadingOnRefresh: true,
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(children: const [
                  Esqueleto(altura: 190),
                  SizedBox(height: 14),
                  Esqueleto(altura: 220),
                  SizedBox(height: 14),
                  Esqueleto(altura: 260),
                ]),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Mensagem(
                  icone: Icons.hourglass_empty_rounded,
                  titulo: e is PainelIndisponivel ? 'Ano ainda não disponível' : 'Não foi possível carregar',
                  texto: e is PainelIndisponivel
                      ? 'Os dados oficiais de ${e.ano} ainda não foram agregados. Escolha outro ano acima.'
                      : 'Verifique sua conexão e tente de novo.',
                  acao: () => ref.invalidate(painelProvider(ano)),
                ),
              ),
              data: (p) => _Corpo(p: p),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corpo extends ConsumerWidget {
  const _Corpo({required this.p});
  final Painel p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final parcial = p.meses.length < 12;
    final itens = <Widget>[
      _Resumo(p: p, parcial: parcial),
      const _Atalhos(),
      _Mensal(p: p),
      _DeOndeVem(p: p),
      _ParaOndeVai(p: p),
      _QuemRecebe(p: p),
      _Orgaos(p: p),
      const _Historico(),
      CartaoVidro(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.verified_outlined, size: 20),
              const SizedBox(width: 8),
              Text('Procedência', style: tt.titleMedium),
            ]),
            const SizedBox(height: 8),
            Text(
              'Lançamentos do Tribunal de Contas do Estado (TCE-SP), consolidados por este '
              'projeto${p.geradoEm != null ? ' em ${dataHoraBr(p.geradoEm!.toLocal())}' : ''}. '
              '${p.fonteSiconfi != null ? 'Despesa por área: ${p.fonteSiconfi} (Tesouro Nacional). ' : ''}'
              'População: ${p.populacao ?? '—'} (IBGE via SICONFI). Valores de "Prefeitura" '
              'incluem todos os órgãos: Prefeitura, Câmara, Previdência (IPSJBV) e FAE.',
              style: tt.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              ActionChip(
                avatar: const Icon(Icons.open_in_new, size: 16),
                label: const Text('TCE-SP'),
                onPressed: () => abrirUrl(Uri.parse(
                    'https://transparencia.tce.sp.gov.br/municipio/sao-joao-da-boa-vista')),
              ),
              ActionChip(
                avatar: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Portal oficial'),
                onPressed: () => abrirUrl(Uri.parse('https://www.saojoao.sp.gov.br/transparencia')),
              ),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 90),
    ];
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverList.separated(
        itemCount: itens.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => Aparecer(indice: i + 2, child: itens[i]),
      ),
    );
  }
}

// ── Resumo ─────────────────────────────────────────────────────────────────

class _Resumo extends StatelessWidget {
  const _Resumo({required this.p, required this.parcial});
  final Painel p;
  final bool parcial;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final saldo = p.receitaTotal - p.pago;
    final porHab = p.porHabitante(p.pago);
    return CartaoVidro(
      forte: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('${p.ano}', style: tt.titleLarge),
            const SizedBox(width: 8),
            if (parcial)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Cores.amarelo.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('até ${_meses[p.meses.last - 1]}', style: tt.labelSmall),
              ),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Kpi(
                  rotulo: 'Entrou',
                  valor: p.receitaTotal,
                  cor: Cores.receita,
                  icone: Icons.south_west_rounded,
                  termo: 'receita',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Kpi(
                  rotulo: 'Saiu (pago)',
                  valor: p.pago,
                  cor: Cores.despesa,
                  icone: Icons.north_east_rounded,
                  termo: 'pago',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BarraDupla(receita: p.receitaTotal, empenhado: p.empenhado, pago: p.pago),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Etiqueta(
                icone: Icons.assignment_outlined,
                texto: 'Comprometido (empenhado): ${reaisCurto((p.empenhado * 100).round())}',
                termo: 'empenho',
              ),
              _Etiqueta(
                icone: saldo >= 0 ? Icons.savings_outlined : Icons.warning_amber_rounded,
                texto: saldo >= 0
                    ? 'Sobrou em caixa: ${reaisCurto((saldo * 100).round())}'
                    : 'Pagou mais do que arrecadou: ${reaisCurto((-saldo * 100).round())}',
              ),
              if (porHab != null)
                _Etiqueta(
                  icone: Icons.person_outline,
                  texto: 'Gasto por morador: ${reais((porHab * 100).round())}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.rotulo, required this.valor, required this.cor, required this.icone, this.termo});
  final String rotulo;
  final double valor;
  final Color cor;
  final IconData icone;
  final String? termo;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: termo == null ? null : () => abrirTermo(context, termo!),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icone, size: 14, color: cor),
            ),
            const SizedBox(width: 6),
            Flexible(child: Text(rotulo, style: tt.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          NumeroAnimado(
            valor: valor,
            formatar: (v) => reaisCurto((v * 100).round()),
            estilo: tt.headlineSmall?.copyWith(color: cor),
          ),
        ],
      ),
    );
  }
}

class _BarraDupla extends StatelessWidget {
  const _BarraDupla({required this.receita, required this.empenhado, required this.pago});
  final double receita, empenhado, pago;

  @override
  Widget build(BuildContext context) {
    final max = [receita, empenhado, pago].reduce((a, b) => a > b ? a : b);
    Widget linha(String r, double v, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 92, child: Text(r, style: Theme.of(context).textTheme.labelMedium)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(children: [
                  Container(height: 10, color: Vidro.of(context).superficie),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: max == 0 ? 0 : v / max),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, f, __) => FractionallySizedBox(
                      widthFactor: f,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [c, c.withValues(alpha: 0.6)]),
                          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
    return Column(children: [
      linha('Arrecadado', receita, Cores.receita),
      linha('Empenhado', empenhado, Cores.laranja),
      linha('Pago', pago, Cores.despesa),
    ]);
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icone, required this.texto, this.termo});
  final IconData icone;
  final String texto;
  final String? termo;

  @override
  Widget build(BuildContext context) {
    final v = Vidro.of(context);
    return InkWell(
      onTap: termo == null ? null : () => abrirTermo(context, termo!),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: v.superficie,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: v.borda),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 14),
          const SizedBox(width: 6),
          Flexible(child: Text(texto, style: Theme.of(context).textTheme.labelMedium, softWrap: true)),
          if (termo != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 12, color: Theme.of(context).colorScheme.outline),
          ],
        ]),
      ),
    );
  }
}

// ── Atalhos para as outras seções ──────────────────────────────────────────

class _Atalhos extends StatelessWidget {
  const _Atalhos();

  @override
  Widget build(BuildContext context) {
    final itens = <(IconData, String, String, Color, String)>[
      (Icons.construction_outlined, 'Obras', 'no mapa, com % pago', Cores.laranja, Rotas.obras),
      (Icons.how_to_vote_outlined, 'Câmara', 'vereadores e votos', Cores.violeta, Rotas.camara),
      (Icons.compare_arrows_rounded, 'Comparar', 'anos e mandatos', Cores.azulCeu, Rotas.comparar),
      (Icons.traffic_rounded, 'Limites da lei', 'saúde, educação, pessoal', Cores.verde, Rotas.indicadores),
      (Icons.campaign_outlined, 'Avisos', 'trânsito, coleta, eventos', Cores.rosa, Rotas.avisos),
      (Icons.change_circle_outlined, 'O que mudou', 'de um ano pro outro', Cores.amarelo, Rotas.mudancas),
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itens.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (icone, titulo, sub, cor, rota) = itens[i];
          return SizedBox(
            width: 150,
            child: CartaoVidro(
              padding: const EdgeInsets.all(14),
              raio: 22,
              cor: cor,
              onTap: () => context.push(rota),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icone, color: cor, size: 24),
                  const Spacer(),
                  Text(titulo, style: Theme.of(context).textTheme.titleSmall),
                  Text(sub, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Mensal ─────────────────────────────────────────────────────────────────

class _Mensal extends StatelessWidget {
  const _Mensal({required this.p});
  final Painel p;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final meses = p.porMes;
    if (meses.length < 2) return const SizedBox.shrink();
    final maxY = meses.fold<double>(0, (m, e) => [m, e.receita, e.empenhado, e.pago].reduce((a, b) => a > b ? a : b));

    LineChartBarData serie(double Function(MesFinanceiro) f, Color c) => LineChartBarData(
          spots: [for (final m in meses) FlSpot(m.mes.toDouble(), f(m) / 1e6)],
          isCurved: true,
          curveSmoothness: 0.3,
          color: c,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0)],
            ),
          ),
        );

    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mês a mês', style: tt.titleMedium),
          Text('em milhões de reais', style: tt.bodySmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              duration: const Duration(milliseconds: 700),
              LineChartData(
                minY: 0,
                maxY: (maxY / 1e6) * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Vidro.of(context).borda, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, _) => Text('${v.round()}', style: tt.labelSmall),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_meses[(v.round() - 1).clamp(0, 11)], style: tt.labelSmall),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  // Só reage a toque longo: deixa a rolagem da página passar.
                  longPressDuration: const Duration(milliseconds: 220),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${reaisCurto((s.y * 1e6 * 100).round())}\n',
                          TextStyle(color: s.bar.color, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  serie((m) => m.receita, Cores.receita),
                  serie((m) => m.empenhado, Cores.laranja),
                  serie((m) => m.pago, Cores.despesa),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 14, children: const [
            _Legenda(Cores.receita, 'Arrecadado'),
            _Legenda(Cores.laranja, 'Empenhado'),
            _Legenda(Cores.despesa, 'Pago'),
          ]),
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

// ── De onde vem ────────────────────────────────────────────────────────────

class _DeOndeVem extends StatelessWidget {
  const _DeOndeVem({required this.p});
  final Painel p;

  @override
  Widget build(BuildContext context) {
    final cats = p.receitasPorCategoria;
    final total = p.receitaTotal;
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('De onde vem o dinheiro',
              subtitulo: 'toque numa linha para entender', acao: () => _todasCategorias(context, cats, total), rotuloAcao: 'Todas'),
          for (final (i, c) in cats.take(7).indexed)
            BarraProporcao(
              rotulo: c.nome,
              valor: reaisCurto((c.valor * 100).round()),
              sub: '${(c.valor / total * 100).toStringAsFixed(1)}% do total',
              proporcao: c.valor / cats.first.valor,
              cor: Cores.serie(i),
              onTap: () => _explicar(context, c),
            ),
        ],
      ),
    );
  }

  void _explicar(BuildContext context, CategoriaReceita c) {
    final porHab = p.porHabitante(c.valor);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.nome, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(c.explicacao, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('${reais((c.valor * 100).round())} em ${p.ano}'
                '${porHab != null ? ' · ${reais((porHab * 100).round())} por morador' : ''}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${(c.valor / p.receitaTotal * 100).toStringAsFixed(1)}% de tudo que o município arrecadou.',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _todasCategorias(BuildContext context, List<CategoriaReceita> cats, double total) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('Todas as fontes de receita', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            for (final (i, c) in cats.indexed)
              BarraProporcao(
                rotulo: c.nome,
                valor: reaisCurto((c.valor * 100).round()),
                sub: c.explicacao,
                proporcao: c.valor / cats.first.valor,
                cor: Cores.serie(i),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Para onde vai ──────────────────────────────────────────────────────────

class _ParaOndeVai extends StatefulWidget {
  const _ParaOndeVai({required this.p});
  final Painel p;

  @override
  State<_ParaOndeVai> createState() => _ParaOndeVaiState();
}

class _ParaOndeVaiState extends State<_ParaOndeVai> {
  int? _tocado;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final funcoes = widget.p.despesasPorFuncao;
    if (funcoes.isEmpty) {
      return CartaoVidro(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Para onde vai', style: tt.titleLarge),
          const SizedBox(height: 8),
          const Aviso('O detalhamento por área (saúde, educação…) ainda não foi publicado no SICONFI para este ano.'),
        ]),
      );
    }
    final total = funcoes.fold<double>(0, (s, f) => s + f.empenhado);
    final top = funcoes.take(6).toList();
    final outras = funcoes.skip(6).fold<double>(0, (s, f) => s + f.empenhado);

    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Para onde vai', subtitulo: 'por área de governo · valores empenhados'),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: PieChart(
                  duration: const Duration(milliseconds: 600),
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 42,
                    pieTouchData: PieTouchData(
                      longPressDuration: const Duration(milliseconds: 220),
                      touchCallback: (e, r) => setState(() => _tocado = r?.touchedSection?.touchedSectionIndex),
                    ),
                    sections: [
                      for (final (i, f) in top.indexed)
                        PieChartSectionData(
                          value: f.empenhado,
                          color: Cores.serie(i),
                          radius: _tocado == i ? 30 : 22,
                          showTitle: false,
                        ),
                      if (outras > 0)
                        PieChartSectionData(
                          value: outras,
                          color: Theme.of(context).colorScheme.outline,
                          radius: _tocado == top.length ? 30 : 22,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, f) in top.indexed)
                      InkWell(
                        onTap: () => _detalhe(context, f, total),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: Cores.serie(i), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f.nome, style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('${(f.empenhado / total * 100).toStringAsFixed(0)}%', style: tt.labelLarge),
                          ]),
                        ),
                      ),
                    if (outras > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Outras áreas', style: tt.bodyMedium)),
                          Text('${(outras / total * 100).toStringAsFixed(0)}%', style: tt.labelLarge),
                        ]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _todas(context, funcoes, total),
            icon: const Icon(Icons.list_rounded, size: 18),
            label: const Text('Ver todas as áreas'),
          ),
        ],
      ),
    );
  }

  void _detalhe(BuildContext context, Funcao f, double total) {
    final p = widget.p;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.nome, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Campo('Empenhado em ${p.ano}', reais((f.empenhado * 100).round())),
            if (f.liquidado != null) Campo('Liquidado', reais((f.liquidado! * 100).round())),
            if (f.pago != null) Campo('Pago', reais((f.pago! * 100).round())),
            Campo('Fatia do total', '${(f.empenhado / total * 100).toStringAsFixed(1)}%'),
            if (p.populacao != null) Campo('Por morador', reais((f.empenhado / p.populacao! * 100).round())),
            const SizedBox(height: 8),
            Text(_explicacaoFuncao(f.codigo), style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _todas(BuildContext context, List<Funcao> funcoes, double total) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('Todas as áreas de governo', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            for (final (i, f) in funcoes.indexed)
              BarraProporcao(
                rotulo: f.nome,
                valor: reaisCurto((f.empenhado * 100).round()),
                sub: '${(f.empenhado / total * 100).toStringAsFixed(1)}% · ${_explicacaoFuncao(f.codigo)}',
                proporcao: f.empenhado / funcoes.first.empenhado,
                cor: Cores.serie(i),
              ),
          ],
        ),
      ),
    );
  }
}

String _explicacaoFuncao(String codigo) => switch (codigo) {
      '10' => 'Hospitais, postos, remédios, SUS municipal. A Constituição exige no mínimo 15% da receita de impostos.',
      '12' => 'Escolas, creches, merenda, professores. Mínimo constitucional: 25% da receita de impostos.',
      '09' => 'Aposentadorias e pensões dos servidores municipais (instituto de previdência próprio).',
      '04' => 'A máquina administrativa: pessoal de apoio, prédios, sistemas, finanças.',
      '15' => 'Ruas, praças, asfalto, drenagem, planejamento urbano.',
      '08' => 'CRAS, CREAS, programas sociais, conselho tutelar.',
      '28' => 'Dívidas, precatórios e outros encargos que não cabem em uma área específica.',
      '17' => 'Água, esgoto e coleta/destinação de lixo.',
      '26' => 'Transporte coletivo, estradas vicinais, terminais.',
      '27' => 'Esporte e lazer: quadras, ginásios, eventos.',
      '13' => 'Cultura: teatro, bibliotecas, eventos, patrimônio histórico.',
      '06' => 'Guarda municipal, trânsito, defesa civil.',
      '18' => 'Meio ambiente: áreas verdes, licenciamento, bem-estar animal.',
      '16' => 'Habitação popular e regularização fundiária.',
      '20' => 'Agricultura e abastecimento.',
      '01' => 'A Câmara Municipal — vereadores e sua estrutura.',
      '23' => 'Desenvolvimento econômico, turismo, comércio e serviços.',
      _ => 'Classificação oficial de despesa por função de governo (Portaria MOG 42/1999).',
    };

// ── Quem recebe ────────────────────────────────────────────────────────────

class _QuemRecebe extends ConsumerStatefulWidget {
  const _QuemRecebe({required this.p});
  final Painel p;

  @override
  ConsumerState<_QuemRecebe> createState() => _QuemRecebeState();
}

class _QuemRecebeState extends ConsumerState<_QuemRecebe> {
  bool _incluirInternos = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final lista = widget.p.topFornecedores.where((f) => _incluirInternos || !f.interno).take(8).toList();
    if (lista.isEmpty) return const SizedBox.shrink();
    final maior = lista.first.empenhado;

    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Quem mais recebeu', subtitulo: 'empresas e entidades · empenhado no ano'),
          for (final (i, f) in lista.indexed)
            BarraProporcao(
              rotulo: _titulo(f.nome),
              valor: reaisCurto((f.empenhado * 100).round()),
              sub: f.interno ? 'repasse interno · ${_curto(f.orgao)}' : _curto(f.orgao),
              proporcao: f.empenhado / maior,
              cor: Cores.serie(i),
              onTap: () => _detalhe(context, f),
            ),
          const SizedBox(height: 6),
          Row(children: [
            Switch.adaptive(
              value: _incluirInternos,
              onChanged: (v) => setState(() => _incluirInternos = v),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text('Incluir folha, previdência e repasses entre órgãos', style: tt.bodySmall)),
          ]),
        ],
      ),
    );
  }

  void _detalhe(BuildContext context, Fornecedor f) {
    final p = widget.p;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titulo(f.nome), style: Theme.of(context).textTheme.headlineSmall),
            if (f.documento != null) Text(_formatarDoc(f.documento!), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Campo('Empenhado em ${p.ano}', reais((f.empenhado * 100).round())),
            Campo('Pago em ${p.ano}', reais((f.pago * 100).round())),
            Campo('Órgão pagador', _curto(f.orgao)),
            if (p.populacao != null) Campo('Por morador', reais((f.empenhado / p.populacao! * 100).round())),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(filtroContratosProvider.notifier).definir(FiltroContratos(razaoSocial: _palavraChave(f.nome)));
                  context.go(Rotas.contratos);
                },
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Ver contratos'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(Rotas.cobrar, extra: 'Gostaria de receber a relação de empenhos, notas fiscais e '
                      'contratos referentes a ${_titulo(f.nome)} no exercício de ${p.ano}, cujo total empenhado, '
                      'segundo o TCE-SP, foi de ${reais((f.empenhado * 100).round())}.');
                },
                icon: const Icon(Icons.record_voice_over_outlined, size: 18),
                label: const Text('Pedir explicação'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Órgãos ─────────────────────────────────────────────────────────────────

class _Orgaos extends StatelessWidget {
  const _Orgaos({required this.p});
  final Painel p;

  @override
  Widget build(BuildContext context) {
    final orgaos = p.porOrgao;
    if (orgaos.isEmpty) return const SizedBox.shrink();
    final total = orgaos.fold<double>(0, (s, o) => s + o.$2);
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Por órgão', subtitulo: 'quem executa o gasto'),
          for (final (i, o) in orgaos.indexed)
            BarraProporcao(
              rotulo: _curto(o.$1),
              valor: reaisCurto((o.$2 * 100).round()),
              sub: '${(o.$2 / total * 100).toStringAsFixed(1)}%',
              proporcao: o.$2 / orgaos.first.$2,
              cor: Cores.serie(i),
            ),
        ],
      ),
    );
  }
}

// ── Histórico 2014→hoje (dados/indicadores.json) ───────────────────────────

class _Historico extends ConsumerWidget {
  const _Historico();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final dados = ref.watch(dadosProvider('indicadores'));
    return dados.maybeWhen(
      data: (j) {
        final anos = j.lista('anos').where((a) => !a.bool_('parcial')).toList();
        if (anos.length < 3) return const SizedBox.shrink();
        final maxY = anos.fold<double>(0, (m, a) => [m, a.num_('receita'), a.num_('pago')].reduce((x, y) => x > y ? x : y)) / 1e6;
        return CartaoVidro(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TituloSecao('${anos.length} anos em um olhar',
                  subtitulo: 'arrecadado × pago, em milhões · toque num ano',
                  acao: () => context.push(Rotas.comparar),
                  rotuloAcao: 'Comparar'),
              SizedBox(
                height: 180,
                child: BarChart(
                  duration: const Duration(milliseconds: 600),
                  BarChartData(
                    maxY: maxY * 1.1,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(color: Vidro.of(context).borda, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (v, _) => Text('${v.round()}', style: tt.labelSmall),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text("'${v.round().toString().substring(2)}", style: tt.labelSmall),
                          ),
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      longPressDuration: const Duration(milliseconds: 220),
                      touchCallback: (e, r) {
                        if (e is FlTapUpEvent && r?.spot != null) {
                          ref.read(anoPainelProvider.notifier).definir(r!.spot!.touchedBarGroup.x);
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                          reaisCurto((rod.toY * 1e6 * 100).round()),
                          TextStyle(color: rod.color, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (final a in anos)
                        BarChartGroupData(
                          x: a.int_('ano'),
                          barsSpace: 2,
                          barRods: [
                            BarChartRodData(toY: a.num_('receita') / 1e6, color: Cores.receita, width: 6, borderRadius: BorderRadius.circular(3)),
                            BarChartRodData(toY: a.num_('pago') / 1e6, color: Cores.despesa, width: 6, borderRadius: BorderRadius.circular(3)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 14, children: const [
                _Legenda(Cores.receita, 'Arrecadado'),
                _Legenda(Cores.despesa, 'Pago'),
              ]),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── util ───────────────────────────────────────────────────────────────────

String _titulo(String s) {
  final minus = {'de', 'da', 'do', 'das', 'dos', 'e', 'em', 'a', 'o', 'para'};
  return s
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty || minus.contains(w) ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ')
      .trim();
}

String _curto(String orgao) {
  final o = orgao.toUpperCase();
  if (o.contains('CÂMARA') || o.contains('CAMARA')) return 'Câmara Municipal';
  if (o.contains('PREV')) return 'Previdência (IPSJBV)';
  if (o.contains('FAE') || o.contains('CENTRO UNIV')) return 'FAE (Centro Universitário)';
  if (o.contains('PREFEITURA')) return 'Prefeitura';
  return _titulo(orgao);
}

String _palavraChave(String nome) {
  final palavras = nome.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();
  return palavras.take(2).join(' ');
}

String _formatarDoc(String d) {
  if (d.length == 14) {
    return 'CNPJ ${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }
  if (d.length == 11) return 'CPF ***.${d.substring(3, 6)}.${d.substring(6, 9)}-**';
  return d;
}
