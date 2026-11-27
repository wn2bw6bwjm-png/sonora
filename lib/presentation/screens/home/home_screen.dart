import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/blocs/home/home_bloc.dart';
import 'package:sonora/presentation/blocs/home/home_event.dart';
import 'package:sonora/presentation/blocs/home/home_state.dart';
import 'package:sonora/presentation/blocs/player/player_bloc.dart';
import 'package:sonora/presentation/blocs/player/player_event.dart';
import 'package:sonora/presentation/blocs/player/player_state.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/presentation/widgets/file_picker_widget.dart';
import 'package:sonora/domain/entities/track.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final HomeBloc _homeBloc;
  late final PlayerBloc _playerBloc;
  late TabController _tabController;
  int _selectedBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
    _playerBloc = context.read<PlayerBloc>();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs now
    _homeBloc.add(const HomeInitialEvent());
    // Listen to player state changes for mini-player
    _playerBloc.listen((state) {
      // Rebuild mini player on state change
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(theme, isDark),
      body: _buildBody(context, theme, isDark),
      bottomNavigationBar: _buildBottomNav(theme, isDark),
      // Add mini player at the very bottom, above system navigation
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 72),
        child: MiniPlayer(),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      title: const Text('SONORA'),
      backgroundColor: isDark
          ? AppTheme.primaryDark
          : Colors.white,
      elevation: 0,
      foregroundColor: isDark ? AppTheme.textPrimary : AppTheme.primaryDark,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Navigate to search
          },
        ),
        IconButton(
          icon: const Icon(Icons.file_upload),
          tooltip: 'Загрузить свой файл',
          onPressed: () {
            // Navigate to file picker - but we use a sheet instead
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Функция загрузки файлов в разработке')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(
      BuildContext context,
      ThemeData theme,
      bool isDark,
      ) {
    return SafeArea(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _buildHeader(theme, isDark),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTrendingSection(theme, isDark),
            _buildSearchSection(theme, isDark),
            _buildLibrarySection(theme, isDark),
            _buildFileSection(theme, isDark), // New tab
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: isDark
          ? AppTheme.surfaceColor
          : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Hello,',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark ? AppTheme.textSecondary : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back!',
            style: theme.textTheme.displayMedium?.copyWith(
              color: isDark ? AppTheme.textPrimary : AppTheme.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Quick access
          const SizedBox(height: 24),
          Text(
            'Quick Access',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.textPrimary : AppTheme.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Favorite tracks preview
          _buildQuickAccessGrid(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) => _QuickAccessItem(
          onTap: () {
            // Handle quick access tap
          },
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildFileSection(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Мои аудиофайлы',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.textPrimary : AppTheme.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // File picker widget
          FilePickerWidget(),

          const SizedBox(height: 24),

          // Recently added from files
          Text(
            'Последние добавленные',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? AppTheme.textPrimary : AppTheme.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildRecentFilesGrid(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildRecentFilesGrid(ThemeData theme, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        crossAxisExtent: 120,
        mainAxisExtent: 140,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 4, // Placeholder count
      itemBuilder: (context, index) => _RecentFileCard(
        isDark: isDark,
        onTap: () {
          // Handle file tap - would pick and play
        },
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAccessItem({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.favorite_border,
              size: 32,
              color: isDark ? AppTheme.accentColor : AppTheme.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentFileCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _RecentFileCard({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? AppTheme.cardColor : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Placeholder for file icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Аудиофайл ${index + 1}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? AppTheme.textPrimary : AppTheme.primaryDark,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0:00',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.textSecondary : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Play button
              IconButton(
                icon: Icon(
                  Icons.play_arrow,
                  color: isDark ? AppTheme.accentColor : AppTheme.primaryDark,
                  size: 20,
                ),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}