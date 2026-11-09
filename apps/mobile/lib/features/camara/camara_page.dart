import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../data/painel.dart';
import '../../data/providers.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';

/// Câmara Municipal: vereadores, sessões, leis e gestões (mandatos).
/// Fonte: dados/camara.json (SAPL), atualizado diariamente.
class CamaraPage extends ConsumerStatefulWidget {
  const CamaraPage({super.key, this.abaInicial = 0});
  final int abaInicial;

  @override
  ConsumerState<CamaraPage> createState() => _CamaraPageState();
}

class _CamaraPageState extends ConsumerState<CamaraPage> {
  late int _aba = widget.abaInicial;

  @override
  Widget build(BuildContext context) {
    final dados = ref.watch(dadosProvider('camara'));
    return Scaffold(
      appBar: AppBar(title: const Text('Câmara Municipal')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (i, (rotulo, icone)) in const [
                    ('Vereadores', Icons.groups_outlined),
                    ('Sessões', Icons.event_outlined),
                    ('Leis', Icons.gavel_outlined),
                    ('Gestões', Icons.timeline_outlined),
                  ].indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PilulaVidro(
                        rotulo: rotulo,
                        icone: icone,
                        selecionada: _aba == i,
                        onTap: () => setState(() => _aba = i),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(dadosProvider('camara').future),
              child: Async(
                valor: dados,
                aoTentarDeNovo: () => ref.invalidate(dadosProvider('camara')),
                carregando: ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [Esqueleto(altura: 120), SizedBox(height: 12), Esqueleto(altura: 120)],
                ),
                dado: (j) => switch (_aba) {
                  0 => _Vereadores(j: j),
                  1 => _Sessoes(j: j),
                  2 => _Leis(j: j),
                  _ => _Gestoes(j: j),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vereadores ─────────────────────────────────────────────────────────────

enum _Ordem { nome, partido, propostas }

class _Vereadores extends StatefulWidget {
  const _Vereadores({required this.j});
  final Map<String, dynamic> j;

  @override
  State<_Vereadores> createState() => _VereadoresState();
}

class _VereadoresState extends State<_Vereadores> {
  _Ordem _ordem = _Ordem.nome;
  bool _soAtuais = true;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final legs = widget.j.lista('legislaturas');
    final atual = legs.where((l) => l.bool_('atual')).firstOrNull;
    final atualId = atual?.int_('id');

    var lista = widget.j.lista('vereadores').where((v) {
      if (!_soAtuais || atualId == null) return true;
      return v.lista('mandatos').any((m) => m.int_('legislatura') == atualId);
    }).toList();

    int propostas(Map<String, dynamic> v) {
      final est = v.mapa('estatisticas');
      final chave = atualId?.toString();
      if (_soAtuais && chave != null) return (est[chave] as Map<String, dynamic>?)?.int_('total') ?? 0;
      return est.values.fold<int>(0, (s, e) => s + ((e as Map<String, dynamic>).int_('total')));
    }

    lista.sort((a, b) => switch (_ordem) {
          _Ordem.nome => a.str('nome').compareTo(b.str('nome')),
          _Ordem.partido => '${a.str('partido')}${a.str('nome')}'.compareTo('${b.str('partido')}${b.str('nome')}'),
          _Ordem.propostas => propostas(b).compareTo(propostas(a)),
        });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Text(
          atual != null
              ? '${atual.int_('numero')}ª Legislatura · ${atual.str('inicio').substring(0, 4)}–${atual.str('fim').substring(0, 4)} · ${lista.length} vereadores'
              : '${lista.length} vereadores',
          style: tt.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (o, r) in const [(_Ordem.nome, 'Nome'), (_Ordem.partido, 'Partido'), (_Ordem.propostas, 'Mais propostas')])
            PilulaVidro(rotulo: r, selecionada: _ordem == o, onTap: () => setState(() => _ordem = o)),
          PilulaVidro(
            rotulo: _soAtuais ? 'Só mandato atual' : 'Todos desde 2013',
            icone: Icons.history,
            selecionada: !_soAtuais,
            cor: Cores.violeta,
            onTap: () => setState(() => _soAtuais = !_soAtuais),
          ),
        ]),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: lista.length,
          itemBuilder: (_, i) {
            final v = lista[i];
            final afastado = v.lista('mandatos').any((m) => m.int_('legislatura') == atualId && m.bool_('afastado'));
            final suplente = v.lista('mandatos').any((m) => m.int_('legislatura') == atualId && !m.bool_('titular'));
            return Aparecer(
              indice: i.clamp(0, 10),
              child: CartaoVidro(
                padding: const EdgeInsets.all(12),
                onTap: () => context.push('/camara/vereador/${v.int_('id')}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FotoVereador(url: v.strOuNulo('foto'), nome: v.str('nome')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(v.str('nome'), style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(children: [
                      if (v.strOuNulo('partido') != null)
                        Text(v.str('partido'), style: tt.labelMedium?.copyWith(color: Cores.primaria, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${propostas(v)} prop.', style: tt.labelSmall),
                    ]),
                    if (afastado || suplente)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(afastado ? 'afastado' : 'suplente',
                            style: tt.labelSmall?.copyWith(color: Cores.laranja, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _Procedencia(j: widget.j, url: 'https://sapl.saojoaodaboavista.sp.leg.br/parlamentar/'),
      ],
    );
  }
}

/// Foto do parlamentar com fallback de ícone.
class FotoVereador extends StatelessWidget {
  const FotoVereador({super.key, required this.url, required this.nome, this.tamanho});
  final String? url;
  final String nome;
  final double? tamanho;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: Cores.primaria.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        nome.isEmpty ? '?' : nome.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Cores.primaria),
      ),
    );
    final img = url == null
        ? fallback
        : Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (_, child, p) => p == null ? child : fallback,
          );
    return tamanho == null ? img : SizedBox(width: tamanho, height: tamanho, child: img);
  }
}

// ── Sessões ────────────────────────────────────────────────────────────────

class _Sessoes extends StatelessWidget {
  const _Sessoes({required this.j});
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final s = j.mapa('sessoes');
    final proximas = s.lista('proximas');
    final ultimas = s.lista('ultimas');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (proximas.isNotEmpty) ...[
          Aparecer(
            child: CartaoVidro(
              forte: true,
              cor: Cores.verde,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.event_available_outlined, color: Cores.verde),
                  const SizedBox(width: 8),
                  Text('Próximas sessões', style: tt.titleMedium),
                ]),
                const SizedBox(height: 6),
                Text('Sessões são públicas: você pode ir à Câmara ou assistir ao vivo no YouTube.', style: tt.bodySmall),
                const SizedBox(height: 8),
                for (final p in proximas)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(p.str('titulo')),
                    subtitle: Text(dataBr(p.data('data'))),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => abrirUrl(Uri.parse(p.str('url'))),
                  ),
                TextButton.icon(
                  onPressed: () => abrirUrl(Uri.parse('https://www.youtube.com/@camarasjbv')),
                  icon: const Icon(Icons.live_tv_outlined, size: 18),
                  label: const Text('Canal da Câmara no YouTube'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Aviso('Agenda das próximas sessões não disponível automaticamente. Em geral, as sessões ordinárias acontecem às segundas-feiras.'),
          ),
        TituloSecao('Últimas sessões', subtitulo: '${ultimas.length} mais recentes · vídeo e ata em PDF'),
        for (final (i, u) in ultimas.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Aparecer(
              indice: i.clamp(0, 8),
              child: CartaoVidro(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.str('titulo'), style: tt.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${dataBr(u.data('data'))}${u.strOuNulo('horaInicio') != null && u.str('horaInicio').isNotEmpty ? ' às ${u.str('horaInicio')}' : ''}'
                    '${u.str('tipo').isNotEmpty ? ' · ${u.str('tipo')}' : ''}'
                    '${u.strOuNulo('tema') != null ? ' · ${u.str('tema')}' : ''}',
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (u.strOuNulo('video') != null)
                      FilledButton.tonalIcon(
                        onPressed: () => abrirUrl(Uri.parse(u.str('video'))),
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('Assistir'),
                      ),
                    if (u.strOuNulo('ata') != null)
                      OutlinedButton.icon(
                        onPressed: () => abrirUrl(Uri.parse(u.str('ata'))),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('Ata (PDF)'),
                      ),
                    if (u.strOuNulo('pauta') != null)
                      OutlinedButton.icon(
                        onPressed: () => abrirUrl(Uri.parse(u.str('pauta'))),
                        icon: const Icon(Icons.list_alt_outlined, size: 18),
                        label: const Text('Pauta'),
                      ),
                    TextButton(onPressed: () => abrirUrl(Uri.parse(u.str('url'))), child: const Text('No SAPL')),
                  ]),
                ]),
              ),
            ),
          ),
        _Procedencia(j: j, url: 'https://sapl.saojoaodaboavista.sp.leg.br/sessao/pesquisar'),
      ],
    );
  }
}

