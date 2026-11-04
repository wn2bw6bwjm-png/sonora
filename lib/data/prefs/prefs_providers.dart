import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptics/haptics.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class HapticsNotifier extends Notifier<bool> {
  static const _key = 'haptics_enabled';

  @override
  bool build() {
    final v = ref.read(sharedPrefsProvider).getBool(_key) ?? true;
    Haptics.enabled = v;
    return v;
  }

  Future<void> set(bool v) async {
    state = v;
    Haptics.enabled = v;
    await ref.read(sharedPrefsProvider).setBool(_key, v);
  }
}

final hapticsProvider = NotifierProvider<HapticsNotifier, bool>(HapticsNotifier.new);

final preferredGenresProvider = Provider<List<String>>(
    (ref) => ref.watch(sharedPrefsProvider).getStringList('pref_genres') ?? const []);

final preferredArtistsProvider = Provider<List<String>>(
    (ref) => ref.watch(sharedPrefsProvider).getStringList('pref_artists') ?? const []);
