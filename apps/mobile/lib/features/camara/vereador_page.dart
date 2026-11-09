import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import 'camara_page.dart' show FotoVereador;

/// Um vereador: quem é e o que fez em cada mandato — números do SAPL,
/// sem adjetivos.
class VereadorPage extends ConsumerWidget {
  const VereadorPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dados = ref.watch(dadosProvider('camara'));
    return Scaffold(
      appBar: AppBar(title: const Text('Vereador(a)')),
      body: Async(
        valor: dados,
        aoTentarDeNovo: () => ref.invalidate(dadosProvider('camara')),
        dado: (j) {
          final v = j.lista('vereadores').where((x) => x.int_('id') == id).firstOrNull;
          if (v == null) {
            return const Mensagem(icone: Icons.person_off_outlined, titulo: 'Vereador não encontrado');
          }
          return _Corpo(v: v, j: j);
        },
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.v, required this.j});
  final Map<String, dynamic> v;
  final Map<String, dynamic> j;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final legs = {for (final l in j.lista('legislaturas')) l.int_('id'): l};
    final mandatos = v.lista('mandatos').reversed.toList();
    final est = v.mapa('estatisticas');
    final emendas = j.lista('emendasImpositivas').where((e) => ((e['autoresIds'] as List?) ?? const []).contains(v.int_('id'))).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Aparecer(
          child: CartaoVidro(
            forte: true,
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FotoVereador(url: v.strOuNulo('foto'), nome: v.str('nome'), tamanho: 96),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.str('nome'), style: tt.headlineSmall),
                  if (v.str('nomeCompleto').isNotEmpty && v.str('nomeCompleto') != v.str('nome'))
                    Text(v.str('nomeCompleto'), style: tt.bodySmall),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (v.strOuNulo('partido') != null) Chip(label: Text(v.str('partido')), visualDensity: VisualDensity.compact),
                    Chip(
                      label: Text(v.bool_('ativo') ? 'em exercício' : 'sem mandato atual'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: (v.bool_('ativo') ? Cores.verde : Colors.grey).withValues(alpha: 0.2),
                    ),
                    Chip(label: Text('${mandatos.length} mandato${mandatos.length == 1 ? '' : 's'}'), visualDensity: VisualDensity.compact),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, m) in mandatos.indexed)
          Aparecer(
            indice: i + 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _Mandato(
                m: m,
                leg: legs[m.int_('legislatura')],
                e: (est[m.int_('legislatura').toString()] as Map<String, dynamic>?) ?? const {},
                emendas: emendas.where((x) => _dentro(x.strOuNulo('data'), legs[m.int_('legislatura')])).toList(),
              ),
            ),
          ),
        if (v.lista('ultimasMaterias').isNotEmpty) ...[
          TituloSecao('Últimas propostas', subtitulo: 'texto integral no SAPL'),
          for (final mat in v.lista('ultimasMaterias'))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CartaoVidro(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                onTap: () => abrirUrl(Uri.parse(mat.strOuNulo('textoUrl') ?? mat.str('url'))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('${mat.str('tipo')} nº ${mat.str('numero')}/${mat.int_('ano')}', style: tt.titleSmall)),
                    if (mat.bool_('emTramitacao'))
                      Text('em tramitação', style: tt.labelSmall?.copyWith(color: Cores.laranja, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  Text(mat.str('ementa'), style: tt.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(dataBr(mat.data('data')), style: tt.bodySmall),
                ]),
              ),
            ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(
            onPressed: () => abrirUrl(Uri.parse(v.str('url'))),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Página no SAPL'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.push(
              Rotas.cobrar,
              extra: 'Gostaria de receber a relação completa de proposições, requerimentos e indicações de autoria '
                  'do(a) vereador(a) ${v.str('nome')} no mandato atual, com a situação de cada uma.',
            ),
            icon: const Icon(Icons.record_voice_over_outlined, size: 18),
            label: const Text('Pedir informação à Câmara'),
          ),
        ]),
        const SizedBox(height: 16),
        CardProcedencia(url: Uri.parse(v.str('url')), obtidoEm: geradoEm(j)),
      ],
    );
  }

  static bool _dentro(String? data, Map<String, dynamic>? leg) {
    if (data == null || leg == null) return false;
    return data.compareTo(leg.str('inicio')) >= 0 && data.compareTo(leg.str('fim')) <= 0;
  }
}

class _Mandato extends StatelessWidget {
  const _Mandato({required this.m, required this.leg, required this.e, required this.emendas});
  final Map<String, dynamic> m;
  final Map<String, dynamic>? leg;
  final Map<String, dynamic> e;
  final List<Map<String, dynamic>> emendas;

