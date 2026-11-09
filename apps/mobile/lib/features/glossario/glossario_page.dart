import 'package:flutter/material.dart';

import '../../widgets/vidro.dart';

/// Um termo explicado em linguagem cidadã.
class Termo {
  const Termo(this.id, this.nome, this.curto, this.longo, {this.exemplo, this.relacionados = const []});
  final String id;
  final String nome;

  /// Uma frase.
  final String curto;

  /// Um parágrafo.
  final String longo;
  final String? exemplo;
  final List<String> relacionados;
}

const termos = <Termo>[
  Termo('receita', 'Receita (arrecadação)', 'Todo dinheiro que entra no caixa do município.',
      'Inclui impostos que você paga direto (IPTU, ISS), repasses que vêm da União e do Estado (FPM, ICMS, IPVA, SUS, FUNDEB) e outras entradas. A maior parte do dinheiro de uma cidade do porte de São João vem de repasses, não de impostos locais.',
      relacionados: ['iptu', 'fpm', 'icms']),
  Termo('despesa', 'Despesa', 'Todo dinheiro que sai.',
      'Uma despesa pública passa por três etapas obrigatórias: empenho, liquidação e pagamento. Por isso o painel mostra três números diferentes para "gasto".',
      relacionados: ['empenho', 'liquidacao', 'pago']),
  Termo('empenho', 'Empenho (comprometido)', 'A Prefeitura reservou o dinheiro para uma compra ou contrato.',
      'É a primeira etapa da despesa: o governo "promete" pagar e separa o valor no orçamento. Ainda não saiu dinheiro. Um empenho pode ser anulado se a compra não acontecer.',
      exemplo: 'A Prefeitura empenha R\$ 200 mil para comprar merenda do ano. O dinheiro está reservado, mas as entregas ainda vão acontecer.',
      relacionados: ['liquidacao', 'pago']),
  Termo('liquidacao', 'Liquidação', 'O serviço foi prestado ou o produto entregue e conferido.',
      'Segunda etapa: um servidor atesta que a Prefeitura recebeu o que comprou. Só depois disso o pagamento pode ser feito.',
      relacionados: ['empenho', 'pago']),
  Termo('pago', 'Pago', 'O dinheiro saiu de fato da conta da Prefeitura.',
      'Terceira e última etapa. É o número mais próximo do "quanto gastou de verdade". A diferença entre empenhado e pago vira "restos a pagar" para o ano seguinte.',
      relacionados: ['empenho', 'restos']),
  Termo('restos', 'Restos a pagar', 'Despesas de um ano que ficaram para pagar no ano seguinte.',
      'Acontece quando algo foi empenhado (e às vezes liquidado) mas não pago até 31 de dezembro. Um volume grande de restos a pagar pode indicar dificuldade de caixa.',
      relacionados: ['empenho', 'pago']),
  Termo('emenda', 'Emenda parlamentar', 'Dinheiro que um deputado ou senador destina do orçamento federal/estadual para a cidade.',
      'Deputados têm direito de indicar parte do orçamento para projetos em municípios. O valor vem "carimbado" para um fim (uma UBS, um asfalto, custeio da saúde). Pode ser individual (de um parlamentar) ou de bancada (vários deputados do estado). "Fundo a fundo" quer dizer que o dinheiro vai direto do fundo federal para o fundo municipal, sem convênio.',
      exemplo: 'Emenda nº 2026.71250001 — R\$ 193.600 da Bancada de São Paulo para custeio hospitalar, repasse fundo a fundo ao Fundo Municipal de Saúde.',
      relacionados: ['convenio', 'fundo_a_fundo']),
  Termo('fundo_a_fundo', 'Fundo a fundo', 'Repasse direto de um fundo federal para um fundo municipal, sem convênio.',
      'É a forma mais rápida de transferência: o dinheiro cai na conta do fundo (Saúde, Assistência) e a Prefeitura presta contas depois. Comum em emendas para a saúde.',
      relacionados: ['emenda', 'convenio']),
  Termo('convenio', 'Convênio', 'Acordo entre governos para fazer algo juntos, com dinheiro de um e execução do outro.',
      'A União ou o Estado repassa recursos, a Prefeitura executa (uma obra, por exemplo) e presta contas. Exige projeto, aprovação e fiscalização.',
      relacionados: ['emenda']),
  Termo('licitacao', 'Licitação', 'Disputa pública para a Prefeitura escolher de quem comprar.',
      'Por lei (14.133/2021), compras acima de certos valores precisam de concorrência aberta: qualquer empresa pode participar e vence a melhor proposta. As modalidades mais comuns hoje são o pregão (eletrônico) e a concorrência. Dispensa e inexigibilidade são exceções previstas em lei.',
      relacionados: ['pregao', 'ata', 'contrato']),
  Termo('pregao', 'Pregão', 'Tipo de licitação em que as empresas dão lances e vence o menor preço.',
      'Usado para bens e serviços comuns (combustível, material de escritório, limpeza). Quase sempre eletrônico. Aparece nos contratos como "PE 003/26" (pregão eletrônico nº 3 de 2026).',
      relacionados: ['licitacao']),
  Termo('ata', 'Ata de registro de preços', 'A Prefeitura "trava" um preço com um fornecedor por até 1 ano e compra conforme precisa.',
      'Não é compromisso de comprar tudo: é uma lista de preços vencedora de uma licitação, que a Prefeitura pode acionar aos poucos. Por isso o valor de uma ata é um teto, não um gasto garantido.',
      relacionados: ['licitacao', 'contrato']),
  Termo('contrato', 'Contrato e termo aditivo', 'O acordo assinado com a empresa; o aditivo é uma mudança nele.',
      'Termos aditivos prorrogam prazo ou alteram valor (até 25% para obras e serviços). Muitos aditivos seguidos no mesmo contrato merecem atenção.',
      relacionados: ['licitacao', 'ata']),
  Termo('iptu', 'IPTU', 'Imposto sobre imóveis urbanos.',
      'Cobrado de quem tem casa, apartamento ou terreno na cidade. É receita livre: a Prefeitura decide onde usar. O valor depende do valor venal do imóvel, definido na planta genérica de valores aprovada pela Câmara.',
      relacionados: ['receita', 'iss']),
  Termo('iss', 'ISS', 'Imposto sobre serviços prestados na cidade.',
      'Pago por prestadores de serviço (de oficina mecânica a hospital, de escola particular a software). Alíquota entre 2% e 5%. Segunda maior receita própria da maioria das cidades.',
      relacionados: ['receita', 'iptu']),
  Termo('itbi', 'ITBI', 'Imposto pago na compra e venda de imóveis.',
      'Incide uma vez, na transferência do imóvel, e fica com o município.'),
  Termo('cosip', 'COSIP (iluminação pública)', 'Contribuição que vem na conta de luz para pagar a iluminação das ruas.',
      'Só pode ser gasta em iluminação pública (energia, manutenção, troca por LED). Se a arrecadação da COSIP for muito maior que o gasto com iluminação, vale perguntar por quê.',
      relacionados: ['taxa']),
  Termo('taxa', 'Taxa', 'Cobrança por um serviço específico que a Prefeitura presta a você.',
      'Diferente do imposto, a taxa tem destino certo: taxa de coleta de lixo paga a coleta; taxa de alvará paga a fiscalização. Pela lei, o valor deve corresponder ao custo do serviço.',
      relacionados: ['cosip', 'iptu']),
  Termo('fpm', 'FPM', 'Fundo de Participação dos Municípios: fatia do IR e do IPI federais que a União repassa.',
      'É a principal receita de muitas cidades. O valor depende da população e cai três vezes por mês. Quando a economia desacelera, o FPM cai e a Prefeitura sente na hora.',
      relacionados: ['receita', 'icms']),
  Termo('icms', 'ICMS (cota-parte)', '25% do ICMS arrecadado no estado volta para os municípios.',
      'A fatia de cada cidade depende do quanto ela gera de valor adicionado (indústria, comércio) e de critérios estaduais. Cidade com mais empresas recebe mais.',
      relacionados: ['fpm', 'ipva']),
  Termo('ipva', 'IPVA (cota-parte)', 'Metade do IPVA dos veículos registrados na cidade fica com o município.',
      'Por isso o mês de janeiro, quando a maioria paga o IPVA, costuma ter a maior arrecadação do ano.'),
  Termo('fundeb', 'FUNDEB', 'Fundo nacional que financia a educação básica.',
      'Junta dinheiro de impostos de todos os entes e redistribui por número de alunos matriculados. Só pode ser gasto em educação; pelo menos 70% em salário de professores.',
      relacionados: ['educacao_minimo']),
  Termo('educacao_minimo', 'Mínimo constitucional (25% educação, 15% saúde)', 'A Constituição obriga a gastar pelo menos 25% da receita de impostos em educação e 15% em saúde.',
      'Se a Prefeitura não cumprir, o prefeito pode ter as contas rejeitadas pelo Tribunal de Contas. A maioria das cidades gasta bem acima do mínimo em saúde.',
      relacionados: ['fundeb', 'tce']),
  Termo('funcao', 'Função de governo (área)', 'A classificação oficial das despesas por área: Saúde, Educação, Urbanismo…',
      'São 28 funções definidas em lei federal, iguais para todos os municípios do Brasil — por isso dá para comparar cidades. No painel, "Para onde vai" usa essa classificação.'),
  Termo('orcamento', 'Orçamento (PPA, LDO, LOA)', 'O plano de quanto vai entrar e sair, aprovado pela Câmara antes do ano começar.',
      'PPA: plano de 4 anos. LDO: prioridades do ano seguinte. LOA: o orçamento detalhado do ano. Todos passam por audiência pública — qualquer cidadão pode participar e sugerir.',
      relacionados: ['dotacao']),
  Termo('dotacao', 'Dotação', 'O valor autorizado no orçamento para cada despesa.',
      'Se a Prefeitura gastou mais que a dotação, precisou de crédito suplementar (autorizado pela Câmara ou por decreto, dentro de um limite).'),
  Termo('lrf', 'Lei de Responsabilidade Fiscal (LRF)', 'A lei que impõe limites de gasto com pessoal e dívida.',
      'Gasto com pessoal não pode passar de 54% da receita corrente líquida (Prefeitura) e 6% (Câmara). A cada 4 meses a Prefeitura publica o RGF e a cada 2 o RREO — relatórios que estão em "Documentos" e no SICONFI.',
      relacionados: ['tce']),
  Termo('duodecimo', 'Duodécimo', 'O repasse mensal da Prefeitura para a Câmara (1/12 do orçamento dela).',
      'A Câmara não arrecada: recebe da Prefeitura uma fatia fixa por mês. O limite depende da população (para São João, 6% da receita do ano anterior).'),
  Termo('terceiro_setor', 'Terceiro setor / OSS', 'Entidades sem fins lucrativos que executam serviços públicos com dinheiro da Prefeitura.',
      'Santa Casa, institutos de gestão hospitalar, APAEs. Recebem por termo de colaboração, fomento ou contrato de gestão, e devem prestar contas. Em São João, a saúde é fortemente executada assim — por isso Santa Casa e institutos aparecem no topo de "Quem mais recebeu".',
      relacionados: ['contrato']),
  Termo('diaria', 'Diária', 'Valor pago a um servidor para viagem a serviço (hospedagem e alimentação).',
      'Tem tabela fixa. A lista de diárias pagas está em "Documentos".'),
  Termo('tce', 'TCE-SP (Tribunal de Contas)', 'O órgão que fiscaliza as contas de todas as prefeituras paulistas.',
      'Recebe mensalmente cada lançamento de receita e despesa (sistema AUDESP) e julga as contas do prefeito todo ano. É a fonte dos números deste painel. Parecer desfavorável do TCE pode levar à inelegibilidade.',
      relacionados: ['lrf']),
  Termo('lai', 'Lei de Acesso à Informação (LAI)', 'A lei que garante a qualquer pessoa o direito de pedir informação pública — sem dizer por quê.',
      'Lei 12.527/2011. A Prefeitura tem 20 dias para responder (prorrogáveis por mais 10). Negativa precisa ser justificada e cabe recurso. O pedido se faz pelo e-SIC.',
      relacionados: ['esic', 'ouvidoria']),
  Termo('esic', 'e-SIC', 'O canal eletrônico para fazer pedidos de informação pela LAI.',
      'Em São João funciona dentro da plataforma e-OUV. Você recebe um número de protocolo e pode acompanhar o prazo. Na aba "Cobrar" o app monta o texto do pedido para você.',
      relacionados: ['lai', 'ouvidoria']),
  Termo('ouvidoria', 'Ouvidoria', 'Onde você reclama, sugere, elogia ou denuncia.',
      'Diferente do e-SIC (que é para pedir informação), a ouvidoria é para manifestar: buraco na rua, demora no posto, servidor mal-educado. Também gera protocolo e tem prazo (30 dias).',
      relacionados: ['esic']),
  Termo('conselho', 'Conselhos municipais', 'Grupos de cidadãos e governo que fiscalizam e decidem políticas de uma área.',
      'Saúde, educação, assistência, meio ambiente, idoso, criança… São João tem mais de 20. As reuniões são públicas e a agenda está no site. É a forma mais direta de participar além do voto.'),
];

