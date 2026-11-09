import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../app/tema.dart';
import '../../data/providers.dart';
import '../../widgets/comuns.dart';

/// Início: o que está acontecendo agora + atalhos em linguagem cidadã.
class InicioPage extends ConsumerWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contratos = ref.watch(contratosProvider(const FiltroContratos()));
    final emendas = ref.watch(emendasProvider(1));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset('assets/logo/logo.svg', height: 28),
            const SizedBox(width: 10),
            const Text('Transparência SJBV'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sobre o app',
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(Rotas.sobre),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(contratosProvider(const FiltroContratos()));
          ref.invalidate(emendasProvider(1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Para onde vai o dinheiro de São João da Boa Vista?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Dados públicos da Prefeitura, reunidos num só lugar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const _Atalhos(),
            const SizedBox(height: 16),
            const Aviso(
              'Receitas e despesas detalhadas (2026) dependem do portal da '
              'Prefeitura, que está instável. Contratos, emendas e documentos '
              'já funcionam normalmente.',
            ),
            const SizedBox(height: 24),
            _Secao(
              titulo: 'Últimos contratos',
              verTudo: () => context.go(Rotas.contratos),
              child: contratos.when(
                skipLoadingOnRefresh: true,
                loading: () => const _Esqueleto(),
                error: (_, __) => const _Falha(),
                data: (p) => Column(
                  children: [
                    for (final c in p.itens.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.titulo),
                        subtitle: Text(c.objeto,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => context.go(Rotas.contrato(c.id)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Secao(
              titulo: 'Emendas parlamentares recentes',
              verTudo: () => context.go(Rotas.emendas),
              child: emendas.when(
                skipLoadingOnRefresh: true,
                loading: () => const _Esqueleto(),
                error: (_, __) => const _Falha(),
                data: (p) => Column(
                  children: [
                    for (final e in p.itens.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.titulo),
                        subtitle: Text('Publicada em ${dataBr(e.publicadoEm)}'),
                        onTap: () => context.go(Rotas.emenda(e.slug)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'App independente e de código aberto. Não é um canal oficial '
              'da Prefeitura. Toda tela mostra de onde o dado veio.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Atalhos extends StatelessWidget {
  const _Atalhos();

  @override
  Widget build(BuildContext context) {
    final itens = <(String, String, IconData, Color, String)>[
      ('Contratos', 'Com quem a Prefeitura contratou', Icons.description_outlined, Cores.azul, Rotas.contratos),
      ('Emendas', 'Dinheiro vindo de deputados', Icons.account_balance_outlined, Cores.verde, Rotas.emendas),
      ('Documentos', 'Balancetes, folha, relatórios', Icons.folder_outlined, Cores.laranja, Rotas.documentos),
      ('Buscar', 'Procure por empresa ou assunto', Icons.search, Cores.roxo, Rotas.buscar),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (final (titulo, sub, icone, cor, rota) in itens)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go(rota),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icone, color: cor, size: 28),
                    const Spacer(),
                    Text(titulo,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(sub,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.child, this.verTudo});
  final String titulo;
  final Widget child;
  final VoidCallback? verTudo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(titulo,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (verTudo != null)
              TextButton(onPressed: verTudo, child: const Text('Ver tudo')),
          ],
        ),
        child,
      ],
    );
  }
}

class _Esqueleto extends StatelessWidget {
  const _Esqueleto();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _Falha extends StatelessWidget {
  const _Falha();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Aviso('Fonte indisponível no momento. Puxe para atualizar.',
            icone: Icons.cloud_off_outlined),
      );
}
