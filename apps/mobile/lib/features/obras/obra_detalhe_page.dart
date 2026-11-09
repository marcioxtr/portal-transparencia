import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../app/tema.dart';
import '../../data/dados_remotos.dart';
import '../../data/providers.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../cidade/noticias_page.dart' show NoticiasRelacionadas;
import 'obra.dart';

class ObraDetalhePage extends ConsumerWidget {
  const ObraDetalhePage({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dados = ref.watch(dadosProvider('obras'));
    return Scaffold(
      appBar: AppBar(title: const Text('Obra')),
      body: Async(
        valor: dados,
        aoTentarDeNovo: () => ref.invalidate(dadosProvider('obras')),
        dado: (j) {
          final obra = Obra.lista(j).where((o) => o.slug == slug).firstOrNull;
          if (obra == null) {
            return const Mensagem(
              icone: Icons.search_off,
              titulo: 'Obra não encontrada',
              texto: 'Ela pode ter sido removida do site da Prefeitura.',
            );
          }
          return _Detalhe(obra: obra, geradoEm: geradoEm(j));
        },
      ),
    );
  }
}

class _Detalhe extends ConsumerWidget {
  const _Detalhe({required this.obra, required this.geradoEm});
  final Obra obra;
  final DateTime? geradoEm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final pct = (obra.percentualExecucao ?? 0).clamp(0, 100).toDouble();
    final dias = obra.dataTerminoPrevista?.difference(DateTime.now()).inDays;

