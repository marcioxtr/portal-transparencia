import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/roteador.dart';
import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import 'obra.dart';

/// Filtros da aba Obras (sobrevivem à navegação para o detalhe).
class FiltroObras {
  const FiltroObras({this.situacao, this.secretaria, this.mapa = true});
  final String? situacao;
  final String? secretaria;
  final bool mapa;

  FiltroObras copyWith({String? situacao, String? secretaria, bool? mapa, bool limparSituacao = false, bool limparSecretaria = false}) =>
      FiltroObras(
        situacao: limparSituacao ? null : (situacao ?? this.situacao),
        secretaria: limparSecretaria ? null : (secretaria ?? this.secretaria),
        mapa: mapa ?? this.mapa,
      );
}

class FiltroObrasNotifier extends Notifier<FiltroObras> {
  @override
  FiltroObras build() => const FiltroObras();
  void definir(FiltroObras f) => state = f;
}

final filtroObrasProvider = NotifierProvider<FiltroObrasNotifier, FiltroObras>(FiltroObrasNotifier.new);

/// Obras públicas no mapa e em lista — dados raspados diariamente de
/// www.saojoao.sp.gov.br/obras (dados/obras.json).
class ObrasPage extends ConsumerWidget {
  const ObrasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dados = ref.watch(dadosProvider('obras'));
    final filtro = ref.watch(filtroObrasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obras'),
        actions: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.map_outlined, size: 18), label: Text('Mapa')),
              ButtonSegment(value: false, icon: Icon(Icons.view_list_outlined, size: 18), label: Text('Lista')),
            ],
            selected: {filtro.mapa},
            onSelectionChanged: (s) => ref.read(filtroObrasProvider.notifier).definir(filtro.copyWith(mapa: s.first)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Async(
        valor: dados,
        aoTentarDeNovo: () => ref.invalidate(dadosProvider('obras')),
        dado: (j) {
          final todas = Obra.lista(j);
          final visiveis = todas
              .where((o) => filtro.situacao == null || o.situacao == filtro.situacao)
              .where((o) => filtro.secretaria == null || o.secretaria == filtro.secretaria)
              .toList();
          return Column(
            children: [
              _Resumo(j: j, todas: todas, visiveis: visiveis),
              _Filtros(j: j, todas: todas, filtro: filtro),
              Expanded(
                child: filtro.mapa
                    ? _Mapa(obras: visiveis)
                    : _Lista(obras: visiveis, geradoEm: geradoEm(j), fonte: j.str('fonte')),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Resumo ─────────────────────────────────────────────────────────────────

class _Resumo extends StatelessWidget {
  const _Resumo({required this.j, required this.todas, required this.visiveis});
  final Map<String, dynamic> j;
  final List<Obra> todas;
  final List<Obra> visiveis;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final andamento = todas.where((o) => o.emAndamento).length;
    final atrasadas = todas.where((o) => o.atrasada).length;
    final contratos = visiveis.fold<double>(0, (s, o) => s + (o.valorContrato ?? 0));
    final executado = visiveis.fold<double>(0, (s, o) => s + (o.valorExecutado ?? 0));
    final pct = contratos == 0 ? 0.0 : executado / contratos;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Aparecer(
        child: CartaoVidro(
          forte: true,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Kpi('Obras', '${visiveis.length}', Cores.azulCeu),
                  _Kpi('Em andamento', '$andamento', Cores.laranja),
                  _Kpi('Atrasadas', '$atrasadas', atrasadas > 0 ? Cores.rosa : Cores.verde),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contratado', style: tt.labelMedium),
                        NumeroAnimado(
                          valor: contratos,
                          formatar: (v) => reaisCurto((v * 100).round()),
                          estilo: tt.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Já pago (${(pct * 100).toStringAsFixed(0)}%)', style: tt.labelMedium),
                        NumeroAnimado(
                          valor: executado,
                          formatar: (v) => reaisCurto((v * 100).round()),
                          estilo: tt.titleLarge?.copyWith(color: Cores.verde),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(children: [
                  Container(height: 8, color: Vidro.of(context).superficie),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct.clamp(0, 1)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, p, __) => FractionallySizedBox(
                      widthFactor: p,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Cores.verde, Cores.azulCeu]),
                          boxShadow: [BoxShadow(color: Cores.verde.withValues(alpha: 0.4), blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.rotulo, this.valor, this.cor);
  final String rotulo;
  final String valor;
  final Color cor;
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: tt.headlineSmall?.copyWith(color: cor)),
          Text(rotulo, style: tt.labelMedium),
        ],
      ),
    );
  }
}

// ── Filtros ────────────────────────────────────────────────────────────────

class _Filtros extends ConsumerWidget {
  const _Filtros({required this.j, required this.todas, required this.filtro});
  final Map<String, dynamic> j;
  final List<Obra> todas;
  final FiltroObras filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(filtroObrasProvider.notifier);
    final situacoes = <String>{for (final o in todas) o.situacao}.toList()..sort((a, b) => Obra.ordem(a).compareTo(Obra.ordem(b)));
    final secretarias = <String>{for (final o in todas) if (o.secretaria.isNotEmpty) o.secretaria}.toList()..sort();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        children: [
          PilulaVidro(
            rotulo: 'Todas',
            selecionada: filtro.situacao == null,
            onTap: () => notifier.definir(filtro.copyWith(limparSituacao: true)),
          ),
          const SizedBox(width: 8),
          for (final s in situacoes) ...[
            PilulaVidro(
              rotulo: '$s (${todas.where((o) => o.situacao == s).length})',
              selecionada: filtro.situacao == s,
              cor: Obra.corSituacao(s),
              onTap: () => notifier.definir(filtro.copyWith(situacao: s)),
            ),
            const SizedBox(width: 8),
          ],
          PilulaVidro(
            rotulo: filtro.secretaria == null ? 'Departamento' : Obra.curto(filtro.secretaria!),
            icone: Icons.account_tree_outlined,
            selecionada: filtro.secretaria != null,
            cor: Cores.violeta,
            onTap: () => _escolherSecretaria(context, ref, secretarias),
          ),
        ],
      ),
    );
  }

  void _escolherSecretaria(BuildContext context, WidgetRef ref, List<String> secretarias) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Qual departamento?', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Todos'),
              onTap: () {
                ref.read(filtroObrasProvider.notifier).definir(filtro.copyWith(limparSecretaria: true));
                Navigator.pop(ctx);
              },
            ),
            for (final s in secretarias)
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(Obra.curto(s)),
                trailing: Text('${todas.where((o) => o.secretaria == s).length}'),
                selected: filtro.secretaria == s,
                onTap: () {
                  ref.read(filtroObrasProvider.notifier).definir(filtro.copyWith(secretaria: s));
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Mapa ───────────────────────────────────────────────────────────────────

class _Mapa extends StatelessWidget {
  const _Mapa({required this.obras});
  final List<Obra> obras;

  static final _centroSJBV = LatLng(-21.969, -46.798);

  @override
  Widget build(BuildContext context) {
    final comCoord = obras.where((o) => o.ponto != null).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      child: Aparecer(
        indice: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: comCoord.isEmpty ? _centroSJBV : _centroSJBV,
                  initialZoom: 13,
                  minZoom: 11,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.com.neofusa.transparencia_sjbv',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final o in comCoord)
                        Marker(
                          point: o.ponto!,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: _Pino(obra: o),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    attributions: [TextSourceAttribution('© OpenStreetMap')],
                  ),
                ],
              ),
              Positioned(
                right: 12,
                top: 12,
                child: _LegendaMapa(obras: comCoord),
              ),
              if (comCoord.isEmpty)
                const Center(
                  child: Mensagem(icone: Icons.location_off_outlined, titulo: 'Nenhuma obra com esse filtro'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pino extends StatelessWidget {
  const _Pino({required this.obra});
  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final cor = obra.cor;
    return GestureDetector(
      onTap: () => abrirSheetObra(context, obra),
      child: Tooltip(
        message: obra.titulo,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Icon(obra.icone, size: 16, color: Colors.white),
            ),
            Container(
              width: 2.5,
              height: 10,
              decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendaMapa extends StatelessWidget {
  const _LegendaMapa({required this.obras});
  final List<Obra> obras;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final situacoes = <String>{for (final o in obras) o.situacao}.toList()..sort((a, b) => Obra.ordem(a).compareTo(Obra.ordem(b)));
    return CartaoVidro(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      raio: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in situacoes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: Obra.corSituacao(s), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(s, style: tt.labelSmall),
              ]),
            ),
        ],
      ),
    );
  }
}

// ── Lista ──────────────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.obras, required this.geradoEm, required this.fonte});
  final List<Obra> obras;
  final DateTime? geradoEm;
  final String fonte;

  @override
  Widget build(BuildContext context) {
    if (obras.isEmpty) {
      return const Mensagem(icone: Icons.search_off, titulo: 'Nenhuma obra com esse filtro');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: obras.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == obras.length) {
          return CardProcedencia(url: Uri.parse(fonte), obtidoEm: geradoEm);
        }
        return Aparecer(indice: i.clamp(0, 8), child: CartaoObra(obra: obras[i]));
      },
    );
  }
}

