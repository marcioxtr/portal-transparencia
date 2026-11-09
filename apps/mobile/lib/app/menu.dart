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
    // Captura o roteador ANTES de fechar o drawer: depois do pop, o `context`
    // do drawer está desativado e `context.go/push` falha silenciosamente.
    final roteador = GoRouter.of(context);
    void ir(String rota) {
      Navigator.pop(context);
      roteador.go(rota);
    }

    void empurrar(String rota) {
      Navigator.pop(context);
      roteador.push(rota);
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
                    Text('Tô de Olho', style: tt.titleLarge),
                    Text('Transparência na palma da mão', style: tt.bodySmall),
                  ]),
                ),
              ]),
            ),
            _Secao('Entender'),
            _Item(Icons.dashboard_rounded, 'Painel: para onde vai o dinheiro', () => ir(Rotas.inicio)),
            _Item(Icons.compare_arrows_rounded, 'Comparar anos e mandatos', () => empurrar(Rotas.comparar)),
            _Item(Icons.traffic_rounded, 'Saúde, educação e pessoal: limites da lei', () => empurrar(Rotas.indicadores)),
            _Item(Icons.change_circle_outlined, 'O que mudou de um ano para o outro', () => empurrar(Rotas.mudancas)),
            _Item(Icons.location_city_outlined, 'Comparar com cidades vizinhas', () => empurrar(Rotas.vizinhos)),
            _Item(Icons.help_outline_rounded, 'O que significa? (glossário)', () => empurrar(Rotas.glossario)),
            _Secao('Acompanhar'),
            _Item(Icons.construction_outlined, 'Obras no mapa', () => empurrar(Rotas.obras)),
            _Item(Icons.how_to_vote_outlined, 'Câmara: vereadores, votos, sessões e leis', () => empurrar(Rotas.camara)),
            _Item(Icons.badge_outlined, 'Salários: prefeito, vereadores, servidores', () => empurrar(Rotas.pessoal)),
            _Item(Icons.campaign_outlined, 'Avisos da cidade (trânsito, coleta, eventos)', () => empurrar(Rotas.avisos)),
            _Item(Icons.newspaper_outlined, 'Notícias por departamento', () => empurrar(Rotas.noticias)),
            _Secao('Consultar'),
            _Item(Icons.search_rounded, 'Buscar', () => ir(Rotas.buscar)),
            _Item(Icons.description_outlined, 'Contratos', () => ir(Rotas.contratos)),
            _Item(Icons.gavel_outlined, 'Chamamentos e contratações sem disputa', () => empurrar(Rotas.licitacoes)),
            _Item(Icons.account_balance_outlined, 'Emendas parlamentares', () => ir(Rotas.emendas)),
            _Item(Icons.folder_outlined, 'Documentos (balancetes, folha…)', () => ir(Rotas.documentos)),
            _Item(Icons.local_hospital_outlined, 'Serviços: saúde, escolas, departamentos', () => empurrar(Rotas.servicos)),
            _Secao('Agir'),
            _Item(Icons.record_voice_over_outlined, 'Cobrar a Prefeitura', () => empurrar(Rotas.cobrar)),
            _Item(Icons.groups_outlined, 'Participar dos conselhos', () => empurrar(Rotas.conselhos)),
            _Secao('No site oficial'),
            _Link(Icons.receipt_long_outlined, '2ª via de IPTU e certidões',
                'https://pm-saojoao.smarapd.com.br/portalservicosweb'),
            _Link(Icons.gavel_outlined, 'Licitações em andamento',
                'https://transparencia-saojoaodaboavista.smarapd.com.br/#/dinamico/7/Licitacoes'),
            _Link(Icons.menu_book_outlined, 'Leis municipais',
                'https://leismunicipais.com.br/prefeitura/sp/sao-joao-da-boa-vista'),
            _Link(Icons.delete_outline, 'Coleta seletiva e Cata-Treco',
                'https://www.saojoao.sp.gov.br/servicos/coleta-seletiva'),
            const Divider(height: 24),
            _Item(Icons.map_outlined, 'Mapa completo do site oficial', () => empurrar(Rotas.mapaSite)),
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
