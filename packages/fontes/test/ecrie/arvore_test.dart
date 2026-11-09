import 'dart:io';

import 'package:fontes/fontes.dart';
import 'package:test/test.dart';

void main() {
  final html = File('test/fixtures/ecrie/despesas-funcionarios-2026-11-08.html')
      .readAsStringSync();
  final parser = ArvoreEcrieParser(
    baseArquivos: Uri.parse('https://ecrie.com.br/home/_arq/41/'),
  );
  late NoArquivo raiz;

  setUpAll(() {
    raiz = parser.parse(
      html,
      pastaRaiz: 'rh/Despesas Mensal Com Funcionarios',
    );
  });

  test('raiz é a pasta pedida', () {
    expect(raiz.ehArquivo, isFalse);
    expect(raiz.nome, 'Despesas Mensal Com Funcionarios');
    expect(raiz.caminho, 'rh/Despesas Mensal Com Funcionarios');
  });

  test('pastas de ano em ordem natural, 2012 primeiro', () {
    final pastas = raiz.filhos.where((f) => !f.ehArquivo).map((f) => f.nome);
    expect(pastas.first, '2012');
    expect(pastas, contains('2015'));
    expect(pastas, contains('2021'));
  });

  test('subpastas aninhadas (2015/2022, 2020/COVID-19) são reconstruídas', () {
    final p2015 = raiz.filhos.firstWhere((f) => f.nome == '2015');
    expect(p2015.filhos.any((f) => f.nome == '2022' && !f.ehArquivo), isTrue);
    final p2020 = raiz.filhos.firstWhere((f) => f.nome == '2020');
    expect(
      p2020.filhos.any((f) => f.nome == 'COVID-19' && !f.ehArquivo),
      isTrue,
    );
  });

  test('todos os 305 arquivos da fixture viram folhas com URL absoluta', () {
    final arquivos = raiz.arquivos.toList();
    expect(arquivos, hasLength(305));
    final um = arquivos.firstWhere((a) => a.nome == '2013 05 Servidores.pdf');
    expect(um.caminho,
        'rh/Despesas Mensal Com Funcionarios/2013/2013 05 Servidores.pdf');
    expect(
      um.url.toString(),
      'https://ecrie.com.br/home/_arq/41/rh/Despesas%20Mensal%20Com%20Funcionarios/2013/2013%2005%20Servidores.pdf',
    );
    expect(um.extensao, 'pdf');
  });

  test('arquivos dentro de uma pasta ficam em ordem natural (meses)', () {
    final p2013 = raiz.filhos.firstWhere((f) => f.nome == '2013');
    final nomes = p2013.filhos.where((f) => f.ehArquivo).map((f) => f.nome);
    expect(nomes.first, '2013 01 Servidores.pdf');
  });

  test('catálogo tem 22 pastas com ids únicos', () {
    expect(pastasLegado, hasLength(22));
    expect(pastasLegado.map((p) => p.id).toSet(), hasLength(22));
  });

  test('FonteEcrie monta a URL da pasta com encoding correto', () {
    final f = FonteEcrie(http: ClienteHttp());
    expect(
      f.urlPasta('transparencia/Balancetes').toString(),
      'https://ecrie.com.br/home/_arq/41/Default.aspx?pasta=transparencia%2FBalancetes',
    );
  });
}
