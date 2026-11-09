import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../glossario/glossario_page.dart' show abrirTermo;

/// Conselhos municipais: o que são, próximas reuniões e como participar.
/// Fontes: `dados/servicos.json` (conselhos) e `dados/avisos.json` (reuniões).
class ConselhosPage extends ConsumerWidget {
  const ConselhosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicos = ref.watch(dadosProvider('servicos'));
    final avisos = ref.watch(dadosProvider('avisos'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conselhos municipais'),
        actions: [
          IconButton(
            tooltip: 'O que é um conselho?',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => abrirTermo(context, 'conselho'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dadosProvider('servicos'));
          ref.invalidate(dadosProvider('avisos'));
        },
        child: Async(
          valor: servicos,
          aoTentarDeNovo: () => ref.invalidate(dadosProvider('servicos')),
          dado: (j) => _Lista(
            conselhos: j.lista('conselhos'),
            reunioes: avisos.maybeWhen(data: (a) => a.lista('reunioesConselhos'), orElse: () => const []),
            geradoEm: geradoEm(j),
          ),
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.conselhos, required this.reunioes, required this.geradoEm});
  final List<Map<String, dynamic>> conselhos;
  final List<Map<String, dynamic>> reunioes;
  final DateTime? geradoEm;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);

    List<Map<String, dynamic>> reunioesDe(Map<String, dynamic> c) {
      final chaves = <String>{
        _norm(c.str('nome')),
        if (c.strOuNulo('sigla') != null) _norm(c.str('sigla')),
      }.where((k) => k.length >= 3).toList();
      return reunioes.where((r) {
        final alvo = _norm('${r.str('conselho')} ${r.str('titulo')}');
        return chaves.any((k) => alvo.contains(k));
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Aparecer(
          child: CartaoVidro(
            forte: true,
            cor: Cores.violeta,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Onde o cidadão decide junto', style: tt.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Cada conselho reúne moradores e governo para fiscalizar e aprovar políticas de uma área — '
                  'saúde, educação, criança, idoso, meio ambiente. As reuniões são abertas: você pode assistir, '
                  'falar e, em muitos deles, se candidatar a conselheiro.',
                  style: tt.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text('${conselhos.length} conselhos encontrados no site da Prefeitura', style: tt.labelMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, c) in conselhos.indexed) ...[
          Aparecer(
            indice: (i + 1).clamp(0, 10),
            child: _Conselho(c: c, reunioes: reunioesDe(c), inicioHoje: inicioHoje),
          ),
          const SizedBox(height: 10),
        ],
        CardProcedencia(url: Uri.parse('https://www.saojoao.sp.gov.br/conselhos-municipais'), obtidoEm: geradoEm),
      ],
    );
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâã]'), 'a')
      .replaceAll(RegExp(r'[éê]'), 'e')
      .replaceAll(RegExp(r'[í]'), 'i')
      .replaceAll(RegExp(r'[óôõ]'), 'o')
      .replaceAll(RegExp(r'[ú]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _Conselho extends StatelessWidget {
  const _Conselho({required this.c, required this.reunioes, required this.inicioHoje});
  final Map<String, dynamic> c;
  final List<Map<String, dynamic>> reunioes;
  final DateTime inicioHoje;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final proximas = reunioes.where((r) => (r.data('data') ?? DateTime(2000)).isAfter(inicioHoje.subtract(const Duration(days: 1)))).toList();
    final ultima = reunioes.isNotEmpty ? reunioes.first : null;
    final pubs = c.lista('publicacoes');

    return CartaoVidro(
      cor: Cores.violeta,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(c.str('nome'), style: tt.titleMedium)),
            if (c.strOuNulo('sigla') != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Cores.violeta.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                child: Text(c.str('sigla'), style: tt.labelSmall),
              ),
          ]),
          if (c.strOuNulo('descricao') != null) ...[
            const SizedBox(height: 4),
            Text(c.str('descricao'), style: tt.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          if (proximas.isNotEmpty)
            for (final r in proximas.take(2))
              _LinhaReuniao(icone: Icons.event_available, cor: Cores.verde, texto: 'Próxima reunião: ${dataBr(r.data('data'))}'
                  '${r.strOuNulo('hora') != null ? ' às ${r.str('hora')}' : ''}'
                  '${r.strOuNulo('local') != null ? ' · ${r.str('local')}' : ''}', url: r.str('url'))
          else if (ultima != null)
            _LinhaReuniao(
              icone: Icons.history,
              cor: Theme.of(context).colorScheme.outline,
              texto: 'Última reunião publicada: ${dataBr(ultima.data('data') ?? ultima.data('publicadoEm'))}',
              url: ultima.str('url'),
            )
          else
            Text('Nenhuma reunião publicada na agenda do site.', style: tt.bodySmall),
          if (pubs.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Últimas publicações', style: tt.labelMedium),
            for (final p in pubs.take(3))
              InkWell(
                onTap: () => abrirUrl(Uri.parse(p.str('url'))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    const Icon(Icons.article_outlined, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(p.str('titulo'), style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (p.strOuNulo('publicadoEm') != null) Text(dataBr(p.data('publicadoEm')), style: tt.labelSmall),
                  ]),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            FilledButton.tonalIcon(
              onPressed: () => abrirUrl(Uri.parse(c.str('url'))),
              icon: const Icon(Icons.how_to_reg_outlined, size: 16),
              label: const Text('Como participar'),
            ),
            if ((c['pdfs'] as List? ?? const []).isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _documentos(context),
                icon: const Icon(Icons.folder_open_outlined, size: 16),
                label: Text('Documentos (${(c['pdfs'] as List).length})'),
              ),
          ]),
        ],
      ),
    );
  }

  void _documentos(BuildContext context) {
    final pdfs = (c['pdfs'] as List).cast<String>();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shrinkWrap: true,
        children: [
          Text(c.str('nome'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final p in pdfs)
            ListTile(
              dense: true,
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(Uri.decodeFull(p.split('/').last), maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => abrirUrl(Uri.parse(p)),
            ),
        ],
      ),
    );
  }
}

class _LinhaReuniao extends StatelessWidget {
  const _LinhaReuniao({required this.icone, required this.cor, required this.texto, required this.url});
  final IconData icone;
  final Color cor;
  final String texto;
  final String url;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => abrirUrl(Uri.parse(url)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 6),
            Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
}
