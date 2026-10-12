import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// Стандартизированная кнопка с иконкой для ПК-версии DotRec Link.
/// Соответствует дизайн-спецификации:
/// - Размер кнопки 44×44 px, иконка 20×20 px
/// - Обязательные Semantics и Tooltip
/// - Видимое кольцо фокуса 2 px для навигации с клавиатуры
class DotIconButton extends StatefulWidget {
  const DotIconButton({
    super.key,
    required this.asset,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.isActive = false,
    this.size = 44,
    this.iconSize = 20,
    this.semanticsLabel,
  });

  final String asset;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isActive;
  final double size;
  final double iconSize;
  final String? semanticsLabel;

  @override
  State<DotIconButton> createState() => _DotIconButtonState();
}

class _DotIconButtonState extends State<DotIconButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dot = context.dot;
    final fgColor = widget.color ?? (widget.isActive ? dot.bg : dot.fg);
    final bgColor = widget.isActive
        ? dot.fg
        : (_isHovered
            ? dot.surfaceRaised
            : Colors.transparent);

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticsLabel ?? widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: FocusableActionDetector(
          onShowFocusHighlight: (v) => setState(() => _isFocused = v),
          onShowHoverHighlight: (v) => setState(() => _isHovered = v),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(DotTokens.radiusButton),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(DotTokens.radiusButton),
                border: Border.all(
                  color: _isFocused ? dot.fg : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  widget.asset,
                  width: widget.iconSize,
                  height: widget.iconSize,
                  colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Элемент плавающей панели инструментов:
/// - Иконка 20 px
/// - Подпись 12 px (системный шрифт, не точечный)
/// - Активная функция заливается `fg`
/// - Доступность (Tooltip + Semantics)
class DotToolbarAction extends StatefulWidget {
  const DotToolbarAction({
    super.key,
    required this.asset,
    required this.label,
    required this.tooltip,
    this.onPressed,
    this.isActive = false,
    this.isDestructive = false,
    this.color,
  });

  final String asset;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isDestructive;
  final Color? color;

  @override
  State<DotToolbarAction> createState() => _DotToolbarActionState();
}

class _DotToolbarActionState extends State<DotToolbarAction> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final dot = context.dot;
    final effectiveColor = widget.color ??
        (widget.isDestructive
            ? DotTokens.accentRed
            : (widget.isActive ? dot.bg : dot.fg));

    final effectiveBg = widget.isActive
        ? (widget.isDestructive ? DotTokens.accentRed : dot.fg)
        : (_isHovered ? dot.surfaceRaised : Colors.transparent);

    return Semantics(
      button: true,
      label: '${widget.label}: ${widget.tooltip}',
      enabled: widget.onPressed != null,
      child: Tooltip(
        message: widget.tooltip,
        child: FocusableActionDetector(
          onShowFocusHighlight: (v) => setState(() => _isFocused = v),
          onShowHoverHighlight: (v) => setState(() => _isHovered = v),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(DotTokens.radiusButton),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: BorderRadius.circular(DotTokens.radiusButton),
                border: Border.all(
                  color: _isFocused ? dot.fg : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    widget.asset,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      effectiveColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          widget.isActive ? FontWeight.w600 : FontWeight.w400,
                      color: effectiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
