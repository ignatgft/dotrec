import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/dot_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';

/// Гайды: как включать разрешения (микрофон, уведомления, плашка,
/// батарея, плитка, доступ к экрану).
class GuidesScreen extends ConsumerWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations t = AppLocalizations.of(context)!;
    final RecorderChannelReader r = RecorderChannelReader(ref);
    return Scaffold(
      appBar: AppBar(title: Text(t.guidesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DotTokens.lg),
        children: [
          _GuideCard(title: t.guideCaptureTitle, body: t.guideCaptureBody),
          _GuideCard(
            title: t.guideMicTitle,
            body: t.guideMicBody,
            actionLabel: t.openSettings,
            onAction: () => r.openAppSettings(),
          ),
          _GuideCard(
            title: t.guideNotifTitle,
            body: t.guideNotifBody,
            actionLabel: t.openSettings,
            onAction: () => r.openAppSettings(),
          ),
          _GuideCard(
            title: t.guideOverlayTitle,
            body: t.guideOverlayBody,
            actionLabel: t.openPermission,
            onAction: () => r.openOverlaySettings(),
          ),
          _GuideCard(
            title: t.guideBatteryTitle,
            body: t.guideBatteryBody,
            actionLabel: t.openSettings,
            onAction: () => r.openBatterySettings(),
          ),
          _GuideCard(
            title: t.guideTileTitle,
            body: t.guideTileBody,
            actionLabel: t.addTileBtn,
            onAction: () async {
              final bool ok = await r.requestAddTile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? t.tileAdded : t.tileUnavailable)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class RecorderChannelReader {
  RecorderChannelReader(this.ref);
  final WidgetRef ref;

  void openAppSettings() => ref.read(recorderChannelProvider).openAppSettings();
  void openOverlaySettings() =>
      ref.read(recorderChannelProvider).openOverlaySettings();
  void openBatterySettings() =>
      ref.read(recorderChannelProvider).openBatterySettings();
  Future<bool> requestAddTile() =>
      ref.read(recorderChannelProvider).requestAddTile();
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DotTokens.md),
      child: DotCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: DotTokens.sm),
            Text(body, style: const TextStyle(fontSize: 13)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DotTokens.sm),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
