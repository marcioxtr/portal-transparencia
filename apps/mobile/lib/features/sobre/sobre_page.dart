import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../widgets/comuns.dart';

class SobrePage extends StatelessWidget {
  const SobrePage({super.key});

  static final _repo =
      Uri.parse('https://github.com/NeoFusa/portal-transparencia');
  static final _portal = Uri.parse('https://www.saojoao.sp.gov.br/transparencia');
  static final _lai = Uri.parse(
      'https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2011/lei/l12527.htm');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: SvgPicture.asset('assets/logo/logo.svg', height: 120)),
          const SizedBox(height: 16),
          Text('Transparência SJBV',
              textAlign: TextAlign.center, style: tt.headlineSmall),
          Text('App cidadão, independente e de código aberto',
              textAlign: TextAlign.center, style: tt.bodyMedium),
          const SizedBox(height: 24),
          const Aviso(
            'Este aplicativo NÃO é da Prefeitura de São João da Boa Vista. '
            'Ele lê os dados que a Prefeitura já publica por obrigação legal '
            'e os reorganiza para caber na palma da mão. Toda tela mostra de '
            'onde o dado veio e quando foi obtido.',
            icone: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 24),
          Text('Por que existe', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(
            'O portal oficial espalha a transparência municipal em cinco '
            'sistemas de três fornecedores diferentes. Dado público só é '
            'transparência de verdade quando qualquer pessoa consegue ver. '
            'Como peças de um quebra-cabeça, a comunidade monta a imagem '
            'inteira junta — e o centro fica aberto para todos olharem.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('De onde vêm os dados', style: tt.titleMedium),
          const SizedBox(height: 8),
          const _Fonte('Site da Prefeitura (www.saojoao.sp.gov.br)',
              'Contratos, emendas parlamentares e documentos até 2022.'),
          const _Fonte('Portal SmarAPD (2026 em diante)',
              'Receitas, despesas, servidores e licitações — em integração.'),
          const _Fonte('Portal Intertec (2023 a 2025)',
              'Fora do ar na fonte oficial. Alternativa em estudo: TCE-SP.'),
          const SizedBox(height: 24),
          Text('Privacidade', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(
            'O app não coleta nenhum dado seu. Não há cadastro, rastreamento '
            'nem anúncios. O que você consulta fica só no seu aparelho.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Código-fonte e como contribuir'),
            subtitle: Text(_repo.host + _repo.path),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => abrirUrl(_repo),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Portal da Transparência oficial'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => abrirUrl(_portal),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Lei de Acesso à Informação (12.527/2011)'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => abrirUrl(_lai),
          ),
          const SizedBox(height: 24),
          Text('Licença MIT · feito pela comunidade',
              textAlign: TextAlign.center, style: tt.bodySmall),
        ],
      ),
    );
  }
}

class _Fonte extends StatelessWidget {
  const _Fonte(this.nome, this.desc);
  final String nome;
  final String desc;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.source_outlined),
        title: Text(nome),
        subtitle: Text(desc),
      );
}