// ── Leis ───────────────────────────────────────────────────────────────────

/// Busca ao vivo no SAPL (`?search=`), sem depender do JSON diário.
final buscaLeisProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, termo) async {
  if (termo.trim().length < 3) return const [];
  final http = ref.watch(clienteHttpProvider);
  final uri = Uri.parse('https://sapl.saojoaodaboavista.sp.leg.br/api/norma/normajuridica/')
      .replace(queryParameters: {'search': termo.trim(), 'page_size': '30', 'ordering': '-data'});
  final resp = await http.get(uri, headers: {'Accept': 'application/json'});
  if (resp.statusCode != 200) throw DadosIndisponiveis('busca de leis');
  final j = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  return (j['results'] as List).cast<Map<String, dynamic>>();
});

class _Leis extends ConsumerStatefulWidget {
  const _Leis({required this.j});
  final Map<String, dynamic> j;

  @override
  ConsumerState<_Leis> createState() => _LeisState();
}

class _LeisState extends ConsumerState<_Leis> {
  final _ctrl = TextEditingController();
  String _termo = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final recentes = widget.j.lista('leisRecentes');
    final porAno = widget.j.mapa('leisPorTipoAno');
    final anos = porAno.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar lei por assunto (ex.: IPTU, cães, feira)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _termo.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _termo = '');
                    }),
          ),
          onSubmitted: (v) => setState(() => _termo = v.trim()),
        ),
        const SizedBox(height: 12),
        if (_termo.length >= 3) ...[
          Builder(builder: (context) {
            final busca = ref.watch(buscaLeisProvider(_termo));
            return busca.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              error: (_, __) => Aviso(
                'Busca ao vivo indisponível agora. Tente de novo ou pesquise direto no SAPL.',
                icone: Icons.cloud_off_outlined,
              ),
              data: (lista) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${lista.length} resultados para "$_termo" (busca ao vivo no SAPL)', style: tt.bodySmall),
                const SizedBox(height: 8),
                if (lista.isEmpty) const Aviso('Nenhuma lei encontrada com esse termo.'),
                for (final n in lista) _CartaoLei(n: _normalizarSapl(n)),
              ]),
            );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => abrirUrl(Uri.parse('https://sapl.saojoaodaboavista.sp.leg.br/norma/pesquisar?ementa=${Uri.encodeQueryComponent(_termo)}')),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Pesquisa completa no SAPL'),
          ),
          const Divider(height: 32),
        ],
        if (anos.isNotEmpty) ...[
          TituloSecao('Leis por ano', subtitulo: 'quantas normas a Câmara publicou'),
          CartaoVidro(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(children: [
              for (final a in anos.take(6))
                () {
                  final m = (porAno[a] as Map).cast<String, dynamic>();
                  final total = m.values.fold<int>(0, (s, v) => s + (v as num).toInt());
                  final max = anos.take(6).map((x) => (porAno[x] as Map).values.fold<int>(0, (s, v) => s + (v as num).toInt())).fold<int>(1, (p, q) => p > q ? p : q);
                  return BarraProporcao(
                    rotulo: a,
                    valor: '$total',
                    sub: m.entries.map((e) => '${e.value} ${e.key}').join(' · '),
                    proporcao: total / max,
                    cor: Cores.serie(anos.indexOf(a)),
                  );
                }(),
            ]),
          ),
          const SizedBox(height: 14),
        ],
        TituloSecao('Leis recentes', subtitulo: '${recentes.length} mais recentes'),
        for (final (i, n) in recentes.indexed) Aparecer(indice: i.clamp(0, 8), child: _CartaoLei(n: n)),
        _Procedencia(j: widget.j, url: 'https://sapl.saojoaodaboavista.sp.leg.br/norma/pesquisar'),
      ],
    );
  }

  Map<String, dynamic> _normalizarSapl(Map<String, dynamic> n) => {
        'id': n['id'],
        'tipo': (n['__str__'] as String? ?? '').split(' nº').first,
        'sigla': '',
        'numero': n['numero'],
        'ano': n['ano'],
        'data': n['data'],
        'dataPublicacao': n['data_publicacao'],
        'veiculo': n['veiculo_publicacao'],
        'ementa': n['ementa'] ?? '',
        'textoUrl': n['texto_integral'],
        'url': 'https://sapl.saojoaodaboavista.sp.leg.br/norma/${n['id']}',
      };
}