Termo? termoPorId(String id) {
  for (final t in termos) {
    if (t.id == id) return t;
  }
  return null;
}

/// Abre a explicação de um termo em folha inferior (usado em todo o app).
void abrirTermo(BuildContext context, String id) {
  final t = termoPorId(id);
  if (t == null) return;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.nome, style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(t.curto, style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(t.longo, style: Theme.of(ctx).textTheme.bodyLarge),
          if (t.exemplo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Exemplo: ${t.exemplo}', style: Theme.of(ctx).textTheme.bodyMedium),
            ),
          ],
          if (t.relacionados.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final r in t.relacionados)
                  if (termoPorId(r) != null)
                    ActionChip(
                      label: Text(termoPorId(r)!.nome),
                      onPressed: () {
                        Navigator.pop(ctx);
                        abrirTermo(context, r);
                      },
                    ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class GlossarioPage extends StatefulWidget {
  const GlossarioPage({super.key});

  @override
  State<GlossarioPage> createState() => _GlossarioPageState();
}

class _GlossarioPageState extends State<GlossarioPage> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final lista = termos.where((t) {
      if (_busca.isEmpty) return true;
      final b = _busca.toLowerCase();
      return t.nome.toLowerCase().contains(b) || t.curto.toLowerCase().contains(b) || t.longo.toLowerCase().contains(b);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('O que significa?')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Ex.: empenho, emenda, IPTU…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _busca = v.trim()),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = lista[i];
                return Aparecer(
                  indice: i.clamp(0, 8),
                  child: CartaoVidro(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    onTap: () => abrirTermo(context, t.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.nome, style: tt.titleMedium),
                        const SizedBox(height: 4),
                        Text(t.curto, style: tt.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
