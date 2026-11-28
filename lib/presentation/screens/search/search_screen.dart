import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/widgets/track_tile.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/data/repositories/track_repository_impl.dart';
import 'package:sonora/data/repositories/local_track_repository.dart';
import 'package:sonora/data/datasources/local_datasource.dart';
import 'package:sonora/data/hive/hive_service.dart';

enum SearchSourceFilter { all, online, local }
enum SearchAvailabilityFilter { all, available, unavailable }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TrackRepository _repository = TrackRepositoryImpl();
  final HiveService _hiveService = HiveService();

  SearchSourceFilter _sourceFilter = SearchSourceFilter.all;
  SearchAvailabilityFilter _availabilityFilter = SearchAvailabilityFilter.all;

  String _searchQuery = '';
  bool _isSearching = false;
  List<Track> _searchResults = [];
  Track? _currentTrack;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _showHistory = _searchQuery.isEmpty;
    });
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _showHistory = false;
    });

    try {
      List<Track> results;
      switch (_sourceFilter) {
        case SearchSourceFilter.online:
          results = await _repository.searchTracks(_searchQuery);
          break;
        case SearchSourceFilter.local:
          final localRepo = LocalTrackRepositoryImpl(
            dataSource: LocalDataSource(),
            hiveService: _hiveService,
          );
          results = await localRepo.getLocalTracks();
          results = results.where((t) =>
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.artist.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
          break;
        case SearchSourceFilter.all:
          results = await _repository.searchTracksAcrossSources(_searchQuery);
          // Also search local
          final localRepo = LocalTrackRepositoryImpl(
            dataSource: LocalDataSource(),
            hiveService: _hiveService,
          );
          final localResults = await localRepo.getLocalTracks();
          final localFiltered = localResults.where((t) =>
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.artist.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
          results.addAll(localFiltered);
      }

      // Apply availability filter
      if (_availabilityFilter == SearchAvailabilityFilter.available) {
        results = results.where((t) => t.availabilityType == 'full').toList();
      } else if (_availabilityFilter == SearchAvailabilityFilter.unavailable) {
        results = results.where((t) => t.availabilityType != 'full').toList();
      }

      // Deduplicate
      final seen = <String>{};
      results = results.where((t) => seen.add(t.id)).toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        // Save to history
        await _hiveService.addSearchQuery(_searchQuery);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    await _hiveService.clearSearchHistory();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск композиций, исполнителей, альбомов...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _performSearch(),
              )
            : const Text('Поиск'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Поиск',
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Отмена',
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _isSearching = false;
                  _searchResults.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_isSearching || _searchResults.isNotEmpty)
            _buildFilterChips(),
          // Content
          Expanded(
            child: _showHistory ? _buildHistoryView() : _buildResultsView(),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentTrack != null) MiniPlayer(track: _currentTrack),
          const NavigationBar(
            selectedIndex: 1,
            onDestinationSelected: (i) => {},
            destinations: [
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

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'Источник',
            child: DropdownButton<SearchSourceFilter>(
              value: _sourceFilter,
              underline: const SizedBox(),
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: AppTheme.textPrimary),
              items: const [
                DropdownMenuItem(value: SearchSourceFilter.all, child: Text('Все')),
                DropdownMenuItem(value: SearchSourceFilter.online, child: Text('Онлайн')),
                DropdownMenuItem(value: SearchSourceFilter.local, child: Text('Локальная')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sourceFilter = value);
                  _performSearch();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Доступность',
            child: DropdownButton<SearchAvailabilityFilter>(
              value: _availabilityFilter,
              underline: const SizedBox(),
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: AppTheme.textPrimary),
              items: const [
                DropdownMenuItem(value: SearchAvailabilityFilter.all, child: Text('Все')),
                DropdownMenuItem(value: SearchAvailabilityFilter.available, child: Text('Доступно')),
                DropdownMenuItem(value: SearchAvailabilityFilter.unavailable, child: Text('Недоступно')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _availabilityFilter = value);
                  _performSearch();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    final history = _hiveService.getSearchHistory();
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Введите запрос для поиска',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.onSurfaceVariant),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 24),
            const Text(
              'История поиска появится здесь',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'История поиска',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: const Text('Очистить', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...history.reversed.map((query) => ListTile(
              leading: const Icon(Icons.history, color: AppTheme.textSecondary),
              title: Text(query, style: const TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                _searchController.text = query;
                _performSearch();
              },
            )),
      ],
    );
  }

  Widget _buildResultsView() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isEmpty) {
      return _buildHistoryView();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.clear, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Ничего не найдено',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры или запрос',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        return TrackTile(
          track: track,
          isCurrent: _currentTrack?.id == track.id,
          onTap: () => setState(() => _currentTrack = track),
          trailing: _buildSourceBadge(track),
        );
      },
    );
  }

  Widget _buildSourceBadge(Track track) {
    Color color;
    String label;
    switch (track.sourceName.toLowerCase()) {
      case 'audius':
        color = Colors.purple;
        label = 'Audius';
        break;
      case 'itunes':
        color = Colors.blue;
        label = 'iTunes';
        break;
      case 'internet archive':
        color = Colors.orange;
        label = 'Archive';
        break;
      case 'local':
        color = Colors.green;
        label = 'Локально';
        break;
      default:
        color = AppTheme.textSecondary;
        label = track.sourceName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}