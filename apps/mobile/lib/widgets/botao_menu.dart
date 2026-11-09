import 'package:flutter/material.dart';

import '../app/casca.dart';

/// Botão ☰ que abre o menu lateral da casca a partir de qualquer aba.
class BotaoMenu extends StatelessWidget {
  const BotaoMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menu',
      onPressed: () => Casca.chaveScaffold.currentState?.openDrawer(),
    );
  }
}
