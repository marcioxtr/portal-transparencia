import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../glossario/glossario_page.dart' show abrirTermo;

/// Avisos da cidade: interdições, alterações de trânsito, coleta/cata-treco,
/// eventos e reuniões dos conselhos. Fonte: `dados/avisos.json` (site oficial).
class AvisosPage extends ConsumerWidget {
  const AvisosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avisos = ref.watch(dadosProvider('avisos'));
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos da cidade')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dadosProvider('avisos').future),
        child: Async(
          valor: avisos,
          aoTentarDeNovo: () => ref.invalidate(dadosProvider('avisos')),
          dado: (j) => _Corpo(j: j),
        ),
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.j});
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context) {
    final interd = j.mapa('interdicoes');
    final coleta = j.mapa('coleta');
    final seletiva = coleta.mapa('seletiva');
    final cata = coleta.mapa('cataTreco');
    final hoje = DateTime.now();
    final eventos = j.lista('eventos').where((e) {
      final d = e.data('data');
      return d == null || !d.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
    }).toList();
    final reunioes = j.lista('reunioesConselhos');
    final proximas = reunioes.where((r) {
      final d = r.data('data');
      return d != null && !d.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
    }).toList();
    final passadas = reunioes.where((r) => !proximas.contains(r)).take(10).toList();

    final secoes = <Widget>[
      _Secao(
        titulo: 'Interdições de trânsito',
        subtitulo: interd.strOuNulo('atualizadoEm') != null
            ? 'atualizado pela Prefeitura em ${dataBr(interd.data('atualizadoEm'))}${interd.strOuNulo('hora') != null ? ' às ${interd.str('hora')}' : ''}'
            : null,
        icone: Icons.block_rounded,
        cor: Cores.rosa,
        url: interd.strOuNulo('url'),
        child: interd.str('texto').isEmpty
            ? const Text('Nenhuma interdição informada.')
            : _Paragrafos(interd.str('texto')),
      ),
      _Secao(
        titulo: 'Alterações de trânsito',
        subtitulo: 'mudanças de mão, sentido e sinalização',
        icone: Icons.alt_route_rounded,
        cor: Cores.laranja,
        child: Column(children: [
          for (final a in j.lista('alteracoesTransito').take(12))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(a.str('titulo')),
              subtitle: a.strOuNulo('publicadoEm') != null ? Text(dataBr(a.data('publicadoEm'))) : null,
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => abrirUrl(Uri.parse(a.str('url'))),
            ),
        ]),
      ),
      _Secao(
        titulo: 'Coleta seletiva e Cata-Treco',
        subtitulo: cata.strOuNulo('publicadoEm') != null ? 'cata-treco atualizado em ${dataBr(cata.data('publicadoEm'))}' : null,
        icone: Icons.recycling_rounded,
        cor: Cores.verde,
        url: cata.strOuNulo('url'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cata.str('texto').isNotEmpty) _Paragrafos(cata.str('texto'), maxLinhas: 14),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (i, img) in (seletiva['imagens'] as List? ?? const []).cast<String>().indexed)
                _Imagem(url: img, rotulo: i == 0 ? 'Como separar' : 'Áreas e dias'),
              for (final img in (cata['imagens'] as List? ?? const []).cast<String>().take(2))
                _Imagem(url: img, rotulo: 'Cata-treco'),
            ]),
            if (seletiva.strOuNulo('url') != null)
              TextButton.icon(
                onPressed: () => abrirUrl(Uri.parse(seletiva.str('url'))),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Página da coleta seletiva'),
              ),
          ],
        ),
      ),
      _Secao(
        titulo: 'Eventos',
        subtitulo: 'cultura, esporte e agenda geral',
        icone: Icons.event_outlined,
        cor: Cores.amarelo,
        child: eventos.isEmpty
            ? const Text('Nenhum evento publicado.')
            : Column(children: [
                for (final e in eventos.take(15))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: e.strOuNulo('imagem') != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(e.str('imagem'), width: 52, height: 52, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.event)),
                          )
                        : const Icon(Icons.event),
                    title: Text(e.str('titulo')),
                    subtitle: Text([
                      if (e.data('data') != null) '${dataBr(e.data('data'))}${e.strOuNulo('hora') != null ? ' às ${e.str('hora')}' : ''}',
                      if (e.strOuNulo('local') != null) e.str('local'),
                      e.str('agenda'),
                    ].join(' · ')),
                    onTap: () => abrirUrl(Uri.parse(e.str('url'))),
                  ),
              ]),
      ),
      _Secao(
        titulo: 'Reuniões dos conselhos',
        subtitulo: 'abertas ao público — é onde o cidadão vota junto',
        icone: Icons.groups_outlined,
        cor: Cores.violeta,
        acaoInfo: () => abrirTermo(context, 'conselho'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (proximas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Nenhuma reunião futura publicada. Últimas publicadas:',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            for (final r in (proximas.isEmpty ? passadas : proximas).take(12)) _Reuniao(r: r),
          ],
        ),
      ),
      CardProcedencia(url: Uri.parse(j.str('fonte', 'https://www.saojoao.sp.gov.br')), obtidoEm: geradoEm(j)),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: secoes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => Aparecer(indice: i, child: secoes[i]),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.child,
    this.subtitulo,
    this.url,
    this.acaoInfo,
  });
  final String titulo;
  final String? subtitulo;
  final IconData icone;
  final Color cor;
  final Widget child;
  final String? url;
  final VoidCallback? acaoInfo;

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
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: tt.titleMedium),
                if (subtitulo != null) Text(subtitulo!, style: tt.bodySmall),
              ]),
            ),
            if (acaoInfo != null) IconButton(icon: const Icon(Icons.info_outline, size: 20), onPressed: acaoInfo),
            if (url != null)
              IconButton(
                tooltip: 'Abrir no site',
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: () => abrirUrl(Uri.parse(url!)),
              ),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Paragrafos extends StatefulWidget {
  const _Paragrafos(this.texto, {this.maxLinhas = 8});
  final String texto;
  final int maxLinhas;

  @override
  State<_Paragrafos> createState() => _ParagrafosState();
}

