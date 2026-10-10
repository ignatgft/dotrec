import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Первый запуск: один экран, офлайн, без сбора данных (FR-ONB-01).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DotTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '● ● ●',
                style: TextStyle(
                  fontFamily: DotTokens.dotFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DotTokens.xl),
              const Text(
                'Запись экрана без лишнего',
                style: TextStyle(
                  fontFamily: DotTokens.dotFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DotTokens.lg),
              _row(context, 'Работает без интернета'),
              _row(context, 'Нет рекламы и водяных знаков'),
              _row(context, 'Файлы хранятся в Movies/DotRec'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Начать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DotTokens.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.dot.fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DotTokens.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
