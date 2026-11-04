import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/album_view.dart';
import '../../domain/entities/collection_view.dart';
import '../../domain/entities/rating_entry.dart';
import '../../domain/entities/track.dart';
import '../backup/backup_service.dart';
import '../../domain/entities/artist_info.dart';
import '../../domain/entities/playlist_view.dart';
import '../../domain/entities/track_entry.dart';
import '../repositories/collection_repository.dart';
import '../repositories/extras_repository.dart';
import '../repositories/library_repository.dart';
import '../repositories/search_repository.dart';
import 'app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final libraryRepoProvider =
    Provider<LibraryRepository>((ref) => LibraryRepository(ref.watch(databaseProvider)));

final albumsProvider =
    StreamProvider<List<AlbumView>>((ref) => ref.watch(libraryRepoProvider).watchAlbums());

final albumProvider = StreamProvider.family<AlbumView?, int>(
    (ref, id) => ref.watch(libraryRepoProvider).watchAlbum(id));

final collectionRepoProvider = Provider<CollectionRepository>(
    (ref) => CollectionRepository(ref.watch(databaseProvider), ref.watch(libraryRepoProvider)));

final searchRepoProvider =
    Provider<SearchRepository>((ref) => SearchRepository(ref.watch(databaseProvider)));

final collectionsProvider = StreamProvider<List<CollectionView>>(
    (ref) => ref.watch(collectionRepoProvider).watchCollections());

final collectionProvider = StreamProvider.family<CollectionView?, int>(
    (ref, id) => ref.watch(collectionRepoProvider).watchCollection(id));

final albumIdsInProvider = StreamProvider.family<Set<int>, int>(
    (ref, id) => ref.watch(collectionRepoProvider).watchAlbumIdsIn(id));

final collectionIdsForProvider = StreamProvider.family<Set<int>, int>(
    (ref, albumId) => ref.watch(collectionRepoProvider).watchCollectionIdsFor(albumId));

final collectionAlbumsProvider = StreamProvider.family<List<AlbumView>, int>((ref, id) {
  ref.watch(albumIdsInProvider(id)); // пересоздаёт поток при изменении состава
  return ref.watch(collectionRepoProvider).watchAlbums(id);
});

final artistAlbumsProvider = StreamProvider.family<List<AlbumView>, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return ref.watch(libraryRepoProvider).watchWhere(db.albums.artistId.equals(id));
});

final searchHistoryProvider =
    StreamProvider<List<String>>((ref) => ref.watch(searchRepoProvider).watchHistory());

final albumGenresProvider = StreamProvider<Map<int, List<String>>>(
    (ref) => ref.watch(libraryRepoProvider).watchGenreMap());

final tracksProvider = StreamProvider.family<List<TrackView>, int>(
    (ref, id) => ref.watch(libraryRepoProvider).watchTracks(id));

final ratingHistoryProvider = StreamProvider.family<List<RatingEntry>, int>(
    (ref, id) => ref.watch(libraryRepoProvider).watchRatingHistory(id));

final ratingDatesProvider =
    StreamProvider<List<DateTime>>((ref) => ref.watch(libraryRepoProvider).watchRatingDates());

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref.watch(databaseProvider)));

final backupsProvider = FutureProvider.autoDispose<List<BackupInfo>>(
    (ref) => ref.watch(backupServiceProvider).listBackups());

final recentlyPlayedProvider = StreamProvider<List<int>>(
    (ref) => ref.watch(libraryRepoProvider).watchRecentlyPlayedIds());

final extrasRepoProvider =
    Provider<ExtrasRepository>((ref) => ExtrasRepository(ref.watch(databaseProvider)));

final allTracksProvider =
    StreamProvider<List<TrackEntry>>((ref) => ref.watch(extrasRepoProvider).watchAllTracks());

final favoriteTracksProvider = StreamProvider<List<TrackEntry>>(
    (ref) => ref.watch(extrasRepoProvider).watchFavoriteTracks());

final artistsProvider =
    StreamProvider<List<ArtistInfo>>((ref) => ref.watch(extrasRepoProvider).watchArtists());

final favoriteArtistsProvider = StreamProvider<List<ArtistInfo>>(
    (ref) => ref.watch(extrasRepoProvider).watchFavoriteArtists());

final artistInfoProvider = StreamProvider.family<ArtistInfo?, int>(
    (ref, id) => ref.watch(extrasRepoProvider).watchArtist(id));

final playlistsProvider =
    StreamProvider<List<PlaylistView>>((ref) => ref.watch(extrasRepoProvider).watchPlaylists());

final playlistTracksProvider = StreamProvider.family<List<TrackEntry>, int>(
    (ref, id) => ref.watch(extrasRepoProvider).watchPlaylistTracks(id));

final playlistIdsForTrackProvider = StreamProvider.family<Set<int>, int>(
    (ref, id) => ref.watch(extrasRepoProvider).watchPlaylistIdsFor(id));
