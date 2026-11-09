import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fontes/fontes.dart';

import '../../data/providers.dart';
import '../../widgets/comuns.dart';

/// Navegador de uma pasta do eCrie: árvore de subpastas (por ano) e PDFs.
class PastaPage extends ConsumerStatefulWidget {
  const PastaPage({super.key, required this.idPasta});
  final String idPasta;

  @override
  ConsumerState<PastaPage> createState() => _PastaPageState();
}

class _PastaPageState extends ConsumerState<PastaPage> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final pasta = pastasLegado.firstWhere((p) => p.id == widget.idPasta);
    final arvore = ref.watch(arvoreLegadoProvider(widget.idPasta));
    final fonte = ref.watch(fonteEcrieProvider);

    return Scaffold(
      appBar: AppBar(title: Text(pasta.titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar arquivo (ex.: 2019, dezembro)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _busca = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: Async(
              valor: arvore,
              aoTentarDeNovo: () =>
                  ref.invalidate(arvoreLegadoProvider(widget.idPasta)),
              dado: (raiz) => _busca.isEmpty
                  ? _Arvore(raiz: raiz, urlFonte: fonte.urlPasta(pasta.pasta))
                  : _Resultados(raiz: raiz, termo: _busca),
            ),
          ),
        ],
      ),
    );
  }
}

class _Arvore extends StatelessWidget {
  const _Arvore({required this.raiz, required this.urlFonte});
  final NoArquivo raiz;
  final Uri urlFonte;

  @override
  Widget build(BuildContext context) {
    final total = raiz.arquivos.length;
    if (total == 0) {
      return const Mensagem(
        icone: Icons.folder_off_outlined,
        titulo: 'Pasta vazia',
        texto: 'A Prefeitura ainda não publicou arquivos aqui.',
      );
    }
    // Pastas de ano mais recentes primeiro — é o que as pessoas procuram.
    final pastas = raiz.filhos.where((f) => !f.ehArquivo).toList().reversed;
    final soltos = raiz.filhos.where((f) => f.ehArquivo);
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final p in pastas) _Pasta(no: p),
        for (final a in soltos) _Arquivo(no: a),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('$total arquivos',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              CardProcedencia(url: urlFonte),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pasta extends StatelessWidget {
  const _Pasta({required this.no});
  final NoArquivo no;

  @override
  Widget build(BuildContext context) {
    final sub = no.filhos.where((f) => !f.ehArquivo).toList().reversed;
    final arqs = no.filhos.where((f) => f.ehArquivo);
    return ExpansionTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(no.nome),
      subtitle: Text('${no.arquivos.length} arquivos'),
      childrenPadding: const EdgeInsets.only(left: 12),
      children: [
        for (final p in sub) _Pasta(no: p),
        for (final a in arqs) _Arquivo(no: a),
      ],
    );
  }
}

class _Arquivo extends StatelessWidget {
  const _Arquivo({required this.no, this.mostrarCaminho = false});
  final NoArquivo no;
  final bool mostrarCaminho;

  @override
  Widget build(BuildContext context) {
    final icone = switch (no.extensao) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
      'txt' => Icons.notes_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
    return ListTile(
      leading: Icon(icone),
      title: Text(no.nome),
      subtitle: mostrarCaminho
          ? Text(no.caminho.split('/').skip(2).take(2).join(' / '))
          : null,
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => abrirUrl(no.url!),
    );
  }
}

class _Resultados extends StatelessWidget {
  const _Resultados({required this.raiz, required this.termo});
  final NoArquivo raiz;
  final String termo;

  @override
  Widget build(BuildContext context) {
    final achados = raiz.arquivos
        .where((a) => a.caminho.toLowerCase().contains(termo))
        .toList();
    if (achados.isEmpty) {
      return const Mensagem(
        icone: Icons.search_off,
        titulo: 'Nenhum arquivo com esse termo',
      );
    }
    return ListView.builder(
      itemCount: achados.length,
      itemBuilder: (_, i) => _Arquivo(no: achados[i], mostrarCaminho: true),
    );
  }
}
