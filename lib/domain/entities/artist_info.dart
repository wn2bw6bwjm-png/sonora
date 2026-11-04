class ArtistInfo {
  const ArtistInfo({
    required this.id,
    required this.name,
    this.bio = '',
    this.imagePath,
    this.isFavorite = false,
  });
  final int id;
  final String name, bio;
  final String? imagePath;
  final bool isFavorite;
}
