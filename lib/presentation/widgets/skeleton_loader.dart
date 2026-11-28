import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';

/// Skeleton loader for track tiles
class TrackTileSkeleton extends StatelessWidget {
  const TrackTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildSkeletonBox(48, 48, 6),
      title: _buildSkeletonLine(width: double.infinity, height: 16),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: _buildSkeletonLine(width: 120, height: 12),
      ),
      trailing: _buildSkeletonLine(width: 50, height: 12),
    );
  }

  Widget _buildSkeletonBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: _ShimmerEffect(),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: _ShimmerEffect(),
    );
  }
}

/// Shimmer animation effect
class _ShimmerEffect extends StatefulWidget {
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
              AppTheme.onSurfaceVariant.withValues(alpha: 0.2),
              AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for album/artist grid cards
class GridCardSkeleton extends StatelessWidget {
  const GridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: _ShimmerEffect(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerEffect(
                  child: Container(height: 16, width: double.infinity),
                ),
                const SizedBox(height: 4),
                _ShimmerEffect(
                  child: Container(height: 12, width: 80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for horizontal recommendation cards
class RecommendationCardSkeleton extends StatelessWidget {
  const RecommendationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 160,
              height: 160,
              color: AppTheme.cardColor,
              child: _ShimmerEffect(),
            ),
          ),
          const SizedBox(height: 8),
          _ShimmerEffect(
            child: Container(height: 16, width: double.infinity),
          ),
          const SizedBox(height: 4),
          _ShimmerEffect(
            child: Container(height: 12, width: 100),
          ),
          const SizedBox(height: 4),
          _ShimmerEffect(
            child: Container(height: 14, width: 60),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for home screen sections
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerEffect(
                  child: Container(height: 28, width: 150),
                ),
                const SizedBox(height: 4),
                _ShimmerEffect(
                  child: Container(height: 16, width: 200),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ShimmerEffect(
              child: Container(height: 18, width: 150),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (_, __) => const RecommendationCardSkeleton(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ShimmerEffect(
              child: Container(height: 18, width: 120),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const TrackTileSkeleton(),
            childCount: 8,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ShimmerEffect(
              child: Container(height: 18, width: 80),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (_, __) => const _GenreChipSkeleton(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _GenreChipSkeleton extends StatelessWidget {
  const _GenreChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: AppTheme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShimmerEffect(
                child: Container(width: 40, height: 40),
              ),
              const SizedBox(height: 8),
              _ShimmerEffect(
                child: Container(width: 80, height: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}