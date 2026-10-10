import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Круглая карточка с тонкой рамкой 0,5 dp, радиус 20.
class DotCard extends StatelessWidget {
  const DotCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final DotColors dot = context.dot;
    return Container(
      padding: padding ?? const EdgeInsets.all(DotTokens.lg),
      decoration: BoxDecoration(
        color: dot.surface,
        borderRadius: BorderRadius.circular(DotTokens.radiusCard),
        border: Border.all(color: dot.line, width: DotTokens.hairline),
      ),
      child: child,
    );
  }
}

/// Круглый переключатель 48 dp. Активное — заливка fg (красный только для записи).
class DotSwitch extends StatelessWidget {
  const DotSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final DotColors dot = context.dot;
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            toggled: value,
            enabled: enabled,
            label: label,
            child: GestureDetector(
              onTap: enabled && onChanged != null
                  ? () => onChanged!(!value)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: DotTokens.chipSelectMs),
                width: 64,
                height: DotTokens.touchMin,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: value ? dot.fg : Colors.transparent,
                  borderRadius: BorderRadius.circular(DotTokens.radiusPill),
                  border: Border.all(
                    color: dot.line,
                    width: DotTokens.hairline,
                  ),
                ),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: value ? dot.onFg : dot.fgMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: DotTokens.sm),
            Flexible(child: Text(label!, style: const TextStyle(fontSize: 13))),
          ],
        ],
      ),
    );
  }
}

/// Таймер точечным шрифтом, tabular figures, без дёргания ширины.
class DotTimer extends StatelessWidget {
  const DotTimer({super.key, required this.elapsed});

  final Duration elapsed;

  static String format(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    String p(int v) => v.toString().padLeft(2, '0');
    if (h > 0) return '${p(h)}:${p(m)}:${p(s)}';
    return '${p(m)}:${p(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      format(elapsed),
      style: const TextStyle(
        fontFamily: DotTokens.dotFamily,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
