import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:transparencia_sjbv/app/app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('abre no Painel com dados embarcados e navega pelas abas sem rede',
      (tester) async {
    // No ambiente de teste o HttpClient é bloqueado (responde 400): o painel
    // deve cair para o asset embarcado e as listas para o estado de erro.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(retry: (_, __) => null, child: const TransparenciaApp()));
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Transparência SJBV'), findsOneWidget);
    expect(find.textContaining('Para onde vai o dinheiro'), findsOneWidget);
    // Primeiro cartão do painel (vindo do asset embarcado dados/<ano>.json).
    expect(find.text('Entrou'), findsOneWidget);
    expect(find.text('Saiu (pago)'), findsOneWidget);

    // Navegação só pelo menu ☰
    Future<void> abrirPeloMenu(String rotulo) async {
      await tester.tap(find.byTooltip('Menu'));
      await tester.pump(const Duration(seconds: 1));
      final item = find.text(rotulo);
      await tester.scrollUntilVisible(item, 120, scrollable: find.byType(Scrollable).last, maxScrolls: 30);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.ancestor(of: item, matching: find.byType(ListTile)));
      await tester.pump(); // fecha o drawer e troca de ramo
      await tester.pump(const Duration(milliseconds: 600));
    }

    await abrirPeloMenu('Documentos (balancetes, folha…)');
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Despesas com Funcionários'), findsOneWidget);

    await abrirPeloMenu('Contratos');
    await tester.pump(); // constrói a aba (dispara a requisição)
    await tester.pump(const Duration(seconds: 4)); // conclui a requisição (400 → erro)
    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });
}
