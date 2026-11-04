import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonora/app.dart';
import 'package:sonora/data/db/providers.dart';
import 'package:sonora/data/prefs/prefs_providers.dart';

void main() {
  testWidgets('tabs switch', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        albumsProvider.overrideWith((ref) => Stream.value(const [])),
        albumGenresProvider.overrideWith((ref) => Stream.value(const <int, List<String>>{})),
        recentlyPlayedProvider.overrideWith((ref) => Stream.value(const <int>[])),
        favoriteArtistsProvider.overrideWith((ref) => Stream.value(const [])),
        collectionsProvider.overrideWith((ref) => Stream.value(const [])),
        ratingDatesProvider.overrideWith((ref) => Stream.value(const <DateTime>[])),
      ],
      child: const SonoraApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Библиотека пуста'), findsOneWidget);
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Недостаточно данных'), findsOneWidget);
  });
}
