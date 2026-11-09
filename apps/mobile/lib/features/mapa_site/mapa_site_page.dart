import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// Mapa completo do site oficial dentro do app: tudo o que a Prefeitura
/// publica, agrupado por categoria, dizendo o que já está organizado aqui
/// (abre a tela interna) e o que ainda só existe no site (abre o original).
class MapaSitePage extends ConsumerStatefulWidget {
  const MapaSitePage({super.key});

  @override
  ConsumerState<MapaSitePage> createState() => _MapaSitePageState();
}

class _MapaSitePageState extends ConsumerState<MapaSitePage> {
  String _busca = '';

  static final _fonte = Uri.parse('https://www.saojoao.sp.gov.br/mapa-do-site');

  @override
  Widget build(BuildContext context) {
    final dados = ref.watch(dadosProvider('mapa_site'));
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa do site oficial')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Procurar uma seção do site (ex.: IPTU, conselho, obras)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _busca = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: Async(
              valor: dados,
              aoTentarDeNovo: () => ref.invalidate(dadosProvider('mapa_site')),
              dado: (j) => _Lista(j: j, busca: _busca, fonte: _fonte),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.j, required this.busca, required this.fonte});
  final Map<String, dynamic> j;
  final String busca;
  final Uri fonte;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final categorias = j.lista('categorias');
    final total = j.int_('total');
    final noApp = j.int_('noApp');

    bool casa(Map<String, dynamic> i) =>
        busca.isEmpty ||
        i.str('titulo').toLowerCase().contains(busca) ||
        i.str('subsecao').toLowerCase().contains(busca) ||
        i.str('grupo').toLowerCase().contains(busca) ||
        i.str('url').toLowerCase().contains(busca);

    final visiveis = [
      for (final c in categorias)
        (c.str('nome'), c.lista('itens').where(casa).toList()),
    ].where((e) => e.$2.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Aparecer(
          child: CartaoVidro(
            forte: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$total seções do site oficial · $noApp já organizadas no app', style: tt.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Tudo o que a Prefeitura publica, no mesmo lugar. O que tem ícone de cubo abre aqui '
                  'dentro, em linguagem simples; o resto abre no site oficial.',
                  style: tt.bodySmall,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(children: [
                    Container(height: 8, color: Vidro.of(context).superficie),
                    FractionallySizedBox(
                      widthFactor: total == 0 ? 0 : (noApp / total).clamp(0, 1),
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Cores.primaria, Cores.azulCeu]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (visiveis.isEmpty)
          const Mensagem(icone: Icons.search_off, titulo: 'Nada encontrado com esse termo'),
        for (final (i, (nome, itens)) in visiveis.indexed) ...[
          Aparecer(
            indice: (i + 1).clamp(0, 8),
            child: CartaoVidro(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: busca.isNotEmpty || i < 2,
                  leading: Icon(_iconeCategoria(nome), color: Cores.serie(i)),
                  title: Text(nome, style: tt.titleMedium),
                  subtitle: Text(
                    '${itens.length} ${itens.length == 1 ? 'seção' : 'seções'} · '
                    '${itens.where((x) => x.strOuNulo('noApp') != null).length} no app',
                    style: tt.bodySmall,
                  ),
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  children: [for (final it in itens) _Item(it: it)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        CardProcedencia(url: fonte, obtidoEm: geradoEm(j)),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.it});
  final Map<String, dynamic> it;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final rota = it.strOuNulo('noApp');
    final externo = it.bool_('externo');
    final sub = it.strOuNulo('subsecao');
    final noApp = rota != null;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.fromLTRB(sub == null ? 20 : 36, 0, 12, 0),
      leading: Icon(
        noApp ? Icons.view_in_ar_rounded : (externo ? Icons.open_in_new : Icons.language),
        size: 20,
        color: noApp ? Cores.primaria : Theme.of(context).colorScheme.outline,
      ),
      title: Text(it.str('titulo'), style: tt.bodyMedium?.copyWith(fontWeight: noApp ? FontWeight.w600 : null)),
      subtitle: Text(
        noApp
            ? 'Organizado no app'
            : (externo ? 'Sistema externo · ${it.str('dominio')}' : 'No site oficial'),
        style: tt.labelSmall,
      ),
      trailing: Icon(noApp ? Icons.chevron_right : Icons.north_east, size: 16),
      onTap: () {
        if (noApp) {
          context.push(rota);
        } else {
          abrirUrl(Uri.parse(it.str('url')));
        }
      },
      onLongPress: () => abrirUrl(Uri.parse(it.str('url'))),
    );
  }
}

IconData _iconeCategoria(String nome) => switch (nome) {
      'Transparência' => Icons.visibility_outlined,
      'Serviços ao cidadão' => Icons.support_agent_outlined,
      'Departamentos' => Icons.apartment_outlined,
      'Conselhos' => Icons.groups_outlined,
      'Educação' => Icons.school_outlined,
      'Saúde' => Icons.local_hospital_outlined,
      'Cultura e esportes' => Icons.theater_comedy_outlined,
      'Notícias' => Icons.newspaper_outlined,
      'Institucional' => Icons.account_balance_outlined,
      'Sistemas externos' => Icons.hub_outlined,
      _ => Icons.folder_outlined,
    };
