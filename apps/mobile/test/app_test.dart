import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transparencia_sjbv/main.dart';

void main() {
  testWidgets('app abre na tela de contratos e lida com falha de rede',
      (tester) async {
    // No ambiente de teste o HttpClient é bloqueado (responde 400), então a
    // tela deve cair no estado de erro com botão de tentar de novo — sem
    // lançar exceção.
    await tester.pumpWidget(const TransparenciaApp());
    expect(find.text('Contratos'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Tentar de novo'), findsOneWidget);
  });
}
