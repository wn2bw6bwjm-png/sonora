import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.page, Sp.xl, Sp.page, Sp.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: t.textTheme.headlineSmall)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text('Все', style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary)),
            ),
        ],
      ),
    );
  }
}
