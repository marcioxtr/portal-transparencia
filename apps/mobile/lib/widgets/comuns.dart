import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Formatação ─────────────────────────────────────────────────────────────

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _moedaCompacta =
    NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
final _data = DateFormat('dd/MM/yyyy', 'pt_BR');
final _dataHora = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');

String reais(int? centavos) =>
    centavos == null ? '—' : _moeda.format(centavos / 100);

/// `R$ 1,2 mi`, `R$ 350 mil` — para cards e resumos.
String reaisCurto(int? centavos) =>
    centavos == null ? '—' : _moedaCompacta.format(centavos / 100);

String dataBr(DateTime? d) => d == null ? '—' : _data.format(d);
String dataHoraBr(DateTime d) => _dataHora.format(d);

Future<void> abrirUrl(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

// ── Estados ────────────────────────────────────────────────────────────────

/// Renderiza um `AsyncValue` com carregando / erro / dado, padronizando a
/// mensagem de erro e o botão "tentar de novo".
class Async<T> extends StatelessWidget {
  const Async({
    super.key,
    required this.valor,
    required this.dado,
    this.aoTentarDeNovo,
    this.carregando,
  });

  final AsyncValue<T> valor;
  final Widget Function(T) dado;
  final VoidCallback? aoTentarDeNovo;
  final Widget? carregando;

  @override
  Widget build(BuildContext context) {
    return valor.when(
      skipLoadingOnRefresh: true,
      data: dado,
      loading: () =>
          carregando ?? const Center(child: CircularProgressIndicator()),
      error: (e, _) => Mensagem(
        icone: Icons.cloud_off_outlined,
        titulo: 'Não foi possível carregar',
        texto: 'A fonte oficial pode estar fora do ar ou lenta. '
            'Isso acontece com frequência — tente de novo em instantes.',
        detalhe: e.toString(),
        acao: aoTentarDeNovo,
      ),
    );
  }
}

class Mensagem extends StatelessWidget {
  const Mensagem({
    super.key,
    required this.icone,
    required this.titulo,
    this.texto,
    this.detalhe,
    this.acao,
    this.rotuloAcao = 'Tentar de novo',
  });

  final IconData icone;
  final String titulo;
  final String? texto;
  final String? detalhe;
  final VoidCallback? acao;
  final String rotuloAcao;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      children: [
        Icon(icone, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(titulo, textAlign: TextAlign.center, style: tt.titleMedium),
        if (texto != null) ...[
          const SizedBox(height: 8),
          Text(texto!, textAlign: TextAlign.center, style: tt.bodyMedium),
        ],
        if (acao != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton.tonal(onPressed: acao, child: Text(rotuloAcao)),
          ),
        ],
        if (detalhe != null) ...[
          const SizedBox(height: 24),
          ExpansionTile(
            title: Text('Detalhes técnicos', style: tt.labelMedium),
            tilePadding: EdgeInsets.zero,
            children: [
              SelectableText(detalhe!, style: tt.bodySmall),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Procedência ────────────────────────────────────────────────────────────

/// Card obrigatório em toda tela de dado: de onde veio e quando.
class CardProcedencia extends StatelessWidget {
  const CardProcedencia({super.key, required this.url, this.obtidoEm});
  final Uri url;
  final DateTime? obtidoEm;

  @override
  Widget build(BuildContext context) {
    final quando = obtidoEm ?? DateTime.now();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: const Text('Procedência'),
        subtitle: Text(
          'Dado público obtido de ${url.host} em ${dataHoraBr(quando)}. '
          'Toque para abrir a fonte oficial.',
        ),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => abrirUrl(url),
      ),
    );
  }
}

/// Linha "rótulo / valor" usada nos detalhes.
class Campo extends StatelessWidget {
  const Campo(this.rotulo, this.valor, {super.key, this.selecionavel = true});
  final String rotulo;
  final String? valor;
  final bool selecionavel;

  @override
  Widget build(BuildContext context) {
    if (valor == null || valor!.isEmpty || valor == '—') {
      return const SizedBox.shrink();
    }
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo,
              style: tt.labelMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 2),
          selecionavel
              ? SelectableText(valor!, style: tt.bodyLarge)
              : Text(valor!, style: tt.bodyLarge),
        ],
      ),
    );
  }
}

/// Faixa de aviso (fonte indisponível, dado parcial…).
class Aviso extends StatelessWidget {
  const Aviso(this.texto, {super.key, this.icone = Icons.info_outline});
  final String texto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, color: cs.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: TextStyle(color: cs.onTertiaryContainer)),
          ),
        ],
      ),
    );
  }
}
