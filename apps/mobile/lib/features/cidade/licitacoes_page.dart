import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../glossario/glossario_page.dart' show abrirTermo;

/// Chamamentos públicos, inexigibilidades e dispensas (parcerias com o
/// terceiro setor) + processos seletivos. Licitações em si: portal SmarAPD.
/// Fonte: `dados/licitacoes.json` (site oficial).
class LicitacoesPage extends ConsumerStatefulWidget {
  const LicitacoesPage({super.key});

  @override
  ConsumerState<LicitacoesPage> createState() => _LicitacoesPageState();
}

class _LicitacoesPageState extends ConsumerState<LicitacoesPage> {
  String? _tipo;
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final dados = ref.watch(dadosProvider('licitacoes'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licitações e parcerias'),
        actions: [
          IconButton(
            tooltip: 'O que é licitação?',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => abrirTermo(context, 'licitacao'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dadosProvider('licitacoes').future),
        child: Async(
          valor: dados,
          aoTentarDeNovo: () => ref.invalidate(dadosProvider('licitacoes')),
          dado: (j) => _Corpo(
            j: j,
            tipo: _tipo,
            busca: _busca,
            aoFiltrar: (t) => setState(() => _tipo = t),
            aoBuscar: (b) => setState(() => _busca = b),
          ),
        ),
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.j, required this.tipo, required this.busca, required this.aoFiltrar, required this.aoBuscar});
  final Map<String, dynamic> j;
  final String? tipo;
  final String busca;
  final ValueChanged<String?> aoFiltrar;
  final ValueChanged<String> aoBuscar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final todos = j.lista('chamamentos');
    final tipos = todos.map((c) => c.str('tipo')).toSet().toList()..sort();
    final b = busca.toLowerCase();
    final lista = todos.where((c) {
      if (tipo != null && c.str('tipo') != tipo) return false;
      if (b.isEmpty) return true;
      return '${c.str('titulo')} ${c.str('objeto')} ${c.str('proponente')}'.toLowerCase().contains(b);
    }).toList();
    final seletivos = j.lista('processosSeletivos');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Aparecer(
          child: CartaoVidro(
            forte: true,
            cor: Cores.laranja,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Licitações em andamento', style: tt.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Pregões, concorrências e dispensas de 2026 em diante estão no portal da Prefeitura (SmarAPD). '
                  'Aqui embaixo ficam as parcerias com entidades sem fins lucrativos, que seguem outra lei (13.019/2014).',
                  style: tt.bodyMedium,
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => abrirUrl(Uri.parse(j.str('licitacoesUrl'))),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Abrir portal de licitações'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Aparecer(
          indice: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TituloSecao('Parcerias sem disputa', subtitulo: 'chamamentos, inexigibilidades e dispensas · ${todos.length} publicações'),
              const Aviso(
                'Inexigibilidade e dispensa são quando a Prefeitura firma a parceria com uma entidade específica sem '
                'chamamento aberto — permitido por lei em casos como emendas parlamentares ou entidade única na cidade. '
                'A justificativa é pública e cabe impugnação no prazo.',
                icone: Icons.info_outline,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(hintText: 'Buscar por entidade ou objeto', prefixIcon: Icon(Icons.search)),
                onChanged: aoBuscar,
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                PilulaVidro(rotulo: 'Todos', selecionada: tipo == null, onTap: () => aoFiltrar(null)),
                for (final t in tipos) PilulaVidro(rotulo: t, selecionada: tipo == t, onTap: () => aoFiltrar(tipo == t ? null : t)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (lista.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nada encontrado.'))),
        for (final (i, c) in lista.indexed) ...[
          Aparecer(indice: (i + 2).clamp(0, 10), child: _Chamamento(c: c)),
          const SizedBox(height: 10),
        ],
        if (seletivos.isNotEmpty) ...[
          const SizedBox(height: 6),
          const TituloSecao('Processos seletivos', subtitulo: 'contratações temporárias e estágios'),
          CartaoVidro(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              for (final p in seletivos)
                ListTile(
                  dense: true,
                  title: Text(p.str('titulo')),
                  subtitle: p.strOuNulo('publicadoEm') != null ? Text(dataBr(p.data('publicadoEm'))) : null,
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () => abrirUrl(Uri.parse(p.str('url'))),
                ),
            ]),
          ),
          const SizedBox(height: 14),
        ],
        CardProcedencia(
          url: Uri.parse(j.mapa('fontes').str('chamamentos', 'https://www.saojoao.sp.gov.br/transparencia/chamamentos-publicos')),
          obtidoEm: geradoEm(j),
        ),
      ],
    );
  }
}

class _Chamamento extends StatelessWidget {
  const _Chamamento({required this.c});
  final Map<String, dynamic> c;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cor = switch (c.str('tipo')) {
      'Inexigibilidade' => Cores.rosa,
      'Dispensa' => Cores.laranja,
      _ => Cores.azulCeu,
    };
    return CartaoVidro(
      cor: cor,
      padding: const EdgeInsets.all(14),
      onTap: () => _detalhe(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(c.str('tipo'), style: tt.labelSmall),
            ),
            const Spacer(),
            if (c.strOuNulo('publicadoEm') != null) Text(dataBr(c.data('publicadoEm')), style: tt.labelSmall),
          ]),
          const SizedBox(height: 8),
          Text(c.strOuNulo('proponente') ?? c.str('titulo'), style: tt.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (c.strOuNulo('objeto') != null) ...[
            const SizedBox(height: 4),
            Text(c.str('objeto'), style: tt.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if (c.numOuNulo('valor') != null) ...[
            const SizedBox(height: 4),
            Text(reais((c.num_('valor') * 100).round()), style: tt.titleMedium?.copyWith(color: cor)),
          ],
        ],
      ),
    );
  }

  void _detalhe(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text(c.str('tipo'), style: Theme.of(context).textTheme.labelLarge),
            Text(c.str('titulo'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Campo('Entidade', c.strOuNulo('proponente')),
            Campo('Objeto', c.strOuNulo('objeto')),
            Campo('Justificativa', c.strOuNulo('justificativa')),
            Campo('Despacho', c.strOuNulo('despacho')),
            Campo('Processo', c.strOuNulo('processo')),
            Campo('Publicado em', c.strOuNulo('publicadoEm') != null ? dataBr(c.data('publicadoEm')) : null),
            Campo('Prazo de impugnação', c.strOuNulo('prazoImpugnacao')),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              FilledButton.tonalIcon(
                onPressed: () => abrirUrl(Uri.parse(c.str('url'))),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Ver no site oficial'),
              ),
              if (c.strOuNulo('pdf') != null)
                OutlinedButton.icon(
                  onPressed: () => abrirUrl(Uri.parse(c.str('pdf'))),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('PDF'),
                ),
              OutlinedButton.icon(
                onPressed: () => abrirTermo(context, 'terceiro_setor'),
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text('O que é terceiro setor?'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
