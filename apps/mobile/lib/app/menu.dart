import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../widgets/comuns.dart';
import 'roteador.dart';

/// Menu lateral (hambúrguer): tudo o que o app tem + atalhos para o que só
/// existe no site oficial.
class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    void ir(String rota) {
      Navigator.pop(context);
      context.go(rota);
    }

    void empurrar(String rota) {
      Navigator.pop(context);
      context.push(rota);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                SvgPicture.asset('assets/logo/logo.svg', height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Transparência SJBV', style: tt.titleLarge),
                    Text('app cidadão · código aberto', style: tt.bodySmall),
                  ]),
                ),
              ]),
            ),
            _Secao('Entender'),
            _Item(Icons.dashboard_rounded, 'Painel: para onde vai o dinheiro', () => ir(Rotas.inicio)),
            _Item(Icons.help_outline_rounded, 'O que significa? (glossário)', () => empurrar(Rotas.glossario)),
            _Secao('Consultar'),
            _Item(Icons.search_rounded, 'Buscar', () => ir(Rotas.buscar)),
            _Item(Icons.description_outlined, 'Contratos', () => ir(Rotas.contratos)),
            _Item(Icons.account_balance_outlined, 'Emendas parlamentares', () => ir(Rotas.emendas)),
            _Item(Icons.folder_outlined, 'Documentos (balancetes, folha…)', () => ir(Rotas.documentos)),
            _Secao('Agir'),
            _Item(Icons.record_voice_over_outlined, 'Cobrar a Prefeitura', () => empurrar(Rotas.cobrar)),
            _Secao('No site oficial'),
            _Link(Icons.receipt_long_outlined, '2ª via de IPTU e certidões',
                'https://pm-saojoao.smarapd.com.br/portalservicosweb'),
            _Link(Icons.gavel_outlined, 'Licitações em andamento',
                'https://transparencia-saojoaodaboavista.smarapd.com.br/#/dinamico/7/Licitacoes'),
            _Link(Icons.work_outline, 'Concursos e processos seletivos',
                'https://www.saojoao.sp.gov.br/transparencia/concursos-publicos'),
            _Link(Icons.newspaper_outlined, 'Notícias da Prefeitura', 'https://www.saojoao.sp.gov.br/noticias'),
            _Link(Icons.menu_book_outlined, 'Leis municipais',
                'https://leismunicipais.com.br/prefeitura/sp/sao-joao-da-boa-vista'),
            _Link(Icons.how_to_vote_outlined, 'Câmara Municipal', 'https://www.saojoaodaboavista.sp.leg.br/'),
            _Link(Icons.delete_outline, 'Coleta seletiva e Cata-Treco',
                'https://www.saojoao.sp.gov.br/servicos/coleta-seletiva'),
            _Link(Icons.traffic_outlined, 'Interdições de trânsito',
                'https://www.saojoao.sp.gov.br/departamentos/seguranca-e-transito/interdicoes-no-momento'),
            const Divider(height: 24),
            _Item(Icons.info_outline, 'Sobre o app', () => empurrar(Rotas.sobre)),
            _Link(Icons.code, 'Código-fonte (GitHub)', 'https://github.com/marcioxtr/portal-transparencia'),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.t);
  final String t;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(t.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
      );
}

class _Item extends StatelessWidget {
  const _Item(this.icone, this.rotulo, this.onTap);
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icone),
        title: Text(rotulo),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      );
}

class _Link extends StatelessWidget {
  const _Link(this.icone, this.rotulo, this.url);
  final IconData icone;
  final String rotulo;
  final String url;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icone),
        title: Text(rotulo),
        trailing: const Icon(Icons.open_in_new, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () => abrirUrl(Uri.parse(url)),
      );
}
