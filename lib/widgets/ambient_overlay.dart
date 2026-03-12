// lib/widgets/ambient_overlay.dart
//
// AmbientOverlay — renderiza partículas e tint de fundo
// sobre o conteúdo do jogo baseado no AmbientState atual.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/ambient_state.dart';

class AmbientOverlay extends StatefulWidget {
  final Widget child;
  final bool effectsEnabled;
  const AmbientOverlay({
    super.key,
    required this.child,
    this.effectsEnabled = true,
  });

  @override
  State<AmbientOverlay> createState() => _AmbientOverlayState();
}

class _AmbientOverlayState extends State<AmbientOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;
  AmbientState _lastState = AmbientState.normal;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _controller.addListener(_tick);
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  void _initParticles(AmbientState state, Size size) {
    _particles = List.generate(state.particleCount, (_) {
      return _Particle.random(_rng, size, state);
    });
  }

  void _tick() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    for (final p in _particles) {
      p.update(size, _rng);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();

    // Não renderiza nada durante loading ou fora do jogo
    if (gp.isLoading) return widget.child;

    final state = resolveAmbientState(gp);
    final size = MediaQuery.of(context).size;

    // Reinicia partículas quando estado muda
    if (state != _lastState) {
      _lastState = state;
      _initParticles(state, size);
    }
    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      color: widget.effectsEnabled ? state.bgTint : const Color(0xFF0A0E14),
      child: Stack(
        children: [
          widget.child,
          if (widget.effectsEnabled && state.hasParticles)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    color: state.particleColor,
                    opacity: state.particleOpacity,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Partícula ──────────────────────────────────────────────────────────────

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double drift; // movimento horizontal leve
  double opacity;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
  });

  factory _Particle.random(Random rng, Size size, AmbientState state) {
    return _Particle(
      x: rng.nextDouble() * size.width,
      y: rng.nextDouble() * size.height,
      size: 1.5 + rng.nextDouble() * 3.5,
      speed:
          (state.particleSpeed * 0.4) + rng.nextDouble() * state.particleSpeed,
      drift: (rng.nextDouble() - 0.5) * 0.8,
      opacity: 0.3 + rng.nextDouble() * 0.5,
      rotation: rng.nextDouble() * 2 * pi,
      rotationSpeed: (rng.nextDouble() - 0.5) * 0.05,
    );
  }

  void update(Size size, Random rng) {
    y += speed;
    x += drift;
    rotation += rotationSpeed;

    // Reinicia no topo quando sai pela base
    if (y > size.height + 10) {
      y = -10;
      x = rng.nextDouble() * size.width;
      opacity = 0.3 + rng.nextDouble() * 0.5;
    }
    // Wrap horizontal
    if (x < -10) x = size.width + 10;
    if (x > size.width + 10) x = -10;
  }
}

// ── Painter ────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double opacity;

  const _ParticlePainter({
    required this.particles,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withOpacity((p.opacity * opacity).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      // Forma varia por tamanho — pequenas são círculos, grandes são losangos
      if (p.size < 2.5) {
        canvas.drawCircle(Offset.zero, p.size, paint);
      } else {
        final path = Path()
          ..moveTo(0, -p.size)
          ..lineTo(p.size * 0.5, 0)
          ..lineTo(0, p.size)
          ..lineTo(-p.size * 0.5, 0)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
