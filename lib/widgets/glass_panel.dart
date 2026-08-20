import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/glass_theme.dart';

/// The lit field that glass panels sit on.
///
/// Frosted glass only reads as glass when there is something behind it worth
/// blurring, so this is not a flat background: it is a cool daylight field with
/// two soft blooms that the panes above pick up and diffuse.
class GlassField extends StatelessWidget {
  const GlassField({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GlassColors.paperHigh, GlassColors.paperLow],
        ),
      ),
      child: Stack(
        children: [
          // Livery red, kept faint. It tints the field JSP's colour without
          // competing with the red that carries meaning: a new job's status
          // light, and the claim action.
          const Positioned(
            right: -260,
            top: -220,
            child: _Bloom(
              color: GlassColors.bloomLivery,
              size: 820,
              opacity: 0.13,
            ),
          ),
          const Positioned(
            left: -240,
            bottom: -280,
            child: _Bloom(
              color: GlassColors.bloomSand,
              size: 860,
              opacity: 0.45,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// A frosted pane.
///
/// [glow] is the signature of this screen: a status colour diffusing out of the
/// pane's left edge, as if a light behind the glass were shining through it.
/// It carries the defect's status before any label is read.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = GlassTheme.radius,
    this.blur = GlassTheme.blur,
    this.fill = GlassColors.paneFill,
    this.glow,
    this.onTap,
  });

  /// How far the status light reaches into the pane. Fixed in pixels rather
  /// than as a fraction of the pane: a proportional glow turns into a wash
  /// across the whole card once the window is wide.
  static const double _glowReach = 190;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color fill;

  /// Colour of the light behind the pane. Null for unlit chrome.
  final Color? glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glowColor = glow;
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      // Panes cast a soft shadow on the field — the cue that says "in front
      // of", which is most of what makes glass read as glass in daylight.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1815).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: fill,
              border: GradientBoxBorder(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [GlassColors.edgeLit, GlassColors.edgeShade],
                ),
              ),
            ),
            child: Stack(
              children: [
                if (glowColor != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _glowReach,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              glowColor.withValues(alpha: 0.16),
                              glowColor.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (glowColor != null)
                  // The light source itself, at the very edge of the pane.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(width: 3, color: glowColor),
                    ),
                  ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: borderRadius,
                    child: Padding(padding: padding, child: child),
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

/// A border painted with a gradient, so a pane's edge can be lit at the top and
/// unlit at the bottom. Flutter's [Border] only takes flat colours.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1});

  final Gradient gradient;
  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;

    final inner = rect.deflate(width / 2);
    if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(inner), paint);
    } else {
      canvas.drawRect(inner, paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}
