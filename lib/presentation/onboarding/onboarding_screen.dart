import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../../data/prefs/prefs_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _count = 5;
  final _page = PageController();
  int _i = 0;
  final _genres = <String>{};
  final _artists = <String>{};
  final _artistCtl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _page.dispose();
    _artistCtl.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool skipped}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final prefs = ref.read(sharedPrefsProvider);
    try {
      if (!skipped) {
        await prefs.setStringList('pref_genres', _genres.toList());
        await prefs.setStringList('pref_artists', _artists.toList());
        ref.invalidate(preferredGenresProvider);
        ref.invalidate(preferredArtistsProvider);
      }
    } catch (_) {
      // Онбординг не должен блокировать вход в приложение.
    }
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go(Routes.home);
  }

  void _next() {
    Haptics.selection();
    if (_i == _count - 1) {
      _finish(skipped: false);
    } else {
      _page.nextPage(duration: Dur.normal, curve: Dur.curve);
    }
  }

  Widget _frame(String title, String subtitle, Widget body) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.page),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Sp.xl),
        Text(title, style: t.textTheme.displaySmall),
        const SizedBox(height: Sp.md),
        Text(subtitle, style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: Sp.xl),
        Expanded(child: body),
      ]),
    );
  }

  Widget _chips(Set<String> selected, List<String> options) => SingleChildScrollView(
        child: Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
          for (final o in options)
            FilterChip(
              label: Text(o),
              selected: selected.contains(o),
              showCheckmark: false,
              onSelected: (v) {
                Haptics.selection();
                setState(() => v ? selected.add(o) : selected.remove(o));
              },
            ),
        ]),
      );

  static const _genreOptions = [
    'Rock', 'Indie Rock', 'Pop', 'Hip-Hop', 'R&B', 'Soul', 'Electronic', 'Ambient', 'Techno', 'House',
    'Synthwave', 'Jazz', 'Blues', 'Classical', 'Folk', 'Indie Folk', 'Singer-Songwriter', 'Dream Pop',
    'Post-Rock', 'Metal', 'Punk', 'Reggae', 'Country',
  ];

  void _addArtist() {
    final v = _artistCtl.text.trim();
    if (v.isEmpty) return;
    Haptics.selection();
    setState(() {
      _artists.add(v);
      _artistCtl.clear();
    });
  }

  Widget _artistInput() => SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _artistCtl,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _addArtist(),
            decoration: InputDecoration(
              hintText: 'Имя исполнителя',
              suffixIcon: IconButton(tooltip: 'Добавить', icon: const Icon(Icons.add), onPressed: _addArtist),
            ),
          ),
          const SizedBox(height: Sp.lg),
          Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
            for (final a in _artists)
              InputChip(label: Text(a), onDeleted: () => setState(() => _artists.remove(a))),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final haptics = ref.watch(hapticsProvider);
    final pages = <Widget>[
      _frame('Welcome to\nSONORA', 'Ваша личная музыкальная библиотека: альбомы, оценки, рецензии и статистика. Всё хранится на вашем устройстве.',
          const SizedBox.shrink()),
      _frame('Любимые жанры', 'Выберите жанры, которые вам близки. Это поможет с рекомендациями.',
          _chips(_genres, _genreOptions)),
      _frame('Любимые исполнители', 'Введите имена, чтобы мы учитывали их в подборках. Этот шаг можно пропустить.',
          _artistInput()),
      _frame(
        'Предпочтения',
        'Настройте приложение под себя. Всё можно изменить позже.',
        ListView(children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Тактильный отклик'),
            value: haptics,
            onChanged: (v) => ref.read(hapticsProvider.notifier).set(v),
          ),
          const SizedBox(height: Sp.md),
          Text('ТЕМА', style: t.textTheme.labelSmall),
          const SizedBox(height: Sp.sm),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная')),
              ButtonSegment(value: ThemeMode.system, label: Text('Система')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ]),
      ),
      _frame(
        'Всё готово',
        _genres.isEmpty && _artists.isEmpty
            ? 'Начните с добавления альбомов или загляните в Discover.'
            : 'Выбрано жанров: ${_genres.length}, исполнителей: ${_artists.length}. Они будут учитываться в подборках Discover.',
        const SizedBox.shrink(),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(Sp.sm),
              child: _i == _count - 1
                  ? const SizedBox(height: 48)
                  : TextButton(onPressed: _busy ? null : () => _finish(skipped: true), child: const Text('Пропустить')),
            ),
          ),
          Expanded(child: PageView(controller: _page, onPageChanged: (i) => setState(() => _i = i), children: pages)),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.md, Sp.page, Sp.xl),
            child: Row(children: [
              for (var i = 0; i < _count; i++)
                AnimatedContainer(
                  duration: Dur.fast,
                  margin: const EdgeInsets.only(right: Sp.xs),
                  width: i == _i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _i ? t.colorScheme.primary : t.colorScheme.outline,
                    borderRadius: Rad.smAll,
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _next,
                child: Text(_i == _count - 1 ? 'Начать' : 'Далее'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
