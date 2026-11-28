import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/widgets/mini_player.dart';
import 'package:sonora/data/hive/hive_service.dart';
import 'package:sonora/services/recommendation_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HiveService _hiveService = HiveService();
  Track? _currentTrack;

  bool _darkMode = true;
  bool _showSourceBadges = true;
  bool _autoPlayNext = true;
  bool _enableBackgroundPlayback = true;

  String _cacheSize = '0 MB';
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheSize();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? true;
      _showSourceBadges = prefs.getBool('showSourceBadges') ?? true;
      _autoPlayNext = prefs.getBool('autoPlayNext') ?? true;
      _enableBackgroundPlayback = prefs.getBool('enableBackgroundPlayback') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _loadCacheSize() async {
    setState(() => _isLoadingCache = true);
    final size = _hiveService.getCacheSize();
    setState(() {
      _cacheSize = size ?? '0 MB';
      _isLoadingCache = false;
    });
  }

  Future<void> _clearCache(String type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Очистить $type', style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text('Удалить $type? Это действие нельзя отменить.', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Очистить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type очищен')));
      _loadCacheSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme section
          _buildSectionHeader('Внешний вид'),
          _buildTile(
            title: 'Тёмная тема',
            subtitle: 'Включить тёмный интерфейс',
            trailing: Switch(
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
                _saveSetting('darkMode', value);
              },
              activeColor: AppTheme.primary,
            ),
          ),
          _buildTile(
            title: 'Показывать значки источников',
            subtitle: 'Отображать Audius/iTunes/Local в поиске',
            trailing: Switch(
              value: _showSourceBadges,
              onChanged: (value) {
                setState(() => _showSourceBadges = value);
                _saveSetting('showSourceBadges', value);
              },
              activeColor: AppTheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Playback section
          _buildSectionHeader('Воспроизведение'),
          _buildTile(
            title: 'Автоматический переход к следующему',
            subtitle: 'Автоматически играть следующий трек',
            trailing: Switch(
              value: _autoPlayNext,
              onChanged: (value) {
                setState(() => _autoPlayNext = value);
                _saveSetting('autoPlayNext', value);
              },
              activeColor: AppTheme.primary,
            ),
          ),
          _buildTile(
            title: 'Фоновое воспроизведение',
            subtitle: 'Играть музыку при свёрнутом приложении',
            trailing: Switch(
              value: _enableBackgroundPlayback,
              onChanged: (value) {
                setState(() => _enableBackgroundPlayback = value);
                _saveSetting('enableBackgroundPlayback', value);
              },
              activeColor: AppTheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Music Sources section
          _buildSectionHeader('Музыкальные источники'),
          _buildTile(
            title: 'Источники музыки',
            subtitle: 'Управление подключёнными источниками',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: _showSourceSettings,
          ),

          const SizedBox(height: 24),

          // Cache section
          _buildSectionHeader('Кэш и хранилище'),
          _buildTile(
            title: 'Размер кэша',
            subtitle: _isLoadingCache ? 'Загрузка...' : _cacheSize,
            trailing: _isLoadingCache
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: _loadCacheSize,
          ),
          _buildTile(
            title: 'Очистить обложки',
            subtitle: 'Удалить загруженные обложки альбомов',
            onTap: () => _clearCache('обложки'),
          ),
          _buildTile(
            title: 'Очистить временные файлы',
            subtitle: 'Удалить временные данные приложения',
            onTap: () => _clearCache('временные файлы'),
          ),
          _buildTile(
            title: 'Очистить историю поиска',
            subtitle: 'Удалить все поисковые запросы',
            onTap: () => _clearCache('историю поиска'),
          ),

          const SizedBox(height: 24),

          // Data section
          _buildSectionHeader('Данные'),
          _buildTile(
            title: 'Рекомендации',
            subtitle: 'Персональные рекомендации на основе истории',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: _showRecommendationInfo,
          ),
          _buildTile(
            title: 'Экспорт данных',
            subtitle: 'Скачать ваши плейлисты, избранное, историю',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: _exportData,
          ),
          _buildTile(
            title: 'Сбросить настройки',
            subtitle: 'Вернуть все настройки к значениям по умолчанию',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: _resetSettings,
          ),

          const SizedBox(height: 24),

          // About section
          _buildSectionHeader('О приложении'),
          _buildTile(
            title: 'Версия',
            subtitle: '1.0.0+1',
            trailing: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
          ),
          _buildTile(
            title: 'Лицензии',
            subtitle: 'Открытые лицензии используемых библиотек',
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: _showLicenses,
          ),
          _buildTile(
            title: 'Конфиденциальность',
            subtitle: 'SONORA не собирает личные данные',
            trailing: const Icon(Icons.privacy_tip_outlined, color: AppTheme.textSecondary),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentTrack != null) MiniPlayer(track: _currentTrack),
          const NavigationBar(
            selectedIndex: 2,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showSourceSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Музыкальные источники', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildSourceToggle('Audius', true, 'Бесплатная стриминговая платформа'),
            _buildSourceToggle('iTunes Search', true, 'Поиск превью и метаданных'),
            _buildSourceToggle('Internet Archive', true, 'Архив свободной музыки'),
            _buildSourceToggle('Локальные файлы', true, 'Ваша музыка на устройстве'),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceToggle(String name, bool value, String description) {
    return ListTile(
      title: Text(name, style: const TextStyle(color: AppTheme.textPrimary)),
      subtitle: Text(description, style: const TextStyle(color: AppTheme.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: (v) {},
        activeColor: AppTheme.primary,
      ),
    );
  }

  void _showRecommendationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Как работают рекомендации', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'SONORA строит рекомендации локально на вашем устройстве:\n\n'
          '• Любимые жанры (из избранного)\n'
          '• Любимые исполнители\n'
          '• История прослушивания\n'
          '• Альбомы и плейлисты\n\n'
          'Данные не покидают ваше устройство.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Экспорт данных будет доступен в следующем обновлении')),
    );
  }

  void _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Сбросить настройки', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Все настройки вернутся к значениям по умолчанию.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сбросить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сброшены')));
    }
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'SONORA',
      applicationVersion: '1.0.0+1',
      applicationIcon: const Icon(Icons.music_note, color: AppTheme.primary),
      applicationLegalese: '© 2024 SONORA. Бесплатный музыкальный агрегатор.',
    );
  }
}