/// Utilidades de parsing para formatos brasileiros usados nos portais.
library;

final _naoDigito = RegExp(r'[^\d]');
final _dataBr = RegExp(r'(\d{2})/(\d{2})/(\d{4})');

/// `"R$ 14.231,58"` → `1423158`. Devolve `null` se não houver número.
int? parseReaisEmCentavos(String? texto) {
  if (texto == null) return null;
  final m = RegExp(r'(\d{1,3}(?:\.\d{3})*|\d+)(?:,(\d{1,2}))?').firstMatch(
    texto.replaceAll(RegExp(r'\s'), ''),
  );
  if (m == null) return null;
  final inteiros = int.parse(m.group(1)!.replaceAll(_naoDigito, ''));
  final cent = (m.group(2) ?? '00').padRight(2, '0');
  return inteiros * 100 + int.parse(cent);
}

/// `"27/03/2026"` → `DateTime(2026, 3, 27)`. Aceita texto ao redor.
DateTime? parseDataBr(String? texto) {
  if (texto == null) return null;
  final m = _dataBr.firstMatch(texto);
  if (m == null) return null;
  final d = int.parse(m.group(1)!);
  final mes = int.parse(m.group(2)!);
  final a = int.parse(m.group(3)!);
  if (mes < 1 || mes > 12 || d < 1 || d > 31) return null;
  return DateTime(a, mes, d);
}

/// Normaliza espaços/quebras de linha de texto extraído de HTML.
String limparEspacos(String s) =>
    s.replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

/// `"Paginação: página 1 de 741"` → `(1, 741)`.
(int atual, int total)? parsePaginacao(String? ariaLabel) {
  if (ariaLabel == null) return null;
  final m = RegExp(r'página\s+(\d+)\s+de\s+(\d+)', caseSensitive: false)
      .firstMatch(ariaLabel);
  if (m == null) return null;
  return (int.parse(m.group(1)!), int.parse(m.group(2)!));
}

/// Converte um rótulo tipo `"Contratado(a):"` em chave estável `contratado`.
String chaveDeRotulo(String rotulo) {
  var s = rotulo.toLowerCase().replaceAll(':', '').trim();
  const acentos = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const semAcento = 'aaaaaeeeeiiiiooooouuuuc';
  for (var i = 0; i < acentos.length; i++) {
    s = s.replaceAll(acentos[i], semAcento[i]);
  }
  s = s.replaceAll(RegExp(r'\(.*?\)'), '');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return s.replaceAll(RegExp(r'^_+|_+$'), '');
}
