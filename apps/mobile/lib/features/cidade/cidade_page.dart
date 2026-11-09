import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// Hub "Cidade": o que está acontecendo hoje + atalhos para avisos, notícias,
/// serviços e conselhos. Tudo vem de `dados/avisos.json` e `dados/noticias.json`,
/// regenerados diariamente a partir do site oficial.
class CidadePage extends ConsumerWidget {
  const CidadePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avisos = ref.watch(dadosProvider('avisos'));
    final noticias = ref.watch(dadosProvider('noticias'));
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cidade')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dadosProvider('avisos'));
          ref.invalidate(dadosProvider('noticias'));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            Aparecer(
              child: Text('O que está acontecendo em São João hoje',
                  style: tt.headlineSmall),
            ),
            const SizedBox(height: 14),
            Aparecer(indice: 1, child: _Atalhos()),
            const SizedBox(height: 16),
            Aparecer(
              indice: 2,
              child: avisos.when(
                skipLoadingOnRefresh: true,
                loading: () => const Esqueleto(altura: 180),
                error: (_, __) => const Aviso(
                    'Avisos indisponíveis no momento. Puxe para atualizar.',
                    icone: Icons.cloud_off_outlined),
                data: (j) => _Hoje(j: j),
              ),
            ),
            const SizedBox(height: 14),
            Aparecer(
              indice: 3,
              child: noticias.when(
                skipLoadingOnRefresh: true,
                loading: () => const Esqueleto(altura: 160),
                error: (_, __) => const SizedBox.shrink(),
                data: (j) => _UltimasNoticias(j: j),
              ),
            ),
            const SizedBox(height: 14),
            Aparecer(
              indice: 4,
              child: avisos.maybeWhen(
                data: (j) => CardProcedencia(
                  url: Uri.parse(j.str('fonte', 'https://www.saojoao.sp.gov.br')),
                  obtidoEm: geradoEm(j),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Atalhos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final itens = <(String, String, IconData, Color, String)>[
      ('Avisos', 'Trânsito, coleta, eventos', Icons.campaign_outlined, Cores.laranja, '/cidade/avisos'),
      ('Notícias', 'O que a Prefeitura publicou', Icons.newspaper_outlined, Cores.azulCeu, '/cidade/noticias'),
      ('Serviços', 'Postos, escolas, contatos', Icons.local_hospital_outlined, Cores.verde, '/cidade/servicos'),
      ('Conselhos', 'Participe das decisões', Icons.groups_outlined, Cores.violeta, '/cidade/conselhos'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        for (final (titulo, sub, icone, cor, rota) in itens)
          CartaoVidro(
            padding: const EdgeInsets.all(14),
            cor: cor,
            onTap: () => context.push(rota),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, color: cor, size: 26),
                const Spacer(),
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                Text(sub,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
      ],
    );
  }
}

class _Hoje extends StatelessWidget {
  const _Hoje({required this.j});
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hoje = DateTime.now();
    final limite = hoje.add(const Duration(days: 14));
    bool proximo(Map<String, dynamic> e) {
      final d = e.data('data');
      return d != null && !d.isBefore(DateTime(hoje.year, hoje.month, hoje.day)) && d.isBefore(limite);
    }

    final eventos = j.lista('eventos').where(proximo).take(4).toList();
    final reunioes = j.lista('reunioesConselhos').where(proximo).take(3).toList();
    final interd = j.mapa('interdicoes');
    final interdTexto = interd.str('texto');

    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Hoje na cidade',
              subtitulo: 'próximos 14 dias', acao: () => context.push('/cidade/avisos')),
          if (interdTexto.isNotEmpty) ...[
            _Linha(
              icone: Icons.block_rounded,
              cor: Cores.rosa,
              titulo: 'Interdições de trânsito',
              sub: _primeiraLinha(interdTexto),
              onTap: () => context.push('/cidade/avisos'),
            ),
            const Divider(),
          ],
          if (eventos.isEmpty && reunioes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhum evento ou reunião publicado para os próximos dias.', style: tt.bodyMedium),
            ),
          for (final e in eventos)
            _Linha(
              icone: Icons.event_outlined,
              cor: Cores.amarelo,
              titulo: e.str('titulo'),
              sub: '${dataBr(e.data('data'))}${e.strOuNulo('hora') != null ? ' às ${e.str('hora')}' : ''} · ${e.str('local', e.str('agenda'))}',
              onTap: () => abrirUrl(Uri.parse(e.str('url'))),
            ),
          for (final r in reunioes)
            _Linha(
              icone: Icons.groups_outlined,
              cor: Cores.violeta,
              titulo: r.str('conselho'),
              sub: 'Reunião em ${dataBr(r.data('data'))}${r.strOuNulo('hora') != null ? ' às ${r.str('hora')}' : ''}${r.strOuNulo('modalidade') != null ? ' · ${r.str('modalidade')}' : ''}',
              onTap: () => abrirUrl(Uri.parse(r.str('url'))),
            ),
        ],
      ),
    );
  }

  static String _primeiraLinha(String t) {
    final l = t.split('\n').map((s) => s.trim()).where((s) => s.length > 10).toList();
    return l.isEmpty ? t : l.first;
  }
}

class _UltimasNoticias extends StatelessWidget {
  const _UltimasNoticias({required this.j});
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final ultimas = j.lista('ultimas').take(5).toList();
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloSecao('Últimas notícias', acao: () => context.push('/cidade/noticias')),
          for (final n in ultimas)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: n.strOuNulo('imagem') != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(n.str('imagem'), width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.newspaper_outlined)),
                    )
                  : const Icon(Icons.newspaper_outlined),
              title: Text(n.str('titulo'), maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodyMedium),
              subtitle: Text(
                [dataBr(n.data('data')), if (n.strOuNulo('departamento') != null) n.str('departamento')].join(' · '),
                style: tt.bodySmall,
              ),
              onTap: () => abrirUrl(Uri.parse(n.str('url'))),
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.cor, required this.titulo, required this.sub, this.onTap});
  final IconData icone;
  final Color cor;
  final String titulo;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icone, size: 18, color: cor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(sub, style: tt.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
