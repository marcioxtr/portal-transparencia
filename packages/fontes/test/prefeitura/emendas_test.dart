import 'dart:io';

import 'package:fontes/fontes.dart';
import 'package:test/test.dart';

String fixture(String nome) =>
    File('test/fixtures/prefeitura/$nome').readAsStringSync();

void main() {
  const parser = EmendasParser();

  group('lista de emendas (fixture 2026-11-08)', () {
    late Pagina<EmendaResumo> pagina;
    setUpAll(() {
      pagina = parser.parseLista(fixture('emendas-lista-2026-11-08.html'));
    });

    test('12 itens por página, 9 páginas, 103 no total', () {
      expect(pagina.itens, hasLength(12));
      expect(pagina.totalPaginas, 9);
      expect(pagina.totalRegistros, 103);
    });

    test('slug, título e data de publicação', () {
      final e = pagina.itens.firstWhere(
        (e) => e.slug == 'emenda-n-202550410002',
      );
      expect(e.titulo, 'Emenda nº 2026.71250001');
      expect(e.publicadoEm, DateTime(2026, 7, 2));
    });

    test('slug com sufixo "recurso não liberado" é preservado', () {
      expect(
        pagina.itens.any((e) => e.slug.endsWith('-recurso-nao-liberado')),
        isTrue,
      );
    });
  });

  group('detalhe da emenda 2026.71250001', () {
    late Emenda e;
    setUpAll(() {
      e = parser.parseDetalhe(
        fixture('emenda-detalhe-202550410002-2026-11-08.html'),
        slug: 'emenda-n-202550410002',
      );
    });

    test('campos', () {
      expect(e.titulo, 'Emenda nº 2026.71250001');
      expect(e.numero, '2026.71250001');
      expect(e.origemRecurso, 'Federal');
      expect(e.tipo, 'Bancada');
      expect(e.autoria, 'Bancada de São Paulo');
      expect(e.formaRepasse, 'Fundo a fundo');
      expect(e.valorCentavos, 19360000);
      expect(e.objetivo, startsWith('Incremento temporário ao Custeio'));
      expect(e.funcaoGoverno, '10 – Saúde');
      expect(e.beneficiario, 'Fundo Municipal de Saúde');
    });

    test('nenhum campo conhecido sobra em camposExtras', () {
      expect(e.camposExtras, isEmpty, reason: '${e.camposExtras}');
    });
  });
}
