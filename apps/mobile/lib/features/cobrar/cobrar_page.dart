import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/tema.dart';
import '../../widgets/comuns.dart';
import '../../widgets/vidro.dart';
import '../glossario/glossario_page.dart' show abrirTermo;

/// Do dado para a ação: canais oficiais para pedir informação, reclamar e
/// participar — com o texto já pronto e a base legal citada.
class CobrarPage extends StatefulWidget {
  const CobrarPage({super.key, this.textoInicial});

  /// Texto pré-preenchido do pedido (vindo de um contrato/fornecedor).
  final String? textoInicial;

  @override
  State<CobrarPage> createState() => _CobrarPageState();
}

class _CobrarPageState extends State<CobrarPage> {
  static final _eouv = Uri.parse('https://saojoaodaboavista.eouve.com.br/');
  static final _ouvidoria = Uri.parse('https://www.saojoao.sp.gov.br/cidadao/ouvidoria');
  static final _camara = Uri.parse('https://www.saojoaodaboavista.sp.leg.br/paginas/vereadores');
  static final _sessoes = Uri.parse('https://www.youtube.com/@camarasjbv');
  static final _conselhos = Uri.parse(
      'https://www.saojoao.sp.gov.br/transparencia/agenda-de-reunioes-dos-conselhos-municipais');
  static final _modelos = Uri.parse('https://www.saojoao.sp.gov.br/cidadao/modelos-de-requerimentos');
  static final _carta = Uri.parse('https://www.saojoao.sp.gov.br/carta-de-servicos');

  late final _ctrl = TextEditingController(text: widget.textoInicial ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _pedido => '''
Prezada Prefeitura Municipal de São João da Boa Vista,

Com fundamento na Lei de Acesso à Informação (Lei Federal nº 12.527/2011, art. 10) e na Lei Complementar nº 131/2009, solicito as seguintes informações:

${_ctrl.text.trim().isEmpty ? '[descreva aqui o que você quer saber]' : _ctrl.text.trim()}

Peço que a resposta seja enviada em formato eletrônico aberto (planilha ou PDF pesquisável), conforme o art. 8º, §3º, II da LAI. Lembro que o prazo legal de resposta é de 20 dias, prorrogáveis por mais 10 mediante justificativa (art. 11).

Atenciosamente.
''';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cobrar a Prefeitura')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Aparecer(
            child: Text('Dado público é o começo. O direito de perguntar é seu — e eles têm prazo para responder.',
                style: tt.titleMedium),
          ),
          const SizedBox(height: 16),
          Aparecer(
            indice: 1,
            child: CartaoVidro(
              forte: true,
              cor: Cores.primaria,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.record_voice_over_outlined),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Pedir uma informação (e-SIC)', style: tt.titleLarge)),
                    IconButton(
                      tooltip: 'O que é e-SIC?',
                      icon: const Icon(Icons.info_outline, size: 20),
                      onPressed: () => abrirTermo(context, 'esic'),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('Escreva o que quer saber. O app monta o pedido com a base legal e o prazo; '
                      'você só cola no portal oficial.', style: tt.bodyMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Ex.: quanto foi gasto com manutenção de iluminação pública em 2025, por bairro?',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Vidro.of(context).superficie,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(_pedido.trim(), style: tt.bodySmall),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _pedido.trim()));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pedido copiado. Agora cole no e-OUV.')),
                        );
                        await abrirUrl(_eouv);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar e abrir o e-OUV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => SharePlus.instance.share(ShareParams(text: _pedido.trim())),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Compartilhar'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Aparecer(
            indice: 2,
            child: _Canal(
              icone: Icons.campaign_outlined,
              cor: Cores.laranja,
              titulo: 'Reclamar, sugerir ou denunciar (Ouvidoria)',
              texto: 'Buraco na rua, demora no posto, atendimento ruim. Gera protocolo e tem prazo de 30 dias.',
              acoes: [
                ('Abrir Ouvidoria', _eouv),
                ('Como funciona', _ouvidoria),
              ],
              termo: 'ouvidoria',
            ),
          ),
          const SizedBox(height: 14),
          Aparecer(
            indice: 3,
            child: _Canal(
              icone: Icons.account_balance_outlined,
              cor: Cores.violeta,
              titulo: 'Falar com quem fiscaliza: os vereadores',
              texto: 'A Câmara fiscaliza a Prefeitura. Vereadores podem pedir informações oficialmente '
                  '(requerimento) e convocar secretários. As sessões são públicas e transmitidas.',
              acoes: [
                ('Conheça os vereadores', _camara),
                ('Assistir às sessões', _sessoes),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Aparecer(
            indice: 4,
            child: _Canal(
              icone: Icons.groups_outlined,
              cor: Cores.verde,
              titulo: 'Participar dos conselhos',
              texto: 'Saúde, educação, meio ambiente, idoso, criança… mais de 20 conselhos com reuniões abertas. '
                  'É onde o cidadão vota junto com o governo.',
              acoes: [('Agenda de reuniões', _conselhos)],
              termo: 'conselho',
            ),
          ),
          const SizedBox(height: 14),
          Aparecer(
            indice: 5,
            child: _Canal(
              icone: Icons.description_outlined,
              cor: Cores.azulCeu,
              titulo: 'Modelos e o que a Prefeitura deve oferecer',
              texto: 'Modelos oficiais de requerimento e a Carta de Serviços — a lista do que cada departamento '
                  'é obrigado a prestar, com prazos.',
              acoes: [
                ('Modelos de requerimento', _modelos),
                ('Carta de Serviços', _carta),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Aparecer(
            indice: 6,
            child: CartaoVidro(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seus direitos, em uma linha cada', style: tt.titleMedium),
                  const SizedBox(height: 8),
                  const _Direito('Você não precisa dizer por que quer a informação.'),
                  const _Direito('Prazo: 20 dias, prorrogáveis por 10 com justificativa.'),
                  const _Direito('Negativa tem que ser por escrito e cabe recurso.'),
                  const _Direito('Dado público deve vir em formato aberto, não só em papel ou imagem.'),
                  const _Direito('Pedir informação não pode gerar retaliação.'),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => abrirTermo(context, 'lai'), child: const Text('Entenda a LAI')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Canal extends StatelessWidget {
  const _Canal({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.texto,
    required this.acoes,
    this.termo,
  });
  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;
  final List<(String, Uri)> acoes;
  final String? termo;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return CartaoVidro(
      cor: cor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: cor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icone, color: cor),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(titulo, style: tt.titleMedium)),
            if (termo != null)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => abrirTermo(context, termo!),
              ),
          ]),
          const SizedBox(height: 8),
          Text(texto, style: tt.bodyMedium),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (rotulo, url) in acoes)
              FilledButton.tonalIcon(
                onPressed: () => abrirUrl(url),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(rotulo),
              ),
          ]),
        ],
      ),
    );
  }
}

class _Direito extends StatelessWidget {
  const _Direito(this.texto);
  final String texto;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Cores.verde),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}
