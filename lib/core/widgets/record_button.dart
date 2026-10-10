import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Состояния кнопки записи (см. docs/06 §3).
enum RecordVisualState { ready, countdown, recording, paused, saving, failed }

/// Большая круглая кнопка записи 120 dp.
class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.visual,
    this.countdownLeft = 0,
    required this.onTap,
    this.semanticsLabel,
  });

  final RecordVisualState visual;
  final int countdownLeft;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final DotColors dot = context.dot;
    return Semantics(
      button: true,
      label: semanticsLabel ?? _defaultLabel(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: DotTokens.recordButton,
          height: DotTokens.recordButton,
          child: CustomPaint(
            painter: _RingPainter(
              color: dot.fg,
              saving: visual == RecordVisualState.saving,
            ),
            child: Center(child: _inner(dot)),
          ),
        ),
      ),
    );
  }

  String _defaultLabel() => switch (visual) {
    RecordVisualState.ready => 'Начать запись, кнопка',
    RecordVisualState.countdown => 'Отсчёт $countdownLeft',
    RecordVisualState.recording => 'Остановить запись, кнопка',
    RecordVisualState.paused => 'Продолжить запись, кнопка',
    RecordVisualState.saving => 'Сохранение записи',
    RecordVisualState.failed => 'Повторить запись, кнопка',
  };

  Widget _inner(DotColors dot) {
    switch (visual) {
      case RecordVisualState.ready:
      case RecordVisualState.failed:
        return AnimatedContainer(
          duration: const Duration(milliseconds: DotTokens.recordMorphMs),
          width: DotTokens.recordInner,
          height: DotTokens.recordInner,
          decoration: BoxDecoration(color: dot.record, shape: BoxShape.circle),
        );
      case RecordVisualState.countdown:
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Text(
            '$countdownLeft',
            key: ValueKey<int>(countdownLeft),
            style: const TextStyle(
              fontFamily: DotTokens.dotFamily,
              fontSize: 44,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case RecordVisualState.recording:
        return AnimatedContainer(
          duration: const Duration(milliseconds: DotTokens.recordMorphMs),
          curve: Curves.easeOutCubic,
          width: DotTokens.recordStop,
          height: DotTokens.recordStop,
          decoration: BoxDecoration(
            color: dot.record,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case RecordVisualState.paused:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: DotTokens.recordInner,
              height: DotTokens.recordInner,
              decoration: BoxDecoration(
                color: dot.record,
                shape: BoxShape.circle,
              ),
            ),
            Icon(
              Icons.pause,
              color: dot.onFg == dot.record ? Colors.white : dot.fg,
              size: 32,
            ),
          ],
        );
      case RecordVisualState.saving:
        return const SizedBox(
          width: DotTokens.recordInner,
          height: DotTokens.recordInner,
        );
    }
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.saving});

  final Color color;
  final bool saving;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - DotTokens.ring;
    if (saving) {
      // Точечный спиннер: 8 точек по кругу.
      for (int i = 0; i < 8; i++) {
        final double a = i * math.pi / 4;
        final Offset p = c + Offset(math.cos(a), math.sin(a)) * (r - 6);
        canvas.drawCircle(p, 3, Paint()..color = color);
      }
      return;
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = DotTokens.ring,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.saving != saving;
}
