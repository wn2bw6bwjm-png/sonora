import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sonora/presentation/screens/home/home_screen.dart';
import 'package:sonora/presentation/widgets/skeleton_loader.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('should show skeleton while loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Should show skeleton loaders initially
      expect(find.byType(TrackTileSkeleton), findsWidgets);
      expect(find.byType(RecommendationCardSkeleton), findsWidgets);
    });

    testWidgets('should show welcome header', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Welcome header should be visible
      expect(find.textContaining('Доброе'), findsOneWidget);
      // or 'Добрый', 'Доброй', 'Доброй' depending on time
    });
  });

  group('Skeleton Loaders', () {
    testWidgets('TrackTileSkeleton should render with shimmer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackTileSkeleton(),
          ),
        ),
      );

      expect(find.byType(TrackTileSkeleton), findsOneWidget);
      // Should have leading, title, subtitle, trailing placeholders
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('RecommendationCardSkeleton should render with shimmer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RecommendationCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(RecommendationCardSkeleton), findsOneWidget);
    });

    testWidgets('GridCardSkeleton should render with shimmer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GridCardSkeleton(),
          ),
        ),
      );

      expect(find.byType(GridCardSkeleton), findsOneWidget);
    });

    testWidgets('HomeScreenSkeleton should render all sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeScreenSkeleton(),
          ),
        ),
      );

      expect(find.byType(HomeScreenSkeleton), findsOneWidget);
      // Should have multiple skeleton items
      expect(find.byType(TrackTileSkeleton), findsWidgets);
      expect(find.byType(RecommendationCardSkeleton), findsWidgets);
    });
  });
}