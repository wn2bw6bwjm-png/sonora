import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';

class FilePickerWidget extends StatelessWidget {
  const FilePickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Выбор аудиофайла',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Pick file button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Will be connected to repository
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Выбрать файл'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                ),
              ),
            ),

            // File list area
            Expanded(
              child: _buildFileList(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Выберите аудиофайл для прослушивания',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Форматы: MP3, WAV, FLAC, M4A и др.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}