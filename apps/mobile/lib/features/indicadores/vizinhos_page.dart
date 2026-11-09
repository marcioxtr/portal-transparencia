import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// Cidades vizinhas lado a lado: receita e gasto por habitante no último ano
/// fechado. Mesma fonte (TCE-SP) e mesmo método para todas — comparação justa.
class VizinhosPage extends ConsumerStatefulWidget {
  const VizinhosPage({super.key});

  @override
  ConsumerState<VizinhosPage> createState() => _VizinhosPageState();
}

class _VizinhosPageState extends ConsumerState<VizinhosPage> {
  bool _gasto = true;

  @override
  Widget build(BuildContext context) {
    final dados = ref.watch(dadosProvider('indicadores'));
    return Scaffold(
      appBar: AppBar(title: const Text('Cidades vizinhas')),
      body: Async(
        valor: dados,
        aoTentarDeNovo: () => ref.invalidate(dadosProvider('indicadores')),
        dado: (j) {
          final viz = j.mapa('vizinhos');
          final ano = viz.int_('ano');
          final municipios = viz.lista('municipios').where((m) => m.numOuNulo('populacao') != null).toList();
          if (municipios.isEmpty) {
            return const Mensagem(
              icone: Icons.location_city_outlined,
              titulo: 'Comparativo ainda não disponível',
              texto: 'Os dados das cidades vizinhas são coletados do TCE-SP e podem levar um dia para aparecer.',
            );
          }
          final chave = _gasto ? 'pagoPorHabitante' : 'receitaPorHabitante';
          final ordenados = [...municipios]..sort((a, b) => b.num_(chave).compareTo(a.num_(chave)));
          final maior = ordenados.first.num_(chave);
          final tt = Theme.of(context).textTheme;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              Aparecer(
                child: Text('Por habitante, $ano · mesma régua para todas as cidades', style: tt.titleMedium),
              ),
              const SizedBox(height: 12),
              Aparecer(
                indice: 1,
                child: Wrap(spacing: 8, runSpacing: 8,children: [
                  PilulaVidro(
                    rotulo: 'Gasto (pago)',
                    icone: Icons.north_east_rounded,
                    selecionada: _gasto,
                    cor: Cores.despesa,
                    onTap: () => setState(() => _gasto = true),
                  ),
                  const SizedBox(width: 8),
                  PilulaVidro(
                    rotulo: 'Arrecadação',
                    icone: Icons.south_west_rounded,
                    selecionada: !_gasto,
                    cor: Cores.receita,
                    onTap: () => setState(() => _gasto = false),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Aparecer(
                indice: 2,
                child: CartaoVidro(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, m) in ordenados.indexed)
                        BarraProporcao(
                          rotulo: '${m.bool_('eSjbv') ? '★ ' : ''}${m.str('nome')}',
                          valor: reais((m.num_(chave) * 100).round()),
                          sub: '${_formatarPop(m.int_('populacao'))} habitantes · total ${reaisCurto(((_gasto ? m.num_('pago') : m.num_('receita')) * 100).round())}',
                          proporcao: maior == 0 ? 0 : m.num_(chave) / maior,
                          cor: m.bool_('eSjbv') ? Cores.primaria : Cores.serie(i).withValues(alpha: 0.75),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Aparecer(
                indice: 3,
                child: Aviso(
                  'Cidades menores costumam ter valores por habitante maiores: custos fixos se dividem por menos gente. '
                  'Use como referência, não como ranking.',
                  icone: Icons.balance_outlined,
                ),
              ),
              const SizedBox(height: 14),
              Aparecer(
                indice: 4,
                child: CardProcedencia(
                  url: Uri.parse('https://transparencia.tce.sp.gov.br/'),
                  obtidoEm: geradoEm(j),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatarPop(int p) {
    final s = p.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}
