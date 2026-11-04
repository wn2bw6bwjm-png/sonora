import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: t.colorScheme.onSurfaceVariant),
            const SizedBox(height: Sp.lg),
            Text(title, style: t.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Sp.sm),
            Text(message,
                style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: Sp.xl),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel ?? 'Продолжить')),
            ],
          ],
        ),
      ),
    );
  }
}
