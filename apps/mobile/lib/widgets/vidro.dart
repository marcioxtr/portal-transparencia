import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app/tema.dart';

/// Fundo com profundidade: gradiente + "bolhas" de cor da marca flutuando
/// lentamente. Tudo o que é vidro fica em cima disso.
class FundoVidro extends StatefulWidget {
  const FundoVidro({super.key, required this.child});
  final Widget child;

  @override
  State<FundoVidro> createState() => _FundoVidroState();
}

class _FundoVidroState extends State<FundoVidro>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = Vidro.of(context);
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [v.fundoA, v.fundoB],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: _BolhasPainter(_ctrl.value, escuro ? 0.42 : 0.30),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _BolhasPainter extends CustomPainter {
  _BolhasPainter(this.t, this.opacidade);
  final double t;
  final double opacidade;

  @override
  void paint(Canvas canvas, Size size) {
    final cores = [Cores.violeta, Cores.azulCeu, Cores.rosa, Cores.verde];
    for (var i = 0; i < cores.length; i++) {
      final fase = t * 2 * math.pi + i * math.pi / 2;
      final cx = size.width * (0.5 + 0.42 * math.cos(fase * (i.isEven ? 1 : -1) + i));
      final cy = size.height * (0.45 + 0.38 * math.sin(fase * 0.7 + i * 1.3));
      final r = size.shortestSide * (0.38 + 0.08 * math.sin(fase + i));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [cores[i].withValues(alpha: opacidade), cores[i].withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BolhasPainter old) => old.t != t;
}

/// Cartão de vidro: desfoque do que está atrás, superfície translúcida,
/// borda luminosa e um brilho no topo. Toque opcional.
class CartaoVidro extends StatelessWidget {
  const CartaoVidro({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.raio = 26,
    this.onTap,
    this.forte = false,
    this.cor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double raio;
  final VoidCallback? onTap;
  final bool forte;

  /// Tingimento sutil (ex.: cor da categoria).
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final v = Vidro.of(context);
    final borda = BorderRadius.circular(raio);
    final base = forte ? v.superficieForte : v.superficie;
    final conteudo = Padding(padding: padding, child: child);

    return ClipRRect(
      borderRadius: borda,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: v.desfoque, sigmaY: v.desfoque),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borda,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(cor?.withValues(alpha: 0.10) ?? Colors.transparent, v.brilho),
                Color.alphaBlend(cor?.withValues(alpha: 0.06) ?? Colors.transparent, base),
              ],
            ),
            border: Border.all(color: v.borda, width: 1),
          ),
          child: onTap == null
              ? conteudo
              : Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: borda,
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    child: conteudo,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Pílula de vidro para chips/seletores.
class PilulaVidro extends StatelessWidget {
  const PilulaVidro({
    super.key,
    required this.rotulo,
    this.selecionada = false,
    this.onTap,
    this.icone,
    this.cor,
  });
  final String rotulo;
  final bool selecionada;
  final VoidCallback? onTap;
  final IconData? icone;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final v = Vidro.of(context);
    final c = cor ?? Cores.primaria;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selecionada ? c.withValues(alpha: 0.85) : v.superficie,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: selecionada ? c : v.borda),
        boxShadow: selecionada
            ? [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 16, color: selecionada ? Colors.white : null),
                  const SizedBox(width: 6),
                ],
                Text(
                  rotulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selecionada ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Número que "conta" até o valor quando muda. Use com `reais`/`reaisCurto`.
class NumeroAnimado extends StatelessWidget {
  const NumeroAnimado({
    super.key,
    required this.valor,
    required this.formatar,
    this.estilo,
    this.duracao = const Duration(milliseconds: 1100),
  });
  final double valor;
  final String Function(double) formatar;
  final TextStyle? estilo;
  final Duration duracao;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor),
      duration: duracao,
      curve: Curves.easeOutExpo,
      builder: (_, v, __) => Text(formatar(v), style: estilo),
    );
  }
}

/// Entrada em cascata: desliza de baixo e aparece, com atraso por índice.
class Aparecer extends StatefulWidget {
  const Aparecer({super.key, required this.child, this.indice = 0});
  final Widget child;
  final int indice;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer> {
  bool _visivel = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 + 70 * widget.indice), () {
      if (mounted) setState(() => _visivel = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visivel ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visivel ? 1 : 0,
        duration: const Duration(milliseconds: 420),
        child: widget.child,
      ),
    );
  }
}

/// Barra horizontal animada (proporção 0..1) com rótulo e valor.
class BarraProporcao extends StatelessWidget {
  const BarraProporcao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.proporcao,
    required this.cor,
    this.onTap,
    this.sub,
  });
  final String rotulo;
  final String valor;
  final double proporcao;
  final Color cor;
  final VoidCallback? onTap;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(rotulo, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text(valor, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            if (sub != null)
              Text(sub!, style: tt.bodySmall?.copyWith(color: tt.bodySmall?.color?.withValues(alpha: 0.7))),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 8, color: Vidro.of(context).superficie),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: proporcao.clamp(0, 1)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, p, __) => FractionallySizedBox(
                      widthFactor: p,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cor, cor.withValues(alpha: 0.65)]),
                          boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.45), blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Esqueleto brilhante para carregamento.
class Esqueleto extends StatefulWidget {
  const Esqueleto({super.key, this.altura = 120});
  final double altura;

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = Vidro.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: widget.altura,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _c.value, 0),
            end: Alignment(0 + 2 * _c.value, 0),
            colors: [v.superficie, v.superficieForte, v.superficie],
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho de seção com título e ação opcional.
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.titulo, {super.key, this.subtitulo, this.acao, this.rotuloAcao = 'Ver tudo'});
  final String titulo;
  final String? subtitulo;
  final VoidCallback? acao;
  final String rotuloAcao;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tt.titleLarge),
                if (subtitulo != null)
                  Text(subtitulo!, style: tt.bodySmall?.copyWith(color: tt.bodySmall?.color?.withValues(alpha: 0.7))),
              ],
            ),
          ),
          if (acao != null) TextButton(onPressed: acao, child: Text(rotuloAcao)),
        ],
      ),
    );
  }
}
