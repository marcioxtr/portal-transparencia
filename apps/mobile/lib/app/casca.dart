import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/vidro.dart';
import 'menu.dart';

/// Casca: fundo com profundidade e menu lateral (☰). As seções principais
/// continuam como ramos do StatefulShellRoute, então cada uma mantém sua pilha
/// ao alternar pelo menu.
class Casca extends StatelessWidget {
  const Casca({super.key, required this.shell});
  final StatefulNavigationShell shell;

  /// Scaffold externo (o que tem o menu lateral). As telas das abas têm o
  /// próprio Scaffold, então `Scaffold.of(context)` não chega até aqui.
  static final chaveScaffold = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    return FundoVidro(
      child: Scaffold(
        key: chaveScaffold,
        backgroundColor: Colors.transparent,
        drawer: const MenuLateral(),
        // A barra ocupa o próprio espaço: nada fica escondido atrás dela.
        extendBody: false,
        // Navegação só pelo menu lateral (☰): nada cobre o conteúdo.
        body: shell,
      ),
    );
  }
}
