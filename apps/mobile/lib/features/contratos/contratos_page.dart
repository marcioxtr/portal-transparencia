import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fontes/fontes.dart';
import 'package:go_router/go_router.dart';

import '../../app/roteador.dart';
import '../../data/providers.dart';
import '../../widgets/botao_menu.dart';
import '../../widgets/comuns.dart';

class ContratosPage extends ConsumerWidget {
  const ContratosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroContratosProvider);
    final pagina = ref.watch(contratosProvider(filtro));

    return Scaffold(
      appBar: AppBar(
        leading: const BotaoMenu(),
        title: const Text('Contratos'),
        actions: [
          IconButton(
            tooltip: 'Filtrar',
            icon: Badge(
              isLabelVisible: filtro.temFiltro,
              child: const Icon(Icons.tune),
            ),
            onPressed: () => _abrirFiltros(context, ref, filtro),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filtro.temFiltro) _ChipsFiltro(filtro: filtro),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(contratosProvider(filtro).future),
              child: Async(
                valor: pagina,
                aoTentarDeNovo: () => ref.invalidate(contratosProvider(filtro)),
                dado: (p) => _Lista(pagina: p, filtro: filtro),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFiltros(
    BuildContext context,
    WidgetRef ref,
    FiltroContratos atual,
  ) async {
    final novo = await showModalBottomSheet<FiltroContratos>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FiltroSheet(inicial: atual),
    );
    if (novo != null) {
      ref.read(filtroContratosProvider.notifier).definir(novo.copyWith(pagina: 1));
    }
  }
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.pagina, required this.filtro});
  final Pagina<ContratoResumo> pagina;
  final FiltroContratos filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pagina.itens.isEmpty) {
      return const Mensagem(
        icone: Icons.search_off,
        titulo: 'Nenhum contrato encontrado',
        texto: 'Tente outros termos ou limpe os filtros.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: pagina.itens.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == pagina.itens.length) {
          return _Paginacao(pagina: pagina, filtro: filtro);
        }
        final c = pagina.itens[i];
        return ListTile(
          title: Text(c.titulo),
          subtitle: Text(c.objeto, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Rotas.contrato(c.id)),
        );
      },
    );
  }
}

class _Paginacao extends ConsumerWidget {
  const _Paginacao({required this.pagina, required this.filtro});
  final Pagina<ContratoResumo> pagina;
  final FiltroContratos filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void ir(int p) => ref.read(filtroContratosProvider.notifier).pagina(p);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: pagina.paginaAtual > 1
                    ? () => ir(pagina.paginaAtual - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${pagina.paginaAtual} de ${pagina.totalPaginas}'),
              ),
              IconButton.filledTonal(
                onPressed: pagina.temProxima
                    ? () => ir(pagina.paginaAtual + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Próxima página',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fonte: www.saojoao.sp.gov.br/contratos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ChipsFiltro extends ConsumerWidget {
  const _ChipsFiltro({required this.filtro});
  final FiltroContratos filtro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = <(String, FiltroContratos)>[
      if (filtro.ano != null)
        ('Ano ${filtro.ano}', filtro.copyWith(limparAno: true)),
      if (filtro.tipo?.isNotEmpty ?? false)
        (filtro.tipo!, filtro.copyWith(limparTipo: true)),
      if (filtro.objeto?.isNotEmpty ?? false)
        ('Objeto: ${filtro.objeto}', filtro.copyWith(objeto: '')),
      if (filtro.razaoSocial?.isNotEmpty ?? false)
        ('Empresa: ${filtro.razaoSocial}', filtro.copyWith(razaoSocial: '')),
      if (filtro.numero?.isNotEmpty ?? false)
        ('Nº ${filtro.numero}', filtro.copyWith(numero: '')),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final (rotulo, semEste) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(rotulo),
                onDeleted: () => ref
                    .read(filtroContratosProvider.notifier)
                    .definir(semEste.copyWith(pagina: 1)),
              ),
            ),
          ActionChip(
            label: const Text('Limpar tudo'),
            onPressed: () =>
                ref.read(filtroContratosProvider.notifier).limpar(),
          ),
        ],
      ),
    );
  }
}

class _FiltroSheet extends StatefulWidget {
  const _FiltroSheet({required this.inicial});
  final FiltroContratos inicial;

  @override
  State<_FiltroSheet> createState() => _FiltroSheetState();
}

class _FiltroSheetState extends State<_FiltroSheet> {
  late final _objeto = TextEditingController(text: widget.inicial.objeto);
  late final _empresa = TextEditingController(text: widget.inicial.razaoSocial);
  late final _numero = TextEditingController(text: widget.inicial.numero);
  late int? _ano = widget.inicial.ano;
  late String? _tipo = widget.inicial.tipo;

  @override
  void dispose() {
    _objeto.dispose();
    _empresa.dispose();
    _numero.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anoAtual = DateTime.now().year;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Filtrar contratos',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _objeto,
            decoration: const InputDecoration(
              labelText: 'O que foi contratado?',
              hintText: 'ex.: merenda, asfalto, medicamentos',
              prefixIcon: Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _empresa,
            decoration: const InputDecoration(
              labelText: 'Empresa contratada',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _ano,
                  decoration: const InputDecoration(labelText: 'Ano'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    for (var a = anoAtual; a >= 2013; a--)
                      DropdownMenuItem(value: a, child: Text('$a')),
                  ],
                  onChanged: (v) => setState(() => _ano = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _numero,
                  decoration: const InputDecoration(labelText: 'Número'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _tipo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              for (final t in tiposContrato)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _tipo = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              FiltroContratos(
                objeto: _objeto.text.trim(),
                razaoSocial: _empresa.text.trim(),
                numero: _numero.text.trim(),
                ano: _ano,
                tipo: _tipo,
              ),
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
