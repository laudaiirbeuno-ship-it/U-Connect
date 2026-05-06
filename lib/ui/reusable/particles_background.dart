import 'dart:math';
import 'package:flutter/material.dart';

/// Widget de partículas animadas para fundo
class ParticlesBackground extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double particleSize;
  final double animationSpeed;

  const ParticlesBackground({
    Key? key,
    this.particleCount = 30,
    this.particleColor = const Color(0xFF000000),
    this.particleSize = 4.0,
    this.animationSpeed = 1.0,
  }) : super(key: key);

  @override
  _ParticlesBackgroundState createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();

    // Inicializar partículas
    _particles = List.generate(
      widget.particleCount,
      (index) => Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.1 + _random.nextDouble() * 0.2,
        direction: _random.nextDouble() * 2 * pi,
        opacity: 0.1 + _random.nextDouble() * 0.3,
        size: widget.particleSize * (0.5 + _random.nextDouble() * 0.5),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(
            particles: _particles,
            animationValue: _controller.value,
            particleColor: widget.particleColor,
            speed: widget.animationSpeed,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double direction;
  double opacity;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.direction,
    required this.opacity,
    required this.size,
  });
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color particleColor;
  final double speed;

  ParticlesPainter({
    required this.particles,
    required this.animationValue,
    required this.particleColor,
    required this.speed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calcular nova posição
      final newX = particle.x + cos(particle.direction) * particle.speed * speed * 0.01;
      final newY = particle.y + sin(particle.direction) * particle.speed * speed * 0.01;

      // Aplicar movimento flutuante vertical
      final floatY = newY + sin(animationValue * 2 * pi + particle.x * 10) * 0.02;

      // Wraparound
      particle.x = newX % 1.0;
      particle.y = floatY % 1.0;

      // Variação de opacidade suave
      final opacityVariation = (sin(animationValue * 2 * pi + particle.x * 5) + 1) / 2;
      final currentOpacity = particle.opacity * (0.5 + opacityVariation * 0.5);

      // Desenhar partícula
      final paint = Paint()
        ..color = particleColor.withOpacity(currentOpacity * 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}





































