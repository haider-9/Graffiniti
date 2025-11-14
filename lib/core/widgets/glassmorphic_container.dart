import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final double blur;
  final double opacity;
  final Border? border;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.backgroundColor,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border:
                border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
