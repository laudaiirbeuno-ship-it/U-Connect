import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';

/// Widget de fundo animado que cria um efeito de gradiente subindo e descendo
/// 
/// Este widget deve ser usado como primeiro elemento em um Stack dentro do body do Scaffold
class AnimatedBackground extends StatefulWidget {
  /// Opacidade do efeito (0.0 a 1.0), padrão: 0.03
  final double opacity;
  
  /// Velocidade da animação (duração em segundos), padrão: 8.0
  final double animationDuration;

  const AnimatedBackground({
    Key? key,
    this.opacity = 0.03,
    this.animationDuration = 8.0,
  }) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.animationDuration.toInt()),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Animação removida - retornar widget vazio
    return SizedBox.shrink();
  }
}

class _AnimatedBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double opacity;

  _AnimatedBackgroundPainter({
    required this.animationValue,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Criar gradiente que se move verticalmente
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0),
        color.withOpacity(opacity),
        color.withOpacity(opacity * 0.5),
        color.withOpacity(opacity),
        color.withOpacity(0),
      ],
      stops: [
        0.0,
        0.3 + (animationValue * 0.2),
        0.5 + (animationValue * 0.1),
        0.7 + (animationValue * 0.2),
        1.0,
      ],
    );

    // Criar gradiente circular para efeito mais suave
    final radialGradient = RadialGradient(
      center: Alignment(
        0.0,
        animationValue * 0.5,
      ),
      radius: 1.5,
      colors: [
        color.withOpacity(opacity * 0.8),
        color.withOpacity(opacity * 0.3),
        color.withOpacity(0),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    // Desenhar gradiente linear
    final linearPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      linearPaint,
    );

    // Desenhar gradiente radial para efeito de ondas
    final radialPaint = Paint()
      ..shader = radialGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    
    // Desenhar múltiplos círculos para efeito de ondas
    for (int i = 0; i < 3; i++) {
      final offset = animationValue * (size.height * 0.3) + (size.height * 0.25 * i);
      final radius = size.width * 0.8;
      
      canvas.drawCircle(
        Offset(size.width / 2, offset.clamp(0, size.height)),
        radius,
        radialPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}





































