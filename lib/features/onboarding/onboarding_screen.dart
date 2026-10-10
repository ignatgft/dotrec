import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Первый запуск: один экран, офлайн, без сбора данных (FR-ONB-01).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context)!;
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
              Text(
                t.onboardingTitle,
                style: const TextStyle(
                  fontFamily: DotTokens.dotFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DotTokens.lg),
              _row(context, t.ob1),
              _row(context, t.ob2),
              _row(context, t.ob3),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onDone, child: Text(t.begin)),
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
