import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../dot_icons.dart';
import '../theme/tokens.dart';

/// Состояния кнопки записи (см. docs/06 §3).
enum RecordVisualState { ready, countdown, recording, paused, saving, failed }

/// Большая круглая кнопка записи 120 dp.
/// T-26: морфинг 220 мс, пульс кольца раз в 2 с при записи, хаптик на тап.
/// Уважает `disableAnimations`.
class RecordButton extends StatefulWidget {
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
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: DotTokens.pulseMs),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(RecordButton old) {
    super.didUpdateWidget(old);
    if (old.visual != widget.visual) _syncPulse();
  }

  void _syncPulse() {
    final bool noAnim = MediaQuery.disableAnimationsOf(context);
    if (widget.visual == RecordVisualState.recording && !noAnim) {
      if (!_pulse.isAnimating) unawaited(_pulse.repeat());
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DotColors dot = context.dot;
    final bool pulsing =
        widget.visual == RecordVisualState.recording &&
        !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? _defaultLabel(),
      child: GestureDetector(
        onTap: widget.onTap == null
            ? null
            : () {
                unawaited(HapticFeedback.lightImpact());
                widget.onTap!();
              },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: DotTokens.recordButton,
          height: DotTokens.recordButton,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                painter: _RingPainter(
                  color: dot.fg,
                  saving: widget.visual == RecordVisualState.saving,
                  pulse: pulsing ? _pulse.value : 0,
                ),
                child: child,
              );
            },
            child: Center(child: _inner(dot)),
          ),
        ),
      ),
    );
  }

  String _defaultLabel() => switch (widget.visual) {
    RecordVisualState.ready => 'Начать запись, кнопка',
    RecordVisualState.countdown => 'Отсчёт ${widget.countdownLeft}',
    RecordVisualState.recording => 'Остановить запись, кнопка',
    RecordVisualState.paused => 'Продолжить запись, кнопка',
    RecordVisualState.saving => 'Сохранение записи',
    RecordVisualState.failed => 'Повторить запись, кнопка',
  };

  Widget _inner(DotColors dot) {
    switch (widget.visual) {
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
            '${widget.countdownLeft}',
            key: ValueKey<int>(widget.countdownLeft),
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
            SvgPicture.asset(
              DotIcons.pause,
              colorFilter: ColorFilter.mode(
                dot.onFg == dot.record ? Colors.white : dot.fg,
                BlendMode.srcIn,
              ),
              width: 32,
              height: 32,
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
  _RingPainter({required this.color, required this.saving, this.pulse = 0});

  final Color color;
  final bool saving;
  final double pulse;

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
    if (pulse > 0) {
      // Пульс кольца раз в 2 с: расширяющееся затухающее кольцо.
      canvas.drawCircle(
        c,
        r + pulse * 10,
        Paint()
          ..color = color.withValues(alpha: (1 - pulse) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = DotTokens.ring,
      );
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
      old.color != color || old.saving != saving || old.pulse != pulse;
}
