import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0.9),
        AppColors.secondary.withValues(alpha: 0.9),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
