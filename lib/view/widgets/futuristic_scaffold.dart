import 'package:flutter/material.dart';

class FuturisticScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const FuturisticScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1020), Color(0xFF11172B), Color(0xFF0B1020)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar ?? _defaultAppBar(),
        body: Stack(children: [_GridBackground(), body]),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  PreferredSizeWidget _defaultAppBar() {
    return AppBar(
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Color(0xFF00F5FF), Color(0xFF7B61FF)],
        ).createShader(rect),
        child: const Text(
          'Pictionary.IA.RY',
          style: TextStyle(color: Colors.white),
        ),
      ),
      actions: const [],
    );
  }
}

class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(), size: Size.infinite);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF1E2A4A).withOpacity(0.25)
      ..strokeWidth = 1;

    const double step = 24;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final Paint glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x3300F5FF), Color(0x0000F5FF)],
          ).createShader(
            Rect.fromCircle(center: Offset(size.width - 80, 80), radius: 120),
          );
    canvas.drawCircle(Offset(size.width - 80, 80), 120, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
