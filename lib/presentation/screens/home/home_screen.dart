import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/domain/entities/track.dart';
import 'package:sonora/data/repositories/track_repository_impl.dart';
import 'package:sonora/services/recommendation_engine.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/presentation/widgets/track_tile.dart';
import 'package:sonora/presentation/widgets/skeleton_loader.dart';
import 'package:sonora/routing/page_transitions.dart';
import 'package:sonora/presentation/screens/settings/settings_screen.dart';
import 'package:sonora/presentation/screens/player/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrackRepository _repository = TrackRepositoryImpl();
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  late Future<List<Track>> _trendingFuture;
  late Future<List<Track>> _recommendationsFuture;
  Track? _currentTrack;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _trendingFuture = _repository.getTrendingTracks();
    _recommendationsFuture = _recommendationEngine.getRecommendations(limit: 10);
  }

  void _reload() {
    setState(() {
      _trendingFuture = _repository.getTrendingTracks();
      _recommendationsFuture = _recommendationEngine.getRecommendations(limit: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SONORA'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentTrack != null) MiniPlayer(track: _currentTrack),
          NavigationBar(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (i) =>
                setState(() => _selectedNavIndex = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Главная'),
              NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: 'Поиск'),
              NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Медиатека'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedNavIndex == 0) {
      return _buildHomeContent();
    } else if (_selectedNavIndex == 1) {
      return _buildSearchPlaceholder();
    } else {
      return _buildLibraryPlaceholder();
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: CustomScrollView(
        slivers: [
          // Welcome header
          SliverToBoxAdapter(
            child: _buildWelcomeHeader(),
          ),

          // Recommendations
          SliverToBoxAdapter(
            child: _buildSectionTitle('Рекомендации для вас'),
          ),
          SliverToBoxAdapter(
            child: _buildRecommendations(),
          ),

          // Trending
          SliverToBoxAdapter(
            child: _buildSectionTitle('Популярное сейчас'),
          ),
          _buildTrendingList(),

          // Genres placeholder
          SliverToBoxAdapter(
            child: _buildSectionTitle('Жанры'),
          ),
          SliverToBoxAdapter(
            child: _buildGenres(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for mini player
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 6) greeting = 'Доброй ночи';
    else if (hour < 12) greeting = 'Доброе утро';
    else if (hour < 18) greeting = 'Добрый день';
    else greeting = 'Добрый вечер';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Что будем слушать сегодня?',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return FutureBuilder<List<Track>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (_, __) => const RecommendationCardSkeleton(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDiscoverFallback();
        }

        final tracks = snapshot.data!;
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _buildRecommendationCard(track);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecommendationCard(Track track) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            SharedAxisPageRoute(
              child: PlayerScreen(initialTrack: track),
              transitionType: SharedAxisTransitionType.vertical,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'album-art-${track.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                    ? Image.network(
                        track.coverUrl!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _cardPlaceholder(),
                      )
                    : _cardPlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getSourceLabel(track.sourceName),
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverFallback() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Рекомендации появятся после прослушивания',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _selectedNavIndex = 1),
              icon: const Icon(Icons.search),
              label: const Text('Найти музыку'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingList() {
    return FutureBuilder<List<Track>>(
      future: _trendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const TrackTileSkeleton(),
              childCount: 8,
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: _buildError(snapshot.error.toString()));
        }

        final tracks = snapshot.data ?? [];
        if (tracks.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: Text('Нет данных', style: TextStyle(color: AppTheme.textSecondary)))));
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = tracks[index];
              return TrackTile(
                track: track,
                isCurrent: _currentTrack?.id == track.id,
                onTap: () {
                  Navigator.push(
                    context,
                    SharedAxisPageRoute(
                      child: PlayerScreen(initialTrack: track),
                      transitionType: SharedAxisTransitionType.vertical,
                    ),
                  );
                },
              );
            },
            childCount: tracks.length > 10 ? 10 : tracks.length,
          ),
        );
      },
    );
  }

  Widget _buildGenres() {
    const genres = [
      {'name': 'Поп', 'icon': Icons.music_note},
      {'name': 'Рок', 'icon': Icons.electric_guitar},
      {'name': 'Хип-хоп', 'icon': Icons.headphones},
      {'name': 'Электроника', 'icon': Icons.speaker},
      {'name': 'Инди', 'icon': Icons.library_music},
      {'name': 'Джаз', 'icon': Icons.saxophone},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.3),
                      AppTheme.secondary.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(genre['icon'] as IconData, size: 40, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      genre['name'] as String,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'Поиск — перейдите на вкладку Поиск',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_music, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'Медиатека — перейдите на вкладку Медиатека',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Не удалось загрузить треки',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardPlaceholder() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.music_note, size: 48, color: AppTheme.textSecondary),
      ),
    );
  }

  String _getSourceLabel(String sourceName) {
    switch (sourceName.toLowerCase()) {
      case 'audius':
        return 'Audius';
      case 'itunes':
        return 'iTunes';
      case 'internet archive':
        return 'Archive';
      case 'local':
        return 'Локально';
      default:
        return sourceName;
    }
  }
}