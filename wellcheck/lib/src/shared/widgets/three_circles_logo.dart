import 'package:flutter/material.dart';

/// Simple three-circles logo reminiscent of overlapping rings.
/// Circles are outlined and slightly overlapped horizontally.
class ThreeCirclesLogo extends StatelessWidget {
  const ThreeCirclesLogo({
    super.key,
    this.size = 96,
    this.color = Colors.white,
    this.strokeWidth = 4,
    this.overlap = 12,
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final circleSize = size;
    final spacing = circleSize - overlap;
    return SizedBox(
      height: circleSize,
      width: circleSize + 2 * spacing,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          _Ring(size: circleSize, color: color, strokeWidth: strokeWidth),
          Positioned(
            left: spacing,
            child: _Ring(size: circleSize, color: color, strokeWidth: strokeWidth),
          ),
          Positioned(
            left: 2 * spacing,
            child: _Ring(size: circleSize, color: color, strokeWidth: strokeWidth),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color, required this.strokeWidth});

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
      ),
    );
  }
}

