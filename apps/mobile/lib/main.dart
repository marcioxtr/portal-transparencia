import 'package:flutter/material.dart';
import 'package:fontes/fontes.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ponto de partida do app. Hoje: uma única tela que prova a integração com
/// o pacote `fontes` listando contratos reais do site da Prefeitura.
/// A arquitetura completa (features/domain/data, cache, config remota) está
/// descrita em `docs/03-arquitetura.md` e entra nas próximas fases.
void main() => runApp(const TransparenciaApp());

class TransparenciaApp extends StatelessWidget {
  const TransparenciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transparência SJBV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
      ),
      home: const ContratosPage(),
    );
  }
}

class ContratosPage extends StatefulWidget {
  const ContratosPage({super.key});

  @override
  State<ContratosPage> createState() => _ContratosPageState();
}

class _ContratosPageState extends State<ContratosPage> {
  final _fonte = FontePrefeitura(http: ClienteHttp());
  late Future<Pagina<ContratoResumo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _fonte.listarContratos();
  }

  Future<void> _recarregar() async {
    setState(() => _futuro = _fonte.listarContratos());
    await _futuro;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contratos')),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<Pagina<ContratoResumo>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _Mensagem(
                icone: Icons.cloud_off,
                texto: 'Não foi possível carregar os contratos.\n${snap.error}',
                acao: _recarregar,
              );
            }
            final pagina = snap.data!;
            return ListView.separated(
              itemCount: pagina.itens.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == pagina.itens.length) {
                  return _Rodape(pagina: pagina);
                }
                final c = pagina.itens[i];
                return ListTile(
                  title: Text(c.titulo),
                  subtitle: Text(
                    c.objeto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ContratoDetalhePage(id: c.id, fonte: _fonte),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ContratoDetalhePage extends StatelessWidget {
  const ContratoDetalhePage({super.key, required this.id, required this.fonte});
  final int id;
  final FontePrefeitura fonte;

  @override
  Widget build(BuildContext context) {
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final data = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Contrato')),
      body: FutureBuilder<Contrato>(
        future: fonte.obterContrato(id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Mensagem(
              icone: Icons.error_outline,
              texto: 'Erro ao carregar: ${snap.error}',
            );
          }
          final c = snap.data!;
          String? d(DateTime? v) => v == null ? null : data.format(v);
          final linhas = <(String, String?)>[
            ('Objeto', c.objeto),
            ('Contratado', c.contratado),
            ('CPF/CNPJ', c.cpfCnpj),
            ('Licitação', c.licitacao),
            (
              'Valor',
              c.valorCentavos == null
                  ? null
                  : moeda.format(c.valorCentavos! / 100)
            ),
            ('Ano', c.ano?.toString()),
            ('Assinatura', d(c.dataAssinatura)),
            ('Início', d(c.dataInicio)),
            ('Fim', d(c.dataFim)),
            ...c.camposExtras.entries.map((e) => (e.key, e.value)),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(c.titulo, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final (rotulo, valor) in linhas)
                if (valor != null && valor.isNotEmpty)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(rotulo,
                        style: Theme.of(context).textTheme.labelMedium),
                    subtitle: Text(valor,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ),
              const SizedBox(height: 16),
              if (c.urlDocumento != null)
                FilledButton.icon(
                  onPressed: () => launchUrl(
                    c.urlDocumento!,
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Abrir documento (PDF)'),
                ),
              const SizedBox(height: 24),
              _Procedencia(url: fonte.urlContrato(id)),
            ],
          );
        },
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.pagina});
  final Pagina<ContratoResumo> pagina;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Página ${pagina.paginaAtual} de ${pagina.totalPaginas} · '
        'fonte: www.saojoao.sp.gov.br/contratos',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _Procedencia extends StatelessWidget {
  const _Procedencia({required this.url});
  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: const Text('Procedência'),
        subtitle: Text('Dado público obtido de ${url.host} em '
            '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}. '
            'Este app é independente e não representa a Prefeitura.'),
        onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.icone, required this.texto, this.acao});
  final IconData icone;
  final String texto;
  final Future<void> Function()? acao;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Icon(icone, size: 48),
        const SizedBox(height: 16),
        Text(texto, textAlign: TextAlign.center),
        if (acao != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: acao, child: const Text('Tentar de novo')),
        ],
      ],
    );
  }
}
