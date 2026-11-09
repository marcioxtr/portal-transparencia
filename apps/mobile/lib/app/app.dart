import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'roteador.dart';
import 'tema.dart';

class TransparenciaApp extends ConsumerWidget {
  const TransparenciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roteador = ref.watch(roteadorProvider);
    return MaterialApp.router(
      title: 'Tô de Olho',
      debugShowCheckedModeBanner: false,
      theme: temaClaro(),
      darkTheme: temaEscuro(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: roteador,
    );
  }
}
