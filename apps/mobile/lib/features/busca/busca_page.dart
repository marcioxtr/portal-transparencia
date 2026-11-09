import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fontes/fontes.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../data/providers.dart';
import '../../widgets/botao_menu.dart';
import '../../widgets/comuns.dart';

/// Busca unificada: um campo, várias fontes.
/// Hoje: contratos por objeto e por empresa (site da Prefeitura) + emendas
/// (filtro local). SmarAPD `BuscaDocumento/busca` entra quando a API voltar.
class BuscaPage extends ConsumerStatefulWidget {
  const BuscaPage({super.key});

  @override
  ConsumerState<BuscaPage> createState() => _BuscaPageState();
}

class _BuscaPageState extends ConsumerState<BuscaPage> {
  final _ctrl = TextEditingController();
  String _termo = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BotaoMenu(), title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Empresa, assunto, número…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _termo.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _termo = '');
                        },
                      ),
              ),
              onSubmitted: (v) => setState(() => _termo = v.trim()),
            ),
          ),
          Expanded(
            child: _termo.length < 3
                ? const _Dicas()
                : _Resultados(termo: _termo),
          ),
        ],
      ),
    );
  }
}

class _Dicas extends StatelessWidget {
  const _Dicas();

  @override
  Widget build(BuildContext context) {
    final exemplos = ['merenda', 'asfalto', 'medicamentos', 'iluminação', 'transporte', 'saúde'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Experimente', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in exemplos)
              ActionChip(
                label: Text(e),
                onPressed: () {
                  final state =
                      context.findAncestorStateOfType<_BuscaPageState>()!;
                  state._ctrl.text = e;
                  // ignore: invalid_use_of_protected_member
                  state.setState(() => state._termo = e);
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Aviso(
          'A busca procura em contratos (objeto e empresa) e emendas. '
          'Digite pelo menos 3 letras e toque em buscar no teclado.',
        ),
      ],
    );
  }
}

class _Resultados extends ConsumerWidget {
  const _Resultados({required this.termo});
  final String termo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final porObjeto =
        ref.watch(contratosProvider(FiltroContratos(objeto: termo)));
    final porEmpresa =
        ref.watch(contratosProvider(FiltroContratos(razaoSocial: termo)));
    final emendas = ref.watch(todasEmendasProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _Bloco(
          titulo: 'Contratos — pelo que foi contratado',
          valor: porObjeto,
          vazio: 'Nenhum contrato com "$termo" no objeto.',
          verTudo: () {
            ref
                .read(filtroContratosProvider.notifier)
                .definir(FiltroContratos(objeto: termo));
            context.go(Rotas.contratos);
          },
          itens: (p) => [
            for (final c in p.itens.take(5))
              ListTile(
                title: Text(c.titulo),
                subtitle: Text(c.objeto,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => context.go(Rotas.contrato(c.id)),
              ),
          ],
        ),
        _Bloco(
          titulo: 'Contratos — pela empresa',
          valor: porEmpresa,
          vazio: 'Nenhuma empresa com "$termo".',
          verTudo: () {
            ref
                .read(filtroContratosProvider.notifier)
                .definir(FiltroContratos(razaoSocial: termo));
            context.go(Rotas.contratos);
          },
          itens: (p) => [
            for (final c in p.itens.take(5))
              ListTile(
                title: Text(c.titulo),
                subtitle: Text(c.objeto,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => context.go(Rotas.contrato(c.id)),
              ),
          ],
        ),
        _BlocoEmendas(termo: termo, valor: emendas),
      ],
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.titulo,
    required this.valor,
    required this.itens,
    required this.vazio,
    this.verTudo,
  });
  final String titulo;
  final AsyncValue<Pagina<ContratoResumo>> valor;
  final List<Widget> Function(Pagina<ContratoResumo>) itens;
  final String vazio;
  final VoidCallback? verTudo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(titulo,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              valor.maybeWhen(
                data: (p) => p.totalPaginas > 0 && verTudo != null
                    ? TextButton(
                        onPressed: verTudo,
                        child: Text(p.totalPaginas > 1
                            ? 'Ver todos (${p.totalPaginas} páginas)'
                            : 'Ver todos'),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        valor.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.all(16),
            child: Aviso('Fonte indisponível no momento.',
                icone: Icons.cloud_off_outlined),
          ),
          data: (p) => p.itens.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(vazio,
                      style: Theme.of(context).textTheme.bodySmall),
                )
              : Column(children: itens(p)),
        ),
      ],
    );
  }
}

class _BlocoEmendas extends StatelessWidget {
  const _BlocoEmendas({required this.termo, required this.valor});
  final String termo;
  final AsyncValue<List<EmendaResumo>> valor;

  @override
  Widget build(BuildContext context) {
    return valor.maybeWhen(
      data: (lista) {
        final achadas = lista
            .where((e) => e.titulo.toLowerCase().contains(termo.toLowerCase()))
            .take(5)
            .toList();
        if (achadas.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text('Emendas parlamentares',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final e in achadas)
              ListTile(
                title: Text(e.titulo),
                subtitle: Text('Publicada em ${dataBr(e.publicadoEm)}'),
                onTap: () => context.go(Rotas.emenda(e.slug)),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