    final itens = <Widget>[
      Text(obra.tituloBonito, style: tt.headlineSmall),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        Chip(
          avatar: Icon(obra.icone, size: 16, color: obra.cor),
          label: Text(obra.situacao),
          side: BorderSide(color: obra.cor),
        ),
        if (obra.atrasada)
          const Chip(
            avatar: Icon(Icons.warning_amber_rounded, size: 16, color: Cores.rosa),
            label: Text('Prazo vencido'),
            side: BorderSide(color: Cores.rosa),
          ),
        Chip(label: Text(Obra.curto(obra.secretaria))),
      ]),
      if (obra.atrasada)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Aviso(
            'A previsão de término era ${dataBr(obra.dataTerminoPrevista)} e a obra consta como '
            '"${obra.situacao}". Vale perguntar à Prefeitura o motivo do atraso.',
            icone: Icons.schedule_outlined,
          ),
        ),
      // Execução financeira em destaque
      CartaoVidro(
        forte: true,
        cor: obra.cor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quanto já foi pago', style: tt.labelLarge),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                NumeroAnimado(
                  valor: pct,
                  formatar: (v) => '${v.toStringAsFixed(1)}%',
                  estilo: tt.displaySmall?.copyWith(color: obra.cor, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${reais(((obra.valorExecutado ?? 0) * 100).round())} de '
                      '${reais(((obra.valorContrato ?? 0) * 100).round())}',
                      style: tt.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                Container(height: 12, color: Vidro.of(context).superficie),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct / 100),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, p, __) => FractionallySizedBox(
                    widthFactor: p,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [obra.cor, obra.cor.withValues(alpha: 0.6)]),
                        boxShadow: [BoxShadow(color: obra.cor.withValues(alpha: 0.45), blurRadius: 10)],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(
              obra.concluida
                  ? 'Obra concluída. Se o percentual ficou abaixo de 100%, a Prefeitura pode ter pago menos que o contrato previa.'
                  : dias == null
                      ? 'Execução financeira: o quanto do contrato já virou pagamento.'
                      : dias >= 0
                          ? 'Faltam $dias dias para o prazo previsto (${dataBr(obra.dataTerminoPrevista)}).'
                          : 'O prazo previsto venceu há ${-dias} dias.',
              style: tt.bodySmall,
            ),
          ],
        ),
      ),
      // Mini-mapa
      if (obra.ponto != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 190,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: obra.ponto!,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.com.neofusa.transparencia_sjbv',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: obra.ponto!,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.place, size: 40, color: obra.cor),
                  ),
                ]),
                const RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [TextSourceAttribution('© OpenStreetMap')],
                ),
              ],
            ),
          ),
        ),
      // Campos
      CartaoVidro(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Campo('Endereço', obra.endereco),
            Campo('Bairro', obra.bairro),
            Campo('Responsável na Prefeitura', obra.secretaria),
            Campo('Responsável técnico', obra.responsavelTecnico),
            const Divider(height: 20),
            Campo('Empresa contratada', obra.empresa),
            Campo('CPF/CNPJ', obra.cpfCnpj),
            Campo('Valor do contrato', obra.valorContrato == null ? null : reais((obra.valorContrato! * 100).round())),
            Campo('Já pago (execução financeira)', obra.valorExecutado == null ? null : reais((obra.valorExecutado! * 100).round())),
            const Divider(height: 20),
            Row(children: [
              Expanded(child: Campo('Início', dataBr(obra.dataInicio))),
              Expanded(child: Campo('Término previsto', dataBr(obra.dataTerminoPrevista))),
            ]),
          ],
        ),
      ),
      if (obra.fotos.isNotEmpty)
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: obra.fotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                obra.fotos[i],
                width: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      // Ações
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (obra.empresa != null)
          FilledButton.tonalIcon(
            onPressed: () {
              ref.read(filtroContratosProvider.notifier).definir(FiltroContratos(razaoSocial: _palavraChave(obra.empresa!)));
              context.go(Rotas.contratos);
            },
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Ver contratos dessa empresa'),
          ),
        FilledButton.icon(
          onPressed: () => context.push(
            Rotas.cobrar,
            extra: 'Solicito informações sobre a obra "${obra.tituloBonito}"'
                '${obra.endereco != null ? ' (${obra.endereco})' : ''}, executada por '
                '${obra.empresa ?? 'empresa não informada'}, com valor de contrato de '
                '${reais(((obra.valorContrato ?? 0) * 100).round())} e situação "${obra.situacao}" no site da Prefeitura: '
                'cronograma físico-financeiro atualizado, medições realizadas, aditivos de prazo ou valor e, '
                '${obra.atrasada ? 'considerando que o prazo previsto (${dataBr(obra.dataTerminoPrevista)}) já venceu, ' : ''}'
                'a nova previsão de conclusão.',
          ),
          icon: const Icon(Icons.record_voice_over_outlined, size: 18),
          label: const Text('Pedir explicação'),
        ),
        OutlinedButton.icon(
          onPressed: () => abrirUrl(Uri.parse(obra.url)),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Ver no site'),
        ),
      ]),
      NoticiasRelacionadas(termo: _termoNoticia(obra.tituloBonito)),
      const SizedBox(height: 12),
      CardProcedencia(url: Uri.parse(obra.url), obtidoEm: geradoEm),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => Aparecer(indice: i, child: itens[i]),
    );
  }

  static String _palavraChave(String nome) {
    final ruido = {'ltda', 'epp', 'me', 'eireli', 's.a', 'sa', 'construtora', 'engenharia', 'e', '&'};
    final palavras = nome
        .split(RegExp(r'[\s&]+'))
        .where((w) => w.length > 2 && !ruido.contains(w.toLowerCase().replaceAll('.', '')))
        .toList();
    return (palavras.isEmpty ? nome.split(' ') : palavras).take(2).join(' ');
  }
}

/// Reduz o título da obra a um termo bom para buscar notícias: o local
/// ("Parque dos Resedás") quando houver, senão as primeiras palavras.
String _termoNoticia(String titulo) {
  final m = RegExp(r'\b(?:no|na|nos|nas|em|do|da)\s+(.{6,40})$', caseSensitive: false).firstMatch(titulo);
  if (m != null) return m.group(1)!.trim();
  final palavras = titulo.split(RegExp(r'\s+')).where((w) => w.length > 3).take(3);
  return palavras.join(' ');
}
