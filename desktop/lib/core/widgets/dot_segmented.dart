import 'package:flutter/material.dart';
import '../theme/tokens.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: context.dot.surfaceRaised,
        borderRadius: BorderRadius.circular(DotTokens.radiusChip),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: values.map((T v) {
          final bool isSel = v == selected;
          final bool enabled = enabledOf?.call(v) ?? true;
          return Expanded(
            child: GestureDetector(
              onTap: enabled ? () => onSelected(v) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? context.dot.fg : Colors.transparent,
                  borderRadius: BorderRadius.circular(DotTokens.radiusChip - 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  labelOf(v),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    color: !enabled
                        ? context.dot.fgMuted.withValues(alpha: 0.4)
                        : isSel
                            ? context.dot.bg
                            : context.dot.fg,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
