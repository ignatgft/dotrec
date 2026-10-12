import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class DotCard extends StatelessWidget {
  const DotCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DotTokens.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.dot.surface,
        borderRadius: BorderRadius.circular(DotTokens.radiusCard),
        border: Border.all(color: context.dot.line, width: 1),
      ),
      padding: padding,
      child: child,
    );
  }
}
