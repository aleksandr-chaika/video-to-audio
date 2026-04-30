import 'package:flutter/material.dart';

/// Красивая stagger-анимация появления контента: fade + slide-up + scale.
/// На старте экрана дочерние элементы появляются последовательно с
/// небольшим offset delay, что создаёт ощущение «оживления» интерфейса.
///
/// Применение:
/// ```dart
/// FadeSlideIn(delay: Duration(milliseconds: 80), child: AppLogo())
/// ```
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.offsetY = 28,
    this.beginScale = 0.96,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double beginScale;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: widget.curve);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offsetY / 100),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  late final Animation<double> _scale = Tween<double>(
    begin: widget.beginScale,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
