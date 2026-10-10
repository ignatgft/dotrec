import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Сегменты выбора (разрешение, FPS, пресеты).
/// Выбранный залит fg, текст onFg. Тач-цель ≥ 48 dp.
class DotSegmented<T> extends StatelessWidget {
  const DotSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.enabledOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool Function(T)? enabledOf;

  @override
  Widget build(BuildContext context) {
    final DotColors dot = context.dot;
    return Wrap(
      spacing: DotTokens.sm,
      runSpacing: DotTokens.sm,
      children: [
        for (final T v in values)
          Builder(
            builder: (BuildContext context) {
              final bool enabled = enabledOf == null ? true : enabledOf!(v);
              final bool isSel = v == selected;
              return Opacity(
                opacity: enabled ? 1 : 0.38,
                child: GestureDetector(
                  onTap: enabled ? () => onSelected(v) : null,
                  child: Semantics(
                    button: true,
                    selected: isSel,
                    enabled: enabled,
                    label: labelOf(v),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 48,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DotTokens.lg,
                        vertical: DotTokens.md,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? dot.fg : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          DotTokens.radiusChip,
                        ),
                        border: Border.all(
                          color: dot.line,
                          width: DotTokens.hairline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          labelOf(v),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSel ? dot.onFg : dot.fg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Одиночный чип.
class DotChip extends StatelessWidget {
  const DotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final DotColors dot = context.dot;
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: DotTokens.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: DotTokens.lg),
          decoration: BoxDecoration(
            color: selected ? dot.fg : Colors.transparent,
            borderRadius: BorderRadius.circular(DotTokens.radiusChip),
            border: Border.all(color: dot.line, width: DotTokens.hairline),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? dot.onFg : dot.fg,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
