import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fontes/fontes.dart';

import '../../data/providers.dart';
import '../../widgets/comuns.dart';

class ContratoDetalhePage extends ConsumerWidget {
  const ContratoDetalhePage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contrato = ref.watch(contratoProvider(id));
    final fonte = ref.watch(fontePrefeituraProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contrato')),
      body: Async(
        valor: contrato,
        aoTentarDeNovo: () => ref.invalidate(contratoProvider(id)),
        dado: (c) => _Detalhe(c: c, urlFonte: fonte.urlContrato(id)),
      ),
    );
  }
}

class _Detalhe extends StatelessWidget {
  const _Detalhe({required this.c, required this.urlFonte});
  final Contrato c;
  final Uri urlFonte;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final vigente = c.dataFim != null && c.dataFim!.isAfter(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(c.titulo, style: tt.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (c.ano != null) Chip(label: Text('${c.ano}')),
            if (c.dataFim != null)
              Chip(
                avatar: Icon(
                  vigente ? Icons.check_circle : Icons.history,
                  size: 18,
                ),
                label: Text(vigente ? 'Vigente' : 'Encerrado'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Valor em destaque — é o que a pessoa quer saber primeiro.
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor',
                    style: tt.labelLarge
                        ?.copyWith(color: cs.onPrimaryContainer)),
                Text(reais(c.valorCentavos),
                    style: tt.headlineMedium
                        ?.copyWith(color: cs.onPrimaryContainer)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Campo('O que foi contratado', c.objeto),
        Campo('Contratado', c.contratado),
        Campo('CPF/CNPJ', c.cpfCnpj),
        Campo('Licitação', c.licitacao),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(child: Campo('Assinatura', dataBr(c.dataAssinatura))),
            Expanded(child: Campo('Início', dataBr(c.dataInicio))),
            Expanded(child: Campo('Fim', dataBr(c.dataFim))),
          ],
        ),
        for (final e in c.camposExtras.entries) Campo(e.key, e.value),
        const SizedBox(height: 16),
        if (c.urlDocumento != null)
          FilledButton.icon(
            onPressed: () => abrirUrl(c.urlDocumento!),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Abrir documento (PDF)'),
          ),
        const SizedBox(height: 24),
        CardProcedencia(url: urlFonte),
      ],
    );
  }
}
