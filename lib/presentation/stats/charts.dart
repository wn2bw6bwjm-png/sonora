import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/usecases/statistics.dart';

FlTitlesData _titles(Widget Function(double) bottom) => FlTitlesData(
      leftTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: 1,
          getTitlesWidget: (v, meta) => Padding(padding: const EdgeInsets.only(top: 8), child: bottom(v)),
        ),
      ),
    );

class RatingDistributionChart extends StatelessWidget {
  const RatingDistributionChart({super.key, required this.distribution});
  final List<int> distribution;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final maxY = (distribution.reduce((a, b) => a > b ? a : b) + 1).toDouble();
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: _titles((v) => Text('${v.toInt()}', style: t.textTheme.bodySmall)),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => t.colorScheme.onSurface,
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                'Оценка ${group.x}: ${rod.toY.toInt()}',
                TextStyle(color: t.colorScheme.surface, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < distribution.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: distribution[i].toDouble(),
                  width: 14,
                  color: t.colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Rad.sm)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.months});
  final List<MonthPoint> months;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final maxV = months.fold<int>(0, (m, p) => [m, p.added, p.rated].reduce((a, b) => a > b ? a : b));
    LineChartBarData line(List<double> ys, Color c) => LineChartBarData(
          spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
          isCurved: false,
          color: c,
          barWidth: 2,
          dotData: const FlDotData(show: true),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (months.length - 1).toDouble(),
            minY: 0,
            maxY: (maxV + 1).toDouble(),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: _titles((v) {
              final i = v.toInt();
              return Text(i >= 0 && i < months.length ? months[i].label : '', style: t.textTheme.bodySmall);
            }),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => t.colorScheme.onSurface,
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${months[s.x.toInt()].label} · ${s.barIndex == 0 ? 'добавлено' : 'оценок'}: ${s.y.toInt()}',
                      TextStyle(color: t.colorScheme.surface, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              line([for (final m in months) m.added.toDouble()], t.colorScheme.onSurfaceVariant),
              line([for (final m in months) m.rated.toDouble()], t.colorScheme.primary),
            ],
          ),
        ),
      ),
      const SizedBox(height: Sp.md),
      Row(children: [
        _Dot(t.colorScheme.onSurfaceVariant),
        const SizedBox(width: Sp.xs),
        Text('Добавлено альбомов', style: t.textTheme.bodySmall),
        const SizedBox(width: Sp.lg),
        _Dot(t.colorScheme.primary),
        const SizedBox(width: Sp.xs),
        Text('Оценок', style: t.textTheme.bodySmall),
      ]),
    ]);
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
