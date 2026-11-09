import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// "O que mudou": receitas que surgiram ou sumiram, fornecedores que entraram
/// ou saíram do topo, áreas que mais cresceram ou caíram. Calculado pelos
/// coletores a partir dos dados do TCE-SP; nenhum texto escrito à mão.
class MudancasPage extends ConsumerWidget {
  const MudancasPage({super.key});

  static const _tipos = <String, (String, IconData, Color)>{
    'receita_nova': ('Nova fonte de receita', Icons.add_circle_outline, Cores.verde),
    'receita_sumiu': ('Receita que deixou de existir', Icons.remove_circle_outline, Cores.rosa),
    'receita_variou': ('Receita que variou muito', Icons.swap_vert_rounded, Cores.azulCeu),
    'fornecedor_novo': ('Novo entre os maiores fornecedores', Icons.business_outlined, Cores.violeta),
    'fornecedor_saiu': ('Saiu dos maiores fornecedores', Icons.business_outlined, Cores.laranja),
    'area_cresceu': ('Área que mais cresceu', Icons.trending_up_rounded, Cores.verde),
    'area_caiu': ('Área que mais caiu', Icons.trending_down_rounded, Cores.rosa),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dados = ref.watch(dadosProvider('indicadores'));
    return Scaffold(
      appBar: AppBar(title: const Text('O que mudou')),
      body: Async(
        valor: dados,
        aoTentarDeNovo: () => ref.invalidate(dadosProvider('indicadores')),
        dado: (j) {
          final mudancas = j.lista('mudancas');
          if (mudancas.isEmpty) {
            return const Mensagem(
              icone: Icons.compare_arrows_rounded,
              titulo: 'Sem mudanças relevantes detectadas',
              texto: 'Comparamos o último ano fechado com o anterior e o ano em curso com o mesmo período do ano passado.',
            );
          }
          final grupos = <String, List<Map<String, dynamic>>>{};
          for (final m in mudancas) {
            grupos.putIfAbsent(m.str('tipo'), () => []).add(m);
          }
          final ordem = _tipos.keys.where(grupos.containsKey).toList();
          var i = 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              Aparecer(
                child: Text(
                  'Comparações automáticas entre anos: o que apareceu, o que sumiu e o que variou mais.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 14),
              for (final tipo in ordem) ...[
                Aparecer(
                  indice: ++i,
                  child: _Grupo(
                    titulo: _tipos[tipo]!.$1,
                    icone: _tipos[tipo]!.$2,
                    cor: _tipos[tipo]!.$3,
                    itens: grupos[tipo]!,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Aparecer(
                indice: ++i,
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

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.icone, required this.cor, required this.itens});
  final String titulo;
  final IconData icone;
  final Color cor;
  final List<Map<String, dynamic>> itens;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return CartaoVidro(
      cor: cor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icone, color: cor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(titulo, style: tt.titleMedium)),
          ]),
          const SizedBox(height: 8),
          for (final (k, m) in itens.indexed) ...[
            if (k > 0) const Divider(),
            _Item(m: m, cor: cor),
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.m, required this.cor});
  final Map<String, dynamic> m;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final variacao = m.numOuNulo('variacao');
    final antes = m.num_('valorAntes');
    final depois = m.num_('valorDepois');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.str('titulo'), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(m.str('descricao'), style: tt.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Valor(rotulo: m.str('de'), valor: antes)),
              Icon(Icons.arrow_forward_rounded, size: 18, color: Theme.of(context).colorScheme.outline),
              Expanded(child: _Valor(rotulo: m.str('para'), valor: depois, destaque: true, cor: cor)),
              if (variacao != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (variacao >= 0 ? Cores.verde : Cores.rosa).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${variacao >= 0 ? '+' : ''}${variacao.toStringAsFixed(1)}%',
                    style: tt.labelMedium?.copyWith(color: variacao >= 0 ? Cores.verde : Cores.rosa, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor({required this.rotulo, required this.valor, this.destaque = false, this.cor});
  final String rotulo;
  final double valor;
  final bool destaque;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          reaisCurto((valor * 100).round()),
          style: (destaque ? tt.titleMedium : tt.bodyMedium)?.copyWith(color: destaque ? cor : null, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
