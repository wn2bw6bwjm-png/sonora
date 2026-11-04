import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/format.dart';
import '../../data/backup/backup_service.dart';
import '../../data/db/providers.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';

class BackupsScreen extends ConsumerWidget {
  const BackupsScreen({super.key});

  String _when(DateTime d) =>
      '${fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final m = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupServiceProvider).createBackup();
      ref.invalidate(backupsProvider);
      m.showSnackBar(const SnackBar(content: Text('Копия создана')));
    } catch (_) {
      m.showSnackBar(const SnackBar(content: Text('Не удалось создать копию')));
    }
  }

  Future<void> _action(BuildContext context, WidgetRef ref, String action, BackupInfo b) async {
    final m = ScaffoldMessenger.of(context);
    final svc = ref.read(backupServiceProvider);
    try {
      if (action == 'share') {
        await Share.shareXFiles([XFile(b.file.path)]);
      } else if (action == 'restore') {
        final ok = await confirm(context,
            title: 'Восстановить из копии?',
            message: 'Текущая библиотека будет заменена данными из копии от ${_when(b.modified)}.',
            action: 'Восстановить');
        if (!ok) return;
        await svc.restoreFromFile(b.file);
        ref.invalidate(backupsProvider);
        m.showSnackBar(const SnackBar(content: Text('Данные восстановлены')));
      } else if (action == 'delete') {
        await svc.deleteBackup(b.file);
        ref.invalidate(backupsProvider);
      }
    } on BackupException catch (e) {
      m.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      m.showSnackBar(const SnackBar(content: Text('Не удалось выполнить действие')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final list = ref.watch(backupsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Резервные копии'),
        actions: [
          IconButton(
              tooltip: 'Создать копию',
              icon: const Icon(Icons.add),
              onPressed: () => _create(context, ref)),
        ],
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
            icon: Icons.error_outline, title: 'Ошибка', message: 'Не удалось прочитать список копий.'),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.backup_outlined,
                title: 'Копий пока нет',
                message: 'Копия сохраняется на устройстве и защищает данные от потери.',
                actionLabel: 'Создать копию',
                onAction: () => _create(context, ref),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final b = items[i];
                  final auto = b.file.path.contains('before_restore');
                  return ListTile(
                    title: Text(_when(b.modified), style: t.textTheme.titleSmall),
                    subtitle: Text(
                      '${(b.bytes / 1024).ceil()} КБ${auto ? ' · автоматическая перед восстановлением' : ''}',
                      style: t.textTheme.bodySmall,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => _action(context, ref, v, b),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'restore', child: Text('Восстановить')),
                        PopupMenuItem(value: 'share', child: Text('Поделиться')),
                        PopupMenuItem(value: 'delete', child: Text('Удалить')),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
