import 'package:flutter/material.dart';
import 'package:sonora/presentation/screens/home/home_screen.dart';
import 'package:sonora/presentation/screens/search/search_screen.dart';
import 'package:sonora/presentation/screens/library/library_screen.dart';
import 'package:sonora/presentation/screens/player/player_screen.dart';

/// App route information
class AppRoute {
  final String name;
  final Widget builder;
  final String label;

  AppRoute({
    required this.name,
    required this.builder,
    required this.label,
  });
}

/// Generates the navigation bar destinations
List<NavigationDestination> get navBarDestinations => [
  const NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Главная',
  ),
  const NavigationDestination(
    icon: Icon(Icons.search_outlined),
    selectedIcon: Icon(Icons.search),
    label: 'Поиск',
  ),
  const NavigationDestination(
    icon: Icon(Icons.library_music_outlined),
    selectedIcon: Icon(Icons.library_music),
    label: 'Медиатека',
  ),
];

/// Route names for navigation
class RouteNames {
  static const home = '/';
  static const search = '/search';
  static const library = '/library';
  static const player = '/player';
}

/// App router configuration
class AppRouter {
  static Route<dynamic>? onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case RouteNames.search:
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
        );
      case RouteNames.library:
        return MaterialPageRoute(
          builder: (_) => const LibraryScreen(),
        );
      case RouteNames.player:
        return MaterialPageRoute(
          builder: (_) => const PlayerScreen(),
        );
      default:
        return null;
    }
  }
}