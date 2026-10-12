import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/link_providers.dart';
import 'core/theme/dot_theme.dart';
import 'core/theme/tokens.dart';
import 'features/connection/onboarding_screen.dart';
import 'features/main/main_screen.dart';
import 'features/mirror/mirror_window.dart';
import 'features/obs/obs_screen.dart';
import 'features/settings/settings_screen.dart';

class DotRecLinkDesktopApp extends ConsumerWidget {
  const DotRecLinkDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'DotRec Link',
      debugShowCheckedModeBanner: false,
      theme: DotTheme.light(),
      darkTheme: DotTheme.dark(),
      themeMode: themeMode,
      home: const DesktopHomeShell(),
    );
  }
}

class DesktopHomeShell extends ConsumerWidget {
  const DesktopHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(activeTabProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.keyM,
          control: true,
          shift: true,
        ): () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const MirrorWindow()));
        },
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () {
          ref.read(activeTabProvider.notifier).state = DesktopTab.settings;
        },
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
          ref.read(activeTabProvider.notifier).state = DesktopTab.mirror;
        },
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () {
          ref.read(activeTabProvider.notifier).state = DesktopTab.connection;
        },
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () {
          ref.read(activeTabProvider.notifier).state = DesktopTab.obs;
        },
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () {
          ref.read(activeTabProvider.notifier).state = DesktopTab.settings;
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              // Custom Desktop Navigation Header
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: DotTokens.xl),
                decoration: BoxDecoration(
                  color: context.dot.surface,
                  border: Border(
                    bottom: BorderSide(color: context.dot.line, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Brand Logo
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DotTokens.accentRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DOTREC LINK',
                          style: TextStyle(
                            fontFamily: DotTokens.dotFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            color: context.dot.fg,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Navigation Tabs
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: context.dot.surfaceRaised,
                        borderRadius: BorderRadius.circular(
                          DotTokens.radiusChip,
                        ),
                      ),
                      child: Row(
                        children: DesktopTab.values.map((tab) {
                          final isSel = tab == currentTab;
                          return GestureDetector(
                            onTap: () {
                              ref.read(activeTabProvider.notifier).state = tab;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? context.dot.fg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  DotTokens.radiusChip - 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: 15,
                                    color: isSel
                                        ? context.dot.bg
                                        : context.dot.fgMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tab.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSel
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSel
                                          ? context.dot.bg
                                          : context.dot.fg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const Spacer(),

                    // Quick Theme Toggle
                    IconButton(
                      icon: Icon(
                        ref.watch(themeModeProvider) == ThemeMode.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 18,
                        color: context.dot.fg,
                      ),
                      tooltip: 'Переключить тему',
                      onPressed: () {
                        ref.read(themeModeProvider.notifier).state =
                            ref.read(themeModeProvider) == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                      },
                    ),
                  ],
                ),
              ),

              // Active Tab Content
              Expanded(
                child: switch (currentTab) {
                  DesktopTab.mirror => const MainScreen(),
                  DesktopTab.connection => const OnboardingScreen(),
                  DesktopTab.obs => const ObsScreen(),
                  DesktopTab.settings => const SettingsScreen(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
