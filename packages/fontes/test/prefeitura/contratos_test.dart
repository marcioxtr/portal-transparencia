import 'dart:io';

import 'package:fontes/fontes.dart';
import 'package:test/test.dart';

String fixture(String nome) =>
    File('test/fixtures/prefeitura/$nome').readAsStringSync();

void main() {
  const parser = ContratosParser();

  group('lista de contratos (fixture 2026-11-08)', () {
    late Pagina<ContratoResumo> pagina;
    setUpAll(() {
      pagina = parser.parseLista(fixture('contratos-lista-2026-11-08.html'));
    });

    test('extrai 10 itens com id, título e objeto', () {
      expect(pagina.itens, hasLength(10));
      final primeiro = pagina.itens.firstWhere((c) => c.id == 26048);
      expect(primeiro.titulo, 'Ata de Registro de Preços 77/26');
      expect(primeiro.objeto,
          'Registro de Preços para Aquisição de Materiais Hidraulicos.');
    });

    test('lê paginação do aria-label', () {
      expect(pagina.paginaAtual, 1);
      expect(pagina.totalPaginas, 741);
      expect(pagina.temProxima, isTrue);
    });

    test('ids são únicos', () {
      expect(pagina.itens.map((c) => c.id).toSet(), hasLength(10));
    });
  });

  group('detalhe de contrato 26048', () {
    late Contrato c;
    setUpAll(() {
      c = parser.parseDetalhe(
        fixture('contrato-detalhe-26048-2026-11-08.html'),
        id: 26048,
      );
    });

    test('campos principais', () {
      expect(c.titulo, 'Ata de Registro de Preços 77/26');
      expect(c.objeto,
          'Registro de Preços para Aquisição de Materiais Hidraulicos.');
      expect(c.contratado, 'HIDROSANEAMENTO LTDA– EPP');
      expect(c.cpfCnpj, '05.958.760/0001-20');
      expect(c.licitacao, 'PE 003/26');
      expect(c.valorCentavos, 1423158);
      expect(c.ano, 2026);
    });

    test('datas', () {
      expect(c.dataAssinatura, DateTime(2026, 3, 27));
      expect(c.dataInicio, DateTime(2026, 3, 27));
      expect(c.dataFim, DateTime(2027, 3, 26));
    });

    test('documento', () {
      expect(
        c.urlDocumento.toString(),
        'https://ecrie.com.br/Sistema/Conteudos/Contratos/c41_30032026155816.pdf',
      );
    });

    test('nenhum campo conhecido sobra em camposExtras', () {
      expect(c.camposExtras, isEmpty, reason: '${c.camposExtras}');
    });
  });

  test('URLs de listagem só incluem filtros preenchidos', () {
    final fonte = FontePrefeitura(http: ClienteHttp());
    expect(fonte.urlContratos().toString(),
        'https://www.saojoao.sp.gov.br/contratos');
    expect(
      fonte.urlContratos(ano: 2026, pagina: 2, tipo: 'Contrato').query,
      'ano=2026&tipo=Contrato&pagina=2',
    );
  });
}
