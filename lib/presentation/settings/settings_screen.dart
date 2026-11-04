import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../data/backup/backup_service.dart';
import '../../data/db/providers.dart';
import '../../data/prefs/prefs_providers.dart';
import '../../shared/widgets/confirm_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _section(ThemeData t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, Sp.sm),
        child: Text(label, style: t.textTheme.labelSmall),
      );

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final m = ScaffoldMessenger.of(context);
    try {
      final f = await ref.read(backupServiceProvider).createBackup();
      ref.invalidate(backupsProvider);
      await Share.shareXFiles([XFile(f.path)], text: 'Резервная копия SONORA');
    } catch (_) {
      m.showSnackBar(const SnackBar(content: Text('Не удалось экспортировать данные')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final m = ScaffoldMessenger.of(context);
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = res?.files.single.bytes;
    if (bytes == null || !context.mounted) return;
    final ok = await confirm(context,
        title: 'Импортировать данные?',
        message: 'Текущая библиотека будет заменена. Перед этим автоматически сохранится резервная копия.',
        action: 'Импортировать');
    if (!ok) return;
    try {
      await ref.read(backupServiceProvider).restoreFromJson(utf8.decode(bytes));
      ref.invalidate(backupsProvider);
      m.showSnackBar(const SnackBar(content: Text('Данные импортированы')));
    } on BackupException catch (e) {
      m.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      m.showSnackBar(const SnackBar(content: Text('Не удалось прочитать файл')));
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final m = ScaffoldMessenger.of(context);
    final ok = await confirm(context,
        title: 'Очистить библиотеку?',
        message: 'Все альбомы, оценки, рецензии, коллекции и копии аудио внутри SONORA будут удалены. Исходные файлы на телефоне останутся. Сначала лучше создать резервную копию.',
        action: 'Очистить');
    if (!ok) return;
    try {
      await ref.read(backupServiceProvider).clearLibrary();
      m.showSnackBar(const SnackBar(content: Text('Библиотека очищена')));
    } catch (_) {
      m.showSnackBar(const SnackBar(content: Text('Не удалось очистить библиотеку')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final haptics = ref.watch(hapticsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Sp.huge),
        children: [
          _section(t, 'ТЕМА'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.page),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная')),
                  ButtonSegment(value: ThemeMode.system, label: Text('Система')),
                ],
                selected: {mode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ),
          ),
          _section(t, 'ИНТЕРФЕЙС'),
          SwitchListTile(
            title: const Text('Тактильный отклик'),
            subtitle: const Text('Лёгкая вибрация при действиях'),
            value: haptics,
            onChanged: (v) => ref.read(hapticsProvider.notifier).set(v),
          ),
          ListTile(
            leading: const Icon(Icons.waving_hand_outlined),
            title: const Text('Пройти приветствие заново'),
            onTap: () => context.go(Routes.onboarding),
          ),
          _section(t, 'ДАННЫЕ'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Экспорт данных'),
            subtitle: const Text('Файл JSON, который можно сохранить или отправить'),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: const Text('Импорт данных'),
            subtitle: const Text('Восстановить из файла JSON'),
            onTap: () => _import(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Резервные копии'),
            onTap: () => context.push(Routes.backups),
          ),
          _section(t, 'БИБЛИОТЕКА'),
          ListTile(
            leading: Icon(Icons.delete_outline, color: t.colorScheme.error),
            title: Text('Очистить библиотеку', style: TextStyle(color: t.colorScheme.error)),
            onTap: () => _clear(context, ref),
          ),
          _section(t, 'О ПРИЛОЖЕНИИ'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('SONORA'),
            subtitle: const Text('Версия 0.1.0'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'SONORA',
              applicationVersion: '0.1.0',
              applicationLegalese: 'Все данные хранятся только на вашем устройстве.',
            ),
          ),
        ],
      ),
    );
  }
}
