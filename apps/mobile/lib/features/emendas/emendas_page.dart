import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fontes/fontes.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../data/providers.dart';
import '../../widgets/comuns.dart';

/// Emendas parlamentares: recursos que deputados/senadores destinam ao
/// município. São ~100 registros, então carregamos tudo e filtramos local.
class EmendasPage extends ConsumerStatefulWidget {
  const EmendasPage({super.key});

  @override
  ConsumerState<EmendasPage> createState() => _EmendasPageState();
}

class _EmendasPageState extends ConsumerState<EmendasPage> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final todas = ref.watch(todasEmendasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Emendas parlamentares')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por número ou ano (ex.: 2026)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _busca = v.trim()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(todasEmendasProvider.future),
              child: Async(
                valor: todas,
                aoTentarDeNovo: () => ref.invalidate(todasEmendasProvider),
                dado: (lista) {
                  final filtradas = _busca.isEmpty
                      ? lista
                      : lista
                          .where((e) => e.titulo
                              .toLowerCase()
                              .contains(_busca.toLowerCase()))
                          .toList();
                  if (filtradas.isEmpty) {
                    return const Mensagem(
                      icone: Icons.search_off,
                      titulo: 'Nenhuma emenda encontrada',
                    );
                  }
                  return _ListaAgrupada(emendas: filtradas);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Agrupa por ano (prefixo do número: "Emenda nº 2026.71250001").
class _ListaAgrupada extends StatelessWidget {
  const _ListaAgrupada({required this.emendas});
  final List<EmendaResumo> emendas;

  static final _ano = RegExp(r'(\d{4})\.');

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<EmendaResumo>>{};
    for (final e in emendas) {
      final ano = _ano.firstMatch(e.titulo)?.group(1) ?? 'Outros';
      grupos.putIfAbsent(ano, () => []).add(e);
    }
    final anos = grupos.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final ano in anos) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '$ano · ${grupos[ano]!.length} emendas',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final e in grupos[ano]!)
            ListTile(
              leading: Icon(
                e.slug.endsWith('recurso-nao-liberado')
                    ? Icons.hourglass_empty
                    : Icons.account_balance_outlined,
              ),
              title: Text(e.titulo),
              subtitle: Text(
                [
                  if (e.publicadoEm != null)
                    'Publicada em ${dataBr(e.publicadoEm)}',
                  if (e.slug.endsWith('recurso-nao-liberado'))
                    'Recurso não liberado',
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(Rotas.emenda(e.slug)),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${emendas.length} emendas · fonte: www.saojoao.sp.gov.br',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
