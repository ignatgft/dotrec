import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../platform/models/recording_item.dart';
import '../../providers.dart';

String _fmtSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} МБ';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} ГБ';
}

String _fmtDur(Duration d) {
  String p(int v) => v.toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${p(d.inHours)}:${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }
  return '${p(d.inMinutes)}:${p(d.inSeconds.remainder(60))}';
}

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecordingItem>> lib = ref.watch(libraryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Записи')),
      body: lib.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Ошибка: $e')),
        data: (List<RecordingItem> items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DotTokens.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        border: Border.all(color: context.dot.line, width: 1),
                        borderRadius: BorderRadius.circular(
                          DotTokens.radiusCard,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '···',
                          style: TextStyle(
                            fontFamily: DotTokens.dotFamily,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DotTokens.lg),
                    const Text('Здесь появятся ваши записи'),
                    const SizedBox(height: DotTokens.lg),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Начать запись'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(DotTokens.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: DotTokens.md,
                crossAxisSpacing: DotTokens.md,
                childAspectRatio: 9 / 16,
              ),
              itemCount: items.length,
              itemBuilder: (BuildContext c, int i) {
                final RecordingItem it = items[i];
                return GestureDetector(
                  onTap: () => ref.read(libraryChannelProvider).open(it.uri),
                  onLongPress: () => _menu(c, ref, it),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.dot.surface,
                      borderRadius: BorderRadius.circular(DotTokens.radiusCard),
                      border: Border.all(
                        color: context.dot.line,
                        width: DotTokens.hairline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.all(DotTokens.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.dot.bg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _fmtDur(it.duration),
                                style: const TextStyle(
                                  fontFamily: DotTokens.dotFamily,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(DotTokens.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                _fmtSize(it.sizeBytes),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.dot.fgMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _menu(BuildContext c, WidgetRef ref, RecordingItem it) {
    showModalBottomSheet<void>(
      context: c,
      builder: (BuildContext m) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Открыть'),
              onTap: () {
                Navigator.of(m).pop();
                ref.read(libraryChannelProvider).open(it.uri);
              },
            ),
            ListTile(
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.of(m).pop();
                ref.read(libraryChannelProvider).share(it.uri);
              },
            ),
            ListTile(
              title: const Text('Удалить'),
              onTap: () async {
                Navigator.of(m).pop();
                final bool ok = await ref
                    .read(libraryChannelProvider)
                    .delete(it.uri);
                if (ok) {
                  await ref.read(libraryProvider.notifier).refresh();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
