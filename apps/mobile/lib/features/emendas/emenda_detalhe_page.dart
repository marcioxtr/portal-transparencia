import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fontes/fontes.dart';

import '../../data/providers.dart';
import '../../widgets/comuns.dart';

class EmendaDetalhePage extends ConsumerWidget {
  const EmendaDetalhePage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emenda = ref.watch(emendaProvider(slug));
    final fonte = ref.watch(fontePrefeituraProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Emenda parlamentar')),
      body: Async(
        valor: emenda,
        aoTentarDeNovo: () => ref.invalidate(emendaProvider(slug)),
        dado: (e) => _Detalhe(e: e, urlFonte: fonte.urlEmenda(slug)),
      ),
    );
  }
}

class _Detalhe extends StatelessWidget {
  const _Detalhe({required this.e, required this.urlFonte});
  final Emenda e;
  final Uri urlFonte;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final naoLiberado = e.slug.endsWith('recurso-nao-liberado');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(e.titulo, style: tt.headlineSmall),
        const SizedBox(height: 12),
        if (naoLiberado) ...[
          const Aviso(
            'Recurso ainda não liberado: a emenda foi indicada, mas o '
            'dinheiro não chegou ao município.',
            icone: Icons.hourglass_empty,
          ),
          const SizedBox(height: 12),
        ],
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor da emenda',
                    style: tt.labelLarge
                        ?.copyWith(color: cs.onPrimaryContainer)),
                Text(reais(e.valorCentavos),
                    style: tt.headlineMedium
                        ?.copyWith(color: cs.onPrimaryContainer)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Campo('Para quê', e.objetivo),
        Campo('Quem recebe', e.beneficiario),
        Campo('Área (função de governo)', e.funcaoGoverno),
        const Divider(height: 24),
        Campo('Autoria', e.autoria),
        Campo('Tipo de emenda', e.tipo),
        Campo('Origem do recurso', e.origemRecurso),
        Campo('Forma de repasse', e.formaRepasse),
        Campo('Número', e.numero),
        for (final x in e.camposExtras.entries) Campo(x.key, x.value),
        const SizedBox(height: 24),
        CardProcedencia(url: urlFonte),
      ],
    );
  }
}
