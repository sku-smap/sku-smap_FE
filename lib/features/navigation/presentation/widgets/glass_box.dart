import 'dart:ui';

import 'package:flutter/material.dart';

import '../navigation_tokens.dart';

class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.radius,
    required this.child,
    this.color = NavColors.glass,
    this.shadow = NavShadows.glass,
    this.padding,
  });

  final double radius;
  final Widget child;
  final Color color;
  final List<BoxShadow> shadow;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(color: color, padding: padding, child: child),
        ),
      ),
    );
  }
}
