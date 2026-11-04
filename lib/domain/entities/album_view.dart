class AlbumView {
  const AlbumView({
    required this.id,
    required this.artistId,
    required this.title,
    required this.artist,
    required this.coverSeed,
    required this.addedAt,
    this.year,
    this.rating,
    this.review = '',
    this.isFavorite = false,
    this.coverPath,
  });

  final int id, artistId;
  final String title, artist, coverSeed, review;
  final int? year;
  final String? coverPath;
  final double? rating;
  final bool isFavorite;
  final DateTime addedAt;
}
