import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sonora/presentation/screens/player/player_screen.dart';
import 'package:sonora/domain/entities/track.dart';

void main() {
  group('PlayerScreen Widget Tests', () {
    testWidgets('should show welcome screen when no track', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlayerScreen(),
        ),
      );

      expect(find.text('Выберите композицию'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('should show player with track info', (WidgetTester tester) async {
      final track = Track(
        id: 'test-track',
        sourceId: 'src',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        sourceName: 'audius',
        availabilityType: 'full',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(initialTrack: track),
        ),
      );

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.text('Test Album'), findsOneWidget);
    });

    testWidgets('should show play/pause button', (WidgetTester tester) async {
      final track = Track(
        id: 'test-track',
        sourceId: 'src',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: const Duration(minutes: 3, seconds: 30),
        sourceName: 'audius',
        availabilityType: 'full',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(initialTrack: track),
        ),
      );

      // Should show play button initially
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should show progress bar', (WidgetTester tester) async {
      final track = Track(
        id: 'test-track',
        sourceId: 'src',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: const Duration(minutes: 3, seconds: 30),
        sourceName: 'audius',
        availabilityType: 'full',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(initialTrack: track),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('should show repeat and shuffle controls', (WidgetTester tester) async {
      final track = Track(
        id: 'test-track',
        sourceId: 'src',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: const Duration(minutes: 3, seconds: 30),
        sourceName: 'audius',
        availabilityType: 'full',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(initialTrack: track),
        ),
      );

      expect(find.byIcon(Icons.repeat), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_outlined), findsOneWidget);
    });
  });
}