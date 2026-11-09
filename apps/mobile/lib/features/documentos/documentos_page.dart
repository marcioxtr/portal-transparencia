import 'package:flutter/material.dart';
import 'package:fontes/fontes.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../widgets/botao_menu.dart';
import '../../widgets/comuns.dart';

/// Documentos históricos (Transparência até 2022): catálogo de pastas do
/// file-browser eCrie, agrupado por categoria.
class DocumentosPage extends StatelessWidget {
  const DocumentosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categorias = <String, List<PastaLegado>>{};
    for (final p in pastasLegado) {
      categorias.putIfAbsent(p.categoria, () => []).add(p);
    }
    return Scaffold(
      appBar: AppBar(leading: const BotaoMenu(), title: const Text('Documentos')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Aviso(
              'Balancetes, balanços, folha de pagamento e relatórios '
              'publicados em PDF pela Prefeitura — principalmente de 2012 '
              'a 2022. Para dados de 2026 em diante, use as outras abas.',
              icone: Icons.folder_open_outlined,
            ),
          ),
          for (final cat in categorias.keys) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(cat, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final p in categorias[cat]!)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(p.titulo),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(Rotas.pasta(p.id)),
              ),
          ],
        ],
      ),
    );
  }
}
