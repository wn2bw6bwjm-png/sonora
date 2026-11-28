import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sonora/presentation/screens/library/favorites_screen.dart';
import 'package:sonora/presentation/screens/library/playlists_screen.dart';
import 'package:sonora/presentation/screens/library/history_screen.dart';
import 'package:sonora/presentation/screens/library/albums_screen.dart';
import 'package:sonora/presentation/screens/library/artists_screen.dart';
import 'package:sonora/presentation/screens/library/local_music_screen.dart';

void main() {
  group('FavoritesScreen', () {
    testWidgets('should show empty state when no favorites', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritesScreen(),
        ),
      );

      expect(find.text('Избранное пусто'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should have app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritesScreen(),
        ),
      );

      expect(find.text('Избранное'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('PlaylistsScreen', () {
    testWidgets('should show empty state with create button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlaylistsScreen(),
        ),
      );

      expect(find.text('Плейлистов пока нет'), findsOneWidget);
      expect(find.text('Создать плейлист'), findsOneWidget);
    });

    testWidgets('should have app bar with actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlaylistsScreen(),
        ),
      );

      expect(find.text('Плейлисты'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('HistoryScreen', () {
    testWidgets('should show empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      expect(find.text('История пуста'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should have clear history button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    });
  });

  group('AlbumsScreen', () {
    testWidgets('should show empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumsScreen(),
        ),
      );

      expect(find.text('Альбомов пока нет'), findsOneWidget);
      expect(find.byIcon(Icons.album_outlined), findsOneWidget);
    });
  });

  group('ArtistsScreen', () {
    testWidgets('should show empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ArtistsScreen(),
        ),
      );

      expect(find.text('Исполнителей пока нет'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });

  group('LocalMusicScreen', () {
    testWidgets('should show empty state with import button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LocalMusicScreen(),
        ),
      );

      expect(find.text('Локальная музыка не найдена'), findsOneWidget);
      expect(find.text('Импортировать'), findsOneWidget);
    });

    testWidgets('should have import and refresh actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LocalMusicScreen(),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}