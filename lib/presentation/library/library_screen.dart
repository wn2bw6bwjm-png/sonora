import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tokens.dart';
import '../artists/artists_screen.dart';
import 'album_form_sheet.dart';
import 'albums_tab.dart';
import 'import_tracks.dart';
import 'library_tabs.dart';
import 'playlist_screen.dart';

enum LibTab {
  albums('Albums'),
  artists('Artists'),
  tracks('Tracks'),
  playlists('Playlists'),
  favorites('Favorites'),
  recent('Recently Added');

  const LibTab(this.label);
  final String label;
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibTab _tab = LibTab.albums;

  Widget _body() => switch (_tab) {
        LibTab.albums => const AlbumsTab(),
        LibTab.artists => const ArtistsList(),
        LibTab.tracks => const TracksTab(),
        LibTab.playlists => const PlaylistsTab(),
        LibTab.favorites => const FavoritesTab(),
        LibTab.recent => const RecentTab(),
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.sm, 0),
          child: Row(children: [
            Expanded(child: Text('Library', style: t.textTheme.displaySmall)),
            IconButton(
                tooltip: 'Коллекции',
                icon: const Icon(Icons.folder_outlined),
                onPressed: () => context.push(Routes.collections)),
            if (_tab == LibTab.albums)
              IconButton(
                  tooltip: 'Добавить альбом', icon: const Icon(Icons.add), onPressed: () => showAlbumForm(context)),
            if (_tab == LibTab.tracks)
              IconButton(
                  tooltip: 'Добавить треки',
                  icon: const Icon(Icons.add),
                  onPressed: () => importTracksFlow(context, ref)),
            if (_tab == LibTab.playlists)
              IconButton(
                  tooltip: 'Создать плейлист',
                  icon: const Icon(Icons.add),
                  onPressed: () => createPlaylistDialog(context, ref)),
          ]),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Sp.page, vertical: Sp.sm),
            children: [
              for (final tab in LibTab.values)
                Padding(
                  padding: const EdgeInsets.only(right: Sp.sm),
                  child: ChoiceChip(
                    label: Text(tab.label),
                    selected: _tab == tab,
                    showCheckmark: false,
                    onSelected: (_) {
                      Haptics.selection();
                      setState(() => _tab = tab);
                    },
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: AnimatedSwitcher(
            duration: Dur.fast,
            child: KeyedSubtree(key: ValueKey(_tab), child: _body()),
          ),
        ),
      ]),
    );
  }
}
