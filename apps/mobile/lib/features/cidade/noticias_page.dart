import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// Notícias da Prefeitura (RSS oficial + listas por departamento), com filtro
/// por departamento e busca local. Fonte: `dados/noticias.json`.
class NoticiasPage extends ConsumerStatefulWidget {
  const NoticiasPage({super.key, this.departamento, this.busca});
  final String? departamento;
  final String? busca;

  @override
  ConsumerState<NoticiasPage> createState() => _NoticiasPageState();
}

class _NoticiasPageState extends ConsumerState<NoticiasPage> {
  late String? _dep = widget.departamento;
  late final _ctrl = TextEditingController(text: widget.busca ?? '');
  late String _busca = widget.busca ?? '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noticias = ref.watch(dadosProvider('noticias'));
    return Scaffold(
      appBar: AppBar(title: const Text('Notícias da Prefeitura')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Buscar nas últimas notícias',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _busca = '');
                        }),
              ),
              onChanged: (v) => setState(() => _busca = v.trim()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(dadosProvider('noticias').future),
              child: Async(
                valor: noticias,
                aoTentarDeNovo: () => ref.invalidate(dadosProvider('noticias')),
                dado: (j) => _Lista(
                  j: j,
                  dep: _dep,
                  busca: _busca,
                  aoEscolherDep: (d) => setState(() => _dep = d),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.j, required this.dep, required this.busca, required this.aoEscolherDep});
  final Map<String, dynamic> j;
  final String? dep;
  final String busca;
  final ValueChanged<String?> aoEscolherDep;

  @override
  Widget build(BuildContext context) {
    final deps = (j['porDepartamento'] as Map?)?.cast<String, dynamic>() ?? const {};
    final nomes = deps.values.map((v) => v.toString()).toSet().toList()..sort();
    final b = busca.toLowerCase();
    final itens = j.lista('ultimas').where((n) {
      if (dep != null && n.strOuNulo('departamento') != dep) return false;
      if (b.isEmpty) return true;
      return n.str('titulo').toLowerCase().contains(b) || n.str('resumo').toLowerCase().contains(b);
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                PilulaVidro(rotulo: 'Todas', selecionada: dep == null, onTap: () => aoEscolherDep(null)),
                for (final n in nomes) ...[
                  const SizedBox(width: 8),
                  PilulaVidro(rotulo: n, selecionada: dep == n, onTap: () => aoEscolherDep(dep == n ? null : n)),
                ],
              ],
            ),
          ),
        ),
        if (itens.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Mensagem(icone: Icons.search_off, titulo: 'Nenhuma notícia encontrada'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList.separated(
              itemCount: itens.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == itens.length) {
                  return CardProcedencia(
                    url: Uri.parse(j.mapa('fontes').str('site', 'https://www.saojoao.sp.gov.br/noticias')),
                    obtidoEm: geradoEm(j),
                  );
                }
                return Aparecer(indice: i.clamp(0, 8), child: CartaoNoticia(n: itens[i]));
              },
            ),
          ),
      ],
    );
  }
}

/// Cartão de uma notícia (reutilizado em outras telas).
class CartaoNoticia extends StatelessWidget {
  const CartaoNoticia({super.key, required this.n, this.compacto = false});
  final Map<String, dynamic> n;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final img = n.strOuNulo('imagem');
    return CartaoVidro(
      padding: const EdgeInsets.all(12),
      onTap: () => abrirUrl(Uri.parse(n.str('url'))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (img != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(img, width: compacto ? 56 : 84, height: compacto ? 56 : 84, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => SizedBox(width: compacto ? 56 : 84, height: compacto ? 56 : 84,
                      child: const Icon(Icons.newspaper_outlined))),
            ),
          if (img != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.str('titulo'), style: tt.titleSmall, maxLines: compacto ? 2 : 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  [dataBr(n.data('data')), if (n.strOuNulo('departamento') != null) n.str('departamento')].join(' · '),
                  style: tt.labelSmall,
                ),
                if (!compacto && n.str('resumo').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(n.str('resumo'), style: tt.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Até 3 notícias cujo título ou resumo contenha [termo] — para telas de obra,
/// contrato, fornecedor etc. Não renderiza nada se não houver.
class NoticiasRelacionadas extends ConsumerWidget {
  const NoticiasRelacionadas({super.key, required this.termo, this.maximo = 3});
  final String termo;
  final int maximo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticias = ref.watch(dadosProvider('noticias'));
    final t = termo.trim().toLowerCase();
    if (t.length < 3) return const SizedBox.shrink();
    return noticias.maybeWhen(
      data: (j) {
        final achadas = j.lista('ultimas').where((n) {
          final txt = '${n.str('titulo')} ${n.str('resumo')}'.toLowerCase();
          return txt.contains(t);
        }).take(maximo).toList();
        if (achadas.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TituloSecao('O que a Prefeitura publicou sobre isso'),
            for (final n in achadas) ...[
              CartaoNoticia(n: n, compacto: true),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
