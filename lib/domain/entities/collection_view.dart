class CollectionView {
  const CollectionView({
    required this.id,
    required this.name,
    required this.isFavorite,
    required this.count,
    required this.seeds,
    this.avgRating,
    this.coverPath,
  });
  final int id, count;
  final String name;
  final bool isFavorite;
  final double? avgRating;
  final String? coverPath;
  final List<String> seeds;
}
