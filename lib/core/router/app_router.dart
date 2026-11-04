import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/album/album_screen.dart';
import '../../presentation/artists/artist_screen.dart';
import '../../presentation/artists/artists_screen.dart';
import '../../presentation/collections/collection_screen.dart';
import '../../presentation/collections/collections_screen.dart';
import '../../presentation/discover/discover_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/library/library_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../data/prefs/prefs_providers.dart';
import '../../presentation/library/playlist_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/player/now_playing_screen.dart';
import '../../presentation/settings/backups_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/shell/fade_branches.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/stats/stats_screen.dart';
import '../theme/tokens.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: (ref.read(sharedPrefsProvider).getBool('onboarding_done') ?? false)
        ? Routes.home
        : Routes.onboarding,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => MainShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            FadeBranches(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.library, builder: (_, __) => const LibraryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.discover, builder: (_, __) => const DiscoverScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.stats, builder: (_, __) => const StatsScreen()),
          ]),
        ],
      ),
      GoRoute(path: Routes.search, parentNavigatorKey: _rootKey, builder: (_, __) => const SearchScreen()),
      GoRoute(path: Routes.settings, parentNavigatorKey: _rootKey, builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: '/album/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => AlbumScreen(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          heroTag: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/playlists/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => PlaylistScreen(id: int.tryParse(s.pathParameters['id'] ?? '') ?? -1),
      ),
      GoRoute(path: Routes.onboarding, parentNavigatorKey: _rootKey, builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: Routes.player,
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NowPlayingScreen(),
          transitionDuration: Dur.normal,
          reverseTransitionDuration: Dur.normal,
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Dur.curve))
                .animate(anim),
            child: child,
          ),
        ),
      ),
      GoRoute(path: Routes.backups, parentNavigatorKey: _rootKey, builder: (_, __) => const BackupsScreen()),
      GoRoute(path: Routes.collections, parentNavigatorKey: _rootKey, builder: (_, __) => const CollectionsScreen()),
      GoRoute(
        path: '/collections/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => CollectionScreen(id: int.tryParse(s.pathParameters['id'] ?? '') ?? -1),
      ),
      GoRoute(path: Routes.artists, parentNavigatorKey: _rootKey, builder: (_, __) => const ArtistsScreen()),
      GoRoute(
        path: '/artists/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, s) => ArtistScreen(id: int.tryParse(s.pathParameters['id'] ?? '') ?? -1),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Страница не найдена: ${state.uri}'))),
  );
});
