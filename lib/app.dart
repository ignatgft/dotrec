import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/dot_theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/app_localizations.dart';
import 'platform/models/record_settings.dart';
import 'providers.dart';

class DotApp extends ConsumerWidget {
  const DotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordSettings cfg =
        ref.watch(settingsProvider).valueOrNull ?? const RecordSettings();
    final ThemeMode mode = switch (cfg.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final String localeCode =
        ref.watch(appLocaleProvider).valueOrNull ?? 'system';
    return MaterialApp(
      onGenerateTitle: (BuildContext c) => AppLocalizations.of(c)!.appTitle,
      theme: DotTheme.light(),
      darkTheme: DotTheme.dark(),
      themeMode: mode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeCode == 'system' ? null : Locale(localeCode),
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  bool? _seen;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences p) {
      if (mounted) {
        setState(() => _seen = p.getBool('onboarding_seen') ?? false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_seen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_seen == false) {
      return OnboardingScreen(
        onDone: () async {
          final SharedPreferences p = await SharedPreferences.getInstance();
          await p.setBool('onboarding_seen', true);
          if (mounted) setState(() => _seen = true);
        },
      );
    }
    return const HomeScreen();
  }
}