class _ParagrafosState extends State<_Paragrafos> {
  bool _tudo = false;

  @override
  Widget build(BuildContext context) {
    final linhas = widget.texto.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final mostrar = _tudo ? linhas : linhas.take(widget.maxLinhas).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in mostrar)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SelectableText(l, style: Theme.of(context).textTheme.bodyMedium),
          ),
        if (linhas.length > widget.maxLinhas)
          TextButton(
            onPressed: () => setState(() => _tudo = !_tudo),
            child: Text(_tudo ? 'Mostrar menos' : 'Mostrar tudo (${linhas.length - widget.maxLinhas} linhas)'),
          ),
      ],
    );
  }
}

class _Imagem extends StatelessWidget {
  const _Imagem({required this.url, required this.rotulo});
  final String url;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => abrirUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(12),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, width: 120, height: 90, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 90,
                    color: Vidro.of(context).superficie,
                    child: const Icon(Icons.image_outlined),
                  )),
        ),
        const SizedBox(height: 4),
        Text(rotulo, style: Theme.of(context).textTheme.labelSmall),
      ]),
    );
  }
}

class _Reuniao extends StatelessWidget {
  const _Reuniao({required this.r});
  final Map<String, dynamic> r;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final data = r.data('data') ?? r.data('publicadoEm');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Cores.violeta.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(data != null ? '${data.day}'.padLeft(2, '0') : '—', style: tt.titleMedium),
          Text(data != null ? _mes(data.month) : '', style: tt.labelSmall),
        ]),
      ),
      title: Text(r.str('conselho'), maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        if (r.strOuNulo('hora') != null) r.str('hora'),
        if (r.strOuNulo('modalidade') != null) r.str('modalidade'),
        if (r.strOuNulo('local') != null) r.str('local'),
      ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () => abrirUrl(Uri.parse(r.str('url'))),
    );
  }

  static String _mes(int m) => const ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'][m - 1];
}
