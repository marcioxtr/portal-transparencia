import 'package:fontes/fontes.dart';
import 'package:test/test.dart';

void main() {
  group('parseReaisEmCentavos', () {
    test('formatos comuns', () {
      expect(parseReaisEmCentavos('R\$ 14.231,58'), 1423158);
      expect(parseReaisEmCentavos('R\$ 193.600,00'), 19360000);
      expect(parseReaisEmCentavos('1.000.000,5'), 100000050);
      expect(parseReaisEmCentavos('R\$ 0,99'), 99);
      expect(parseReaisEmCentavos('350'), 35000);
    });
    test('sem número', () {
      expect(parseReaisEmCentavos('—'), isNull);
      expect(parseReaisEmCentavos(null), isNull);
    });
  });

  group('parseDataBr', () {
    test('com texto ao redor', () {
      expect(parseDataBr(' Publicado: 02/07/2026'), DateTime(2026, 7, 2));
    });
    test('inválida', () {
      expect(parseDataBr('32/13/2026'), isNull);
      expect(parseDataBr('2026-07-02'), isNull);
    });
  });

  test('parsePaginacao', () {
    expect(parsePaginacao('Paginação: página 3 de 741'), (3, 741));
    expect(parsePaginacao(null), isNull);
  });

  test('chaveDeRotulo', () {
    expect(chaveDeRotulo('Contratado(a):'), 'contratado');
    expect(chaveDeRotulo('CPF/CNPJ:'), 'cpf_cnpj');
    expect(chaveDeRotulo('Objetivo/Finalidade:'), 'objetivo_finalidade');
    expect(chaveDeRotulo('Função de Governo:'), 'funcao_de_governo');
    expect(chaveDeRotulo('Número da Emenda: '), 'numero_da_emenda');
  });

  test('SmarapdEndpoints.download codifica o nome', () {
    expect(
      SmarapdEndpoints.download('Relatório 1.pdf', inline: true),
      'filemanager/pai/download?nomeArquivo=Relat%C3%B3rio+1.pdf&isInlineContent=true',
    );
  });
}
