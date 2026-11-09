import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Dados agregados de um exercício — gerados por `dados/agregar.py` a partir do
/// TCE-SP e do SICONFI e publicados no repositório. Formato: `dados/README.md`.
class Painel {
  Painel._(this._j);
  final Map<String, dynamic> _j;

  factory Painel.fromJson(Map<String, dynamic> j) => Painel._(j);

  int get ano => _j['ano'] as int;
  int? get populacao => (_j['populacao'] as num?)?.toInt();
  DateTime? get geradoEm => DateTime.tryParse(_j['geradoEm'] as String? ?? '');
  List<int> get meses => (_j['mesesDisponiveis'] as List).cast<int>();
  String? get fonteSiconfi => (_j['fontes'] as Map?)?['siconfi'] as String?;

  Map<String, dynamic> get _d => _j['despesas'] as Map<String, dynamic>;
  Map<String, dynamic> get _r => _j['receitas'] as Map<String, dynamic>;

  double get receitaTotal => (_r['total'] as num).toDouble();
  double get empenhado => ((_d['total'] as Map)['empenhado'] as num? ?? 0).toDouble();
  double get liquidado => ((_d['total'] as Map)['liquidado'] as num? ?? 0).toDouble();
  double get pago => ((_d['total'] as Map)['pago'] as num? ?? 0).toDouble();

  double? porHabitante(double v) => populacao == null ? null : v / populacao!;

  List<MesFinanceiro> get porMes {
    final rec = {for (final m in (_r['porMes'] as List)) m['mes'] as int: (m['total'] as num).toDouble()};
    return [
      for (final m in (_d['porMes'] as List))
        MesFinanceiro(
          mes: m['mes'] as int,
          receita: rec[m['mes']] ?? 0,
          empenhado: (m['empenhado'] as num? ?? 0).toDouble(),
          pago: (m['pago'] as num? ?? 0).toDouble(),
        ),
    ];
  }

  List<CategoriaReceita> get receitasPorCategoria => [
        for (final c in (_r['porCategoria'] as List))
          CategoriaReceita(
            id: c['id'] as String,
            nome: c['nome'] as String,
            explicacao: c['explicacao'] as String,
            valor: (c['valor'] as num).toDouble(),
          ),
      ];

  List<Funcao> get despesasPorFuncao => [
        for (final f in (_d['porFuncao'] as List? ?? const []))
          if (((f['empenhado'] as num?) ?? 0) > 0)
            Funcao(
              codigo: f['codigo'] as String,
              nome: f['nome'] as String,
              empenhado: (f['empenhado'] as num).toDouble(),
              liquidado: (f['liquidado'] as num?)?.toDouble(),
              pago: (f['pago'] as num?)?.toDouble(),
            ),
      ]..sort((a, b) => b.empenhado.compareTo(a.empenhado));

  List<Fornecedor> get topFornecedores => [
        for (final f in (_d['topFornecedores'] as List))
          Fornecedor(
            nome: f['nome'] as String,
            id: f['id'] as String? ?? '',
            orgao: f['orgao'] as String? ?? '',
            empenhado: (f['empenhado'] as num).toDouble(),
            pago: (f['pago'] as num? ?? 0).toDouble(),
            interno: f['interno'] as bool? ?? false,
          ),
      ];

  List<(String, double)> get porOrgao => [
        for (final o in (_d['porOrgao'] as List)) (o['orgao'] as String, (o['empenhado'] as num).toDouble()),
      ];
}

class MesFinanceiro {
  const MesFinanceiro({required this.mes, required this.receita, required this.empenhado, required this.pago});
  final int mes;
  final double receita, empenhado, pago;
}

class CategoriaReceita {
  const CategoriaReceita({required this.id, required this.nome, required this.explicacao, required this.valor});
  final String id, nome, explicacao;
  final double valor;
}

class Funcao {
  const Funcao({required this.codigo, required this.nome, required this.empenhado, this.liquidado, this.pago});
  final String codigo, nome;
  final double empenhado;
  final double? liquidado, pago;
}

class Fornecedor {
  const Fornecedor({
    required this.nome,
    required this.id,
    required this.orgao,
    required this.empenhado,
    required this.pago,
    required this.interno,
  });
  final String nome, id, orgao;
  final double empenhado, pago;

  /// Folha, previdência, repasses entre órgãos — não é "empresa contratada".
  final bool interno;

  /// Só os dígitos do CNPJ/CPF, se houver.
  String? get documento {
    final m = RegExp(r'(\d{11,14})$').firstMatch(id);
    return m?.group(1);
  }
}

/// Onde o app busca o JSON mais recente antes de cair no asset embarcado.
const urlDadosBase = 'https://raw.githubusercontent.com/marcioxtr/portal-transparencia/main/dados';

final anoPainelProvider = NotifierProvider<AnoPainelNotifier, int>(AnoPainelNotifier.new);

class AnoPainelNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  void definir(int ano) => state = ano;
}

/// Anos que o painel pode mostrar (TCE-SP publica a partir de 2014).
final anosPainelProvider = Provider<List<int>>((_) {
  final atual = DateTime.now().year;
  return [for (var a = atual; a >= 2014; a--) a];
});

final painelProvider = FutureProvider.family<Painel, int>((ref, ano) async {
  ref.keepAlive();
  final http_ = ref.watch(clienteHttpProvider);

  // 1) rede (dados atualizados diariamente pelo workflow)
  try {
    final resp = await http_.get(Uri.parse('$urlDadosBase/$ano.json'));
    if (resp.statusCode == 200) {
      return Painel.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
    }
  } on Object catch (_) {
    // cai para o asset
  }
  // 2) asset embarcado no build
  try {
    final s = await rootBundle.loadString('assets/dados/$ano.json');
    return Painel.fromJson(jsonDecode(s) as Map<String, dynamic>);
  } on Object catch (_) {
    throw PainelIndisponivel(ano);
  }
});

class PainelIndisponivel implements Exception {
  PainelIndisponivel(this.ano);
  final int ano;
  @override
  String toString() => 'Ainda não há dados agregados para $ano.';
}
