import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Carregador genérico dos JSONs publicados pelo projeto em `dados/`.
///
/// Ordem: rede (GitHub raw, atualizado diariamente pelos coletores) → asset
/// embarcado no build (primeiro uso / offline). O app nunca mostra uma tela
/// vazia por falta de rede, e nunca precisa de release para atualizar dados.
const urlDadosRaiz = 'https://raw.githubusercontent.com/marcioxtr/portal-transparencia/main/dados';

class DadosIndisponiveis implements Exception {
  DadosIndisponiveis(this.nome);
  final String nome;
  @override
  String toString() => 'Dados "$nome" indisponíveis no momento.';
}

/// `ref.watch(dadosProvider('obras'))` → Map do JSON `dados/obras.json`.
final dadosProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, nome) async {
  ref.keepAlive();
  final http = ref.watch(clienteHttpProvider);
  try {
    final resp = await http.get(Uri.parse('$urlDadosRaiz/$nome.json'));
    if (resp.statusCode == 200) {
      return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    }
  } on Object catch (_) {
    // cai para o asset
  }
  try {
    final s = await rootBundle.loadString('assets/dados/$nome.json');
    return jsonDecode(s) as Map<String, dynamic>;
  } on Object catch (_) {
    throw DadosIndisponiveis(nome);
  }
});

/// Quando o JSON foi gerado (campo `geradoEm` padrão dos coletores).
DateTime? geradoEm(Map<String, dynamic> j) => DateTime.tryParse(j['geradoEm'] as String? ?? '')?.toLocal();

// ── helpers de leitura tolerante ───────────────────────────────────────────

extension LeituraJson on Map<String, dynamic> {
  // Tolerante a números no lugar de texto (ex.: `numero: 12` vindo do SAPL).
  String str(String k, [String padrao = '']) => this[k]?.toString() ?? padrao;
  String? strOuNulo(String k) => this[k]?.toString();
  double num_(String k, [double padrao = 0]) => (this[k] as num?)?.toDouble() ?? padrao;
  double? numOuNulo(String k) => (this[k] as num?)?.toDouble();
  int int_(String k, [int padrao = 0]) => (this[k] as num?)?.toInt() ?? padrao;
  bool bool_(String k, [bool padrao = false]) => (this[k] as bool?) ?? padrao;
  DateTime? data(String k) => DateTime.tryParse(this[k] as String? ?? '');
  List<Map<String, dynamic>> lista(String k) =>
      ((this[k] as List?) ?? const []).cast<Map<String, dynamic>>();
  Map<String, dynamic> mapa(String k) => (this[k] as Map<String, dynamic>?) ?? const {};
}