class _CartaoLei extends StatelessWidget {
  const _CartaoLei({required this.n});
  final Map<String, dynamic> n;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoVidro(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        onTap: () => abrirUrl(Uri.parse(n.strOuNulo('textoUrl') ?? n.str('url'))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${n.str('tipo')} nº ${n.str('numero')}/${n.int_('ano')}', style: tt.titleSmall),
          const SizedBox(height: 4),
          Text(n.str('ementa'), style: tt.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(
            [
              if (n.data('data') != null) 'de ${dataBr(n.data('data'))}',
              if (n.data('dataPublicacao') != null) 'publicada em ${dataBr(n.data('dataPublicacao'))}${n.strOuNulo('veiculo') != null ? ' (${n.str('veiculo')})' : ''}',
            ].join(' · '),
            style: tt.bodySmall,
          ),
        ]),
      ),
    );
  }
}

// ── Gestões ────────────────────────────────────────────────────────────────

class _Gestoes extends ConsumerWidget {
  const _Gestoes({required this.j});
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final gestoes = j.lista('gestoes').reversed.toList();
    final vereadores = {for (final v in j.lista('vereadores')) v.int_('id'): v};
    final avisos = (j['avisos'] as List?)?.cast<String>() ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Text('Cada mandato tem 4 anos. Toque num período para ver as contas daquele ano no painel.', style: tt.bodySmall),
        const SizedBox(height: 12),
        for (final (i, g) in gestoes.indexed)
          Aparecer(
            indice: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CartaoVidro(
                forte: g.bool_('atual'),
                cor: g.bool_('atual') ? Cores.primaria : null,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('${g.str('inicio').substring(0, 4)}–${g.str('fim').substring(0, 4)}', style: tt.titleLarge),
                    const SizedBox(width: 8),
                    Text('${g.int_('numero')}ª legislatura', style: tt.bodySmall),
                    if (g.bool_('atual')) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Cores.verde.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                        child: Text('atual', style: tt.labelSmall),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Campo(
                    'Prefeito(a)',
                    g['prefeito'] is Map
                        ? '${(g['prefeito'] as Map)['nome']} (${(g['prefeito'] as Map)['partido'] ?? '—'})'
                        : 'nome não disponível na fonte automática',
                    selecionavel: false,
                  ),
                  Row(children: [
                    Expanded(child: Campo('Sessões', '${g.int_('sessoes')}', selecionavel: false)),
                    Expanded(child: Campo('Matérias', '${g.int_('materias')}', selecionavel: false)),
                    Expanded(child: Campo('Leis', '${g.int_('leis')}', selecionavel: false)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Vereadores (${g.lista('vereadores').length})', style: tt.labelMedium),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final id in (g['vereadores'] as List? ?? const []).cast<num>())
                      if (vereadores[id.toInt()] != null)
                        ActionChip(
                          avatar: ClipOval(child: FotoVereador(url: vereadores[id.toInt()]!.strOuNulo('foto'), nome: vereadores[id.toInt()]!.str('nome'), tamanho: 24)),
                          label: Text(vereadores[id.toInt()]!.str('nome'), style: tt.labelSmall),
                          onPressed: () => context.push('/camara/vereador/${id.toInt()}'),
                        ),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    for (var ano = int.parse(g.str('inicio').substring(0, 4)); ano <= int.parse(g.str('fim').substring(0, 4)) && ano <= DateTime.now().year; ano++)
                      if (ano >= 2014)
                        FilledButton.tonal(
                          onPressed: () {
                            ref.read(anoPainelProvider.notifier).definir(ano);
                            context.go(Rotas.inicio);
                          },
                          child: Text('Contas $ano'),
                        ),
                  ]),
                ]),
              ),
            ),
          ),
        for (final a in avisos) Padding(padding: const EdgeInsets.only(bottom: 10), child: Aviso(a)),
        _Procedencia(j: j, url: 'https://sapl.saojoaodaboavista.sp.leg.br/parlamentar/legislatura'),
      ],
    );
  }
}

class _Procedencia extends StatelessWidget {
  const _Procedencia({required this.j, required this.url});
  final Map<String, dynamic> j;
  final String url;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CardProcedencia(url: Uri.parse(url), obtidoEm: geradoEm(j)),
      );
}
