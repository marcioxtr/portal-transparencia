import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// Serviços: unidades de saúde, escolas, departamentos (contato), Carta de
/// Serviços, relatórios da Ouvidoria, multas, Programa de Metas e modelos.
/// Fonte: `dados/servicos.json` (site oficial, regenerado diariamente).
class ServicosPage extends ConsumerStatefulWidget {
  const ServicosPage({super.key, this.abaInicial = 0});
  final int abaInicial;

  @override
  ConsumerState<ServicosPage> createState() => _ServicosPageState();
}

class _ServicosPageState extends ConsumerState<ServicosPage> {
  late int _aba = widget.abaInicial;
  String _busca = '';

  static const _abas = [
    ('Saúde', Icons.local_hospital_outlined, Cores.rosa),
    ('Escolas', Icons.school_outlined, Cores.amarelo),
    ('Departamentos', Icons.apartment_outlined, Cores.azulCeu),
    ('Documentos', Icons.description_outlined, Cores.verde),
  ];

  @override
  Widget build(BuildContext context) {
    final servicos = ref.watch(dadosProvider('servicos'));
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços e contatos')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _abas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => PilulaVidro(
                rotulo: _abas[i].$1,
                icone: _abas[i].$2,
                cor: _abas[i].$3,
                selecionada: _aba == i,
                onTap: () => setState(() => _aba = i),
              ),
            ),
          ),
          if (_aba < 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Buscar por nome ou bairro', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _busca = v.trim().toLowerCase()),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(dadosProvider('servicos').future),
              child: Async(
                valor: servicos,
                aoTentarDeNovo: () => ref.invalidate(dadosProvider('servicos')),
                dado: (j) => switch (_aba) {
                  0 => _Fichas(itens: j.lista('unidadesSaude'), busca: _busca, j: j, cor: Cores.rosa, vazio: 'Nenhuma unidade encontrada'),
                  1 => _Fichas(itens: j.lista('escolas'), busca: _busca, j: j, cor: Cores.amarelo, vazio: 'Nenhuma escola encontrada'),
                  2 => _Departamentos(j: j, busca: _busca),
                  _ => _Documentos(j: j),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _bate(Map<String, dynamic> f, String b) {
  if (b.isEmpty) return true;
  return '${f.str('nome')} ${f.str('endereco')} ${f.str('responsavel')}'.toLowerCase().contains(b);
}

Future<void> _ligar(String tel) => launchUrl(Uri.parse('tel:${tel.replaceAll(RegExp(r'[^\d]'), '')}'));
Future<void> _mapa(String end) =>
    launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$end, São João da Boa Vista - SP')}'),
        mode: LaunchMode.externalApplication);

class _Fichas extends StatelessWidget {
  const _Fichas({required this.itens, required this.busca, required this.j, required this.cor, required this.vazio});
  final List<Map<String, dynamic>> itens;
  final String busca;
  final Map<String, dynamic> j;
  final Color cor;
  final String vazio;

  @override
  Widget build(BuildContext context) {
    final lista = itens.where((f) => _bate(f, busca)).toList()..sort((a, b) => a.str('nome').compareTo(b.str('nome')));
    if (lista.isEmpty) return Mensagem(icone: Icons.search_off, titulo: vazio);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: lista.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == lista.length) {
          return CardProcedencia(url: Uri.parse(j.mapa('fontes').str('site', 'https://www.saojoao.sp.gov.br')), obtidoEm: geradoEm(j));
        }
        final f = lista[i];
        final tels = (f['telefones'] as List? ?? const []).cast<String>();
        final detalhes = (f['detalhes'] as List? ?? const []).cast<String>();
        return Aparecer(
          indice: i.clamp(0, 8),
          child: CartaoVidro(
            cor: cor,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.str('nome'), style: Theme.of(context).textTheme.titleMedium),
                if (f.strOuNulo('endereco') != null) ...[
                  const SizedBox(height: 4),
                  Text(f.str('endereco'), style: Theme.of(context).textTheme.bodySmall),
                ],
                for (final d in detalhes.take(2)) Text(d, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final t in tels.take(2))
                    ActionChip(avatar: const Icon(Icons.call, size: 16), label: Text(t), onPressed: () => _ligar(t)),
                  if (f.strOuNulo('endereco') != null)
                    ActionChip(
                        avatar: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Mapa'),
                        onPressed: () => _mapa(f.str('endereco'))),
                  if (f.strOuNulo('cardapio') != null)
                    ActionChip(
                        avatar: const Icon(Icons.restaurant_outlined, size: 16),
                        label: const Text('Cardápio'),
                        onPressed: () => abrirUrl(Uri.parse(f.str('cardapio')))),
                  if (f.strOuNulo('url') != null)
                    ActionChip(
                        avatar: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Página'),
                        onPressed: () => abrirUrl(Uri.parse(f.str('url')))),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Departamentos extends StatelessWidget {
  const _Departamentos({required this.j, required this.busca});
  final Map<String, dynamic> j;
  final String busca;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final lista = j.lista('departamentos').where((d) => _bate(d, busca)).toList();
    if (lista.isEmpty) return const Mensagem(icone: Icons.search_off, titulo: 'Nenhum departamento encontrado');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: lista.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == lista.length) {
          return CardProcedencia(url: Uri.parse('https://www.saojoao.sp.gov.br/departamentos'), obtidoEm: geradoEm(j));
        }
        final d = lista[i];
        final tels = (d['telefones'] as List? ?? const []).cast<String>();
        return Aparecer(
          indice: i.clamp(0, 8),
          child: CartaoVidro(
            cor: Cores.azulCeu,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.str('nome'), style: tt.titleMedium),
                if (d.strOuNulo('responsavel') != null) Text('Responsável: ${d.str('responsavel')}', style: tt.bodySmall),
                if (d.strOuNulo('horario') != null) Text('Horário: ${d.str('horario')}', style: tt.bodySmall),
                if (d.strOuNulo('endereco') != null) Text(d.str('endereco'), style: tt.bodySmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final t in tels.take(2))
                    ActionChip(avatar: const Icon(Icons.call, size: 16), label: Text(t), onPressed: () => _ligar(t)),
                  if (d.strOuNulo('url') != null)
                    ActionChip(
                        avatar: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Página'),
                        onPressed: () => abrirUrl(Uri.parse(d.str('url')))),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Documentos extends StatelessWidget {
  const _Documentos({required this.j});
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context) {
    final grupos = <(String, String, IconData, String)>[
      ('cartaServicos', 'Carta de Serviços', Icons.fact_check_outlined,
          'O que cada departamento é obrigado a prestar e em quanto tempo (Lei 13.460/2017).'),
      ('ouvidoriaRelatorios', 'Relatórios da Ouvidoria', Icons.record_voice_over_outlined,
          'Quantas reclamações, elogios e denúncias a Prefeitura recebeu por ano e como respondeu.'),
      ('multas', 'Multas de trânsito: arrecadação e aplicação', Icons.traffic_outlined,
          'Por lei, o dinheiro das multas só pode ser gasto em trânsito. Aqui a Prefeitura presta contas.'),
      ('programaMetas', 'Programa de Metas', Icons.flag_outlined,
          'O que a gestão prometeu fazer em cada área e o que diz ter realizado.'),
      ('modelos', 'Modelos de requerimento', Icons.edit_document,
          'Formulários prontos: recurso de IPTU, parcelamento, ITBI, prescrição.'),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: grupos.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (i == grupos.length) {
          return CardProcedencia(url: Uri.parse('https://www.saojoao.sp.gov.br'), obtidoEm: geradoEm(j));
        }
        final (chave, titulo, icone, expl) = grupos[i];
        final g = j.mapa(chave);
        final docs = g.lista('documentos');
        return Aparecer(indice: i, child: _GrupoDocs(titulo: titulo, icone: icone, explicacao: expl, docs: docs, url: g.strOuNulo('url')));
      },
    );
  }
}

class _GrupoDocs extends StatefulWidget {
  const _GrupoDocs({required this.titulo, required this.icone, required this.explicacao, required this.docs, this.url});
  final String titulo;
  final IconData icone;
  final String explicacao;
  final List<Map<String, dynamic>> docs;
  final String? url;

  @override
  State<_GrupoDocs> createState() => _GrupoDocsState();
}

class _GrupoDocsState extends State<_GrupoDocs> {
  bool _tudo = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mostrar = _tudo ? widget.docs : widget.docs.take(6).toList();
    return CartaoVidro(
      cor: Cores.verde,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(widget.icone, color: Cores.verde),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.titulo, style: tt.titleMedium)),
            Text('${widget.docs.length}', style: tt.labelLarge),
          ]),
          const SizedBox(height: 4),
          Text(widget.explicacao, style: tt.bodySmall),
          const SizedBox(height: 6),
          for (final d in mostrar)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(d.str('url').toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined, size: 20),
              title: Text(d.str('titulo'), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => abrirUrl(Uri.parse(d.str('url'))),
            ),
          if (widget.docs.length > 6)
            TextButton(
              onPressed: () => setState(() => _tudo = !_tudo),
              child: Text(_tudo ? 'Mostrar menos' : 'Ver todos (${widget.docs.length})'),
            ),
          if (widget.url != null)
            TextButton.icon(
              onPressed: () => abrirUrl(Uri.parse(widget.url!)),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver no site oficial'),
            ),
        ],
      ),
    );
  }
}