  static const _nomesTipo = {
    'REQ': 'Requerimentos', 'IND': 'Indicações', 'MOC': 'Moções', 'PL': 'Projetos de lei',
    'PLC': 'Projetos de lei complementar', 'PELOM': 'Emendas à Lei Orgânica', 'PDL': 'Projetos de decreto legislativo',
    'PR': 'Projetos de resolução', 'EMI': 'Emendas impositivas', 'OFI': 'Ofícios', 'OFEXE': 'Ofícios do Executivo',
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final atual = leg?.bool_('atual') ?? false;
    final inicio = (m.strOuNulo('inicio') ?? leg?.str('inicio') ?? '').substring(0, 4);
    final fim = (m.strOuNulo('fim') ?? leg?.str('fim') ?? '').substring(0, 4);
    final porTipo = (e['porTipo'] as Map?)?.cast<String, dynamic>() ?? const {};
    final votos = (e['votos'] as Map?)?.cast<String, dynamic>() ?? const {};
    final totalVotos = votos.values.fold<int>(0, (s, x) => s + (x as num).toInt());
    final presencas = e.int_('presencas');
    final sessoes = e.int_('sessoes');
    final maiorTipo = porTipo.values.fold<int>(1, (p, q) => p > (q as num).toInt() ? p : q.toInt());

    return CartaoVidro(
      cor: atual ? Cores.primaria : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Mandato $inicio–$fim', style: tt.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          if (atual) Text('atual', style: tt.labelMedium?.copyWith(color: Cores.verde, fontWeight: FontWeight.w700)),
          if (!m.bool_('titular')) Text(' · suplente', style: tt.labelSmall),
          if (m.bool_('afastado')) Text(' · afastado', style: tt.labelSmall?.copyWith(color: Cores.laranja)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Kpi('Propostas', '${e.int_('total')}', Cores.azulCeu)),
          Expanded(child: _Kpi('Emendas impositivas', '${e.int_('emendasImpositivas')}', Cores.laranja)),
          Expanded(
            child: _Kpi(
              'Presença',
              sessoes > 0 ? '${(presencas / sessoes * 100).clamp(0, 100).toStringAsFixed(0)}%' : '—',
              Cores.verde,
              sub: sessoes > 0 ? '$presencas de $sessoes sessões' : null,
            ),
          ),
        ]),
        if (porTipo.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('O que propôs', style: tt.titleMedium),
          const SizedBox(height: 4),
          for (final (i, en) in (porTipo.entries.toList()..sort((a, b) => (b.value as num).compareTo(a.value as num))).take(6).indexed)
            BarraProporcao(
              rotulo: _nomesTipo[en.key] ?? en.key,
              valor: '${en.value}',
              proporcao: (en.value as num) / maiorTipo,
              cor: Cores.serie(i),
            ),
        ],
        if (totalVotos > 0) ...[
          const SizedBox(height: 14),
          Text('Como votou', style: tt.titleMedium),
          Text('$totalVotos votos nominais registrados', style: tt.bodySmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(children: [
                for (final (k, cor) in const [('sim', Cores.verde), ('nao', Cores.rosa), ('abstencao', Cores.amarelo), ('naoVotou', Colors.grey)])
                  if ((votos[k] as num? ?? 0) > 0)
                    Expanded(flex: (votos[k] as num).toInt(), child: Container(color: cor)),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 12, runSpacing: 4, children: [
            for (final (k, r, cor) in const [('sim', 'Sim', Cores.verde), ('nao', 'Não', Cores.rosa), ('abstencao', 'Abstenção', Cores.amarelo), ('naoVotou', 'Não votou', Colors.grey)])
              if ((votos[k] as num? ?? 0) > 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('$r ${votos[k]}', style: tt.labelMedium),
                ]),
          ]),
        ],
        if (emendas.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Emendas impositivas', style: tt.titleMedium),
          Text('Dinheiro do orçamento que o vereador destinou a um fim específico.', style: tt.bodySmall),
          const SizedBox(height: 6),
          for (final em in emendas.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(em.str('ementa'), maxLines: 3, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [
                  '${em.str('sigla')} ${em.str('numero')}/${em.int_('ano')}',
                  if (em.numOuNulo('valor') != null) reais((em.num_('valor') * 100).round()),
                ].join(' · '),
              ),
              onTap: () => abrirUrl(Uri.parse(em.strOuNulo('textoUrl') ?? em.str('url'))),
            ),
        ],
      ]),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.rotulo, this.valor, this.cor, {this.sub});
  final String rotulo;
  final String valor;
  final Color cor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(rotulo, style: tt.labelMedium),
      Text(valor, style: tt.headlineSmall?.copyWith(color: cor)),
      if (sub != null) Text(sub!, style: tt.labelSmall),
    ]);
  }
}
