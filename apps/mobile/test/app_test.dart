import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:transparencia_sjbv/app/app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('abre no Início e navega pelas abas sem rede', (tester) async {
    // No ambiente de teste o HttpClient é bloqueado (responde 400): as telas
    // devem degradar para o estado de erro, nunca lançar exceção.
    await tester.pumpWidget(const ProviderScope(child: TransparenciaApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Transparência SJBV'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Contratos').last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Não foi possível carregar'), findsOneWidget);

    await tester.tap(find.text('Documentos').last);
    await tester.pumpAndSettle();
    expect(find.text('Balancetes'), findsOneWidget);

    await tester.tap(find.text('Emendas').last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Emendas parlamentares'), findsOneWidget);
  });
}
