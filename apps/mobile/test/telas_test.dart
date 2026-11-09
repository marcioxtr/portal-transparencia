import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:intl/date_symbol_data_local.dart';
import 'package:transparencia_sjbv/app/app.dart';
import 'package:transparencia_sjbv/app/roteador.dart';

/// Teste de fumaça: abre CADA tela do app com os dados embarcados
/// (assets/dados/*.json — a rede é bloqueada nos testes e responde 400) e
/// verifica que ela renderiza um texto esperado sem lançar exceção nem
/// estourar layout. Se um coletor mudar o formato do JSON e quebrar uma tela,
/// este teste pega antes de chegar à loja.
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  // flutter_map guarda tiles em cache via path_provider, que não existe no
  // ambiente de teste; respondemos com um diretório temporário.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => '/tmp/to_de_olho_test_cache',
    );
  });

  // rota → texto que precisa aparecer
  const telas = <String, String>{
    Rotas.inicio: 'Entrou',
    Rotas.obras: 'Obras',
    Rotas.camara: 'Vereadores',
    Rotas.pessoal: 'Quanto ganham',
    Rotas.mapaSite: 'site oficial',
    Rotas.comparar: 'Comparar',
    Rotas.indicadores: 'Três regras',
    Rotas.mudancas: 'mudou',
    Rotas.vizinhos: 'Por habitante',
    Rotas.cidade: 'Hoje na cidade',
    Rotas.avisos: 'Avisos da cidade',
    Rotas.noticias: 'Notícias',
    Rotas.servicos: 'Saúde',
    Rotas.conselhos: 'Conselho',
    Rotas.licitacoes: 'Licitações e parcerias',
    Rotas.glossario: 'Empenho',
    Rotas.cobrar: 'e-SIC',
    Rotas.sobre: 'Por que existe',
    Rotas.documentos: 'Balancetes',
    Rotas.emendas: 'Emendas parlamentares',
    Rotas.contratos: 'Contratos',
    Rotas.buscar: 'Buscar',
  };

  for (final entrada in telas.entries) {
    testWidgets('tela ${entrada.key} renderiza', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400); // celular comum (360×800 lógicos)
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // Pré-carrega os JSONs embarcados com I/O real; a partir daí o
      // rootBundle serve do cache e o provider resolve dentro dos pumps.
      await tester.runAsync(() async {
        for (final n in ['2026', '2025', 'obras', 'camara', 'avisos', 'noticias', 'licitacoes', 'servicos', 'indicadores', 'mapa_site', 'pessoal']) {
          try {
            await rootBundle.loadString('assets/dados/$n.json');
          } on Object catch (_) {}
        }
      });
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [rotaInicialProvider.overrideWithValue(entrada.key)],
          child: const TransparenciaApp(),
        ),
      );
      // A leitura do asset é I/O real (não obedece ao relógio falso do teste):
      // runAsync deixa esse I/O acontecer; pump avança animações/timers.
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
        await tester.pump(const Duration(milliseconds: 600));
      }

      expect(tester.takeException(), isNull, reason: 'exceção em ${entrada.key}');
      expect(
        find.textContaining(entrada.value, findRichText: true),
        findsWidgets,
        reason: 'texto "${entrada.value}" não encontrado em ${entrada.key}',
      );
    });
  }
}
