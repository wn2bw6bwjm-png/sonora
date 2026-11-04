import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/media/image_store.dart';
import 'core/haptics/haptics.dart';
import 'data/prefs/prefs_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.sonora.sonora.channel.audio',
      androidNotificationChannelName: 'Воспроизведение SONORA',
      androidNotificationOngoing: true,
    );
  } catch (_) {
    // Без фонового сервиса приложение всё равно работает.
  }
  ImageStore.baseDir = (await getApplicationDocumentsDirectory()).path;
  final prefs = await SharedPreferences.getInstance();
  Haptics.enabled = prefs.getBool('haptics_enabled') ?? true;
  runApp(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const SonoraApp(),
  ));
}