/// Cartão de obra (lista e sheet do mapa).
class CartaoObra extends StatelessWidget {
  const CartaoObra({super.key, required this.obra, this.compacto = false});
  final Obra obra;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return CartaoVidro(
      cor: obra.cor,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      onTap: () => context.push(Rotas.obra(obra.slug)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: obra.cor.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(8)),
              child: Text(obra.situacao, style: tt.labelSmall?.copyWith(color: obra.cor, fontWeight: FontWeight.w700)),
            ),
            if (obra.atrasada) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Cores.rosa.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(8)),
                child: Text('Prazo vencido', style: tt.labelSmall?.copyWith(color: Cores.rosa, fontWeight: FontWeight.w700)),
              ),
            ],
            const Spacer(),
            Text(Obra.curto(obra.secretaria), style: tt.labelSmall, overflow: TextOverflow.ellipsis),
          ]),
          const SizedBox(height: 8),
          Text(obra.tituloBonito, style: tt.titleMedium, maxLines: compacto ? 2 : 3, overflow: TextOverflow.ellipsis),
          if (obra.endereco != null) ...[
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.place_outlined, size: 14),
              const SizedBox(width: 4),
              Expanded(child: Text(obra.endereco!, style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ],
          const SizedBox(height: 8),
          BarraProporcao(
            rotulo: obra.empresa ?? 'Empresa não informada',
            valor: '${obra.percentualExecucao?.toStringAsFixed(0) ?? '—'}% pago',
            sub: '${reaisCurto(((obra.valorExecutado ?? 0) * 100).round())} de ${reaisCurto(((obra.valorContrato ?? 0) * 100).round())}'
                '${obra.dataTerminoPrevista != null ? ' · prazo ${dataBr(obra.dataTerminoPrevista)}' : ''}',
            proporcao: (obra.percentualExecucao ?? 0) / 100,
            cor: obra.cor,
          ),
        ],
      ),
    );
  }
}

/// Sheet rápido ao tocar um pino do mapa.
void abrirSheetObra(BuildContext context, Obra obra) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CartaoObra(obra: obra, compacto: true),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(Rotas.obra(obra.slug));
            },
            icon: const Icon(Icons.open_in_full, size: 18),
            label: const Text('Ver detalhes da obra'),
          ),
        ],
      ),
    ),
  );
}
