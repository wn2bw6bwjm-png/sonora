import 'package:flutter/material.dart';
import '../../core/haptics/haptics.dart';
import 'package:go_router/go_router.dart';

import '../player/mini_player.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.library_music_outlined, Icons.library_music, 'Library'),
    (Icons.explore_outlined, Icons.explore, 'Discover'),
    (Icons.insights_outlined, Icons.insights, 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          const Divider(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              Haptics.selection();
              shell.goBranch(i, initialLocation: i == shell.currentIndex);
            },
            destinations: [
              for (final it in _items)
                NavigationDestination(icon: Icon(it.$1), selectedIcon: Icon(it.$2), label: it.$3),
            ],
          ),
        ],
      ),
    );
  }
}
