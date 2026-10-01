import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/plant.dart';
import '../models/reading.dart';
import '../providers/pot_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum ChartMetric {
  moisture('Toprak nemi', AppColors.moisture),
  temperature('Sıcaklık', AppColors.temperature);

  const ChartMetric(this.label, this.color);

  final String label;
  final Color color;
}

/// Geçmiş ölçümlerin çizgi grafiği. Nem grafiğinde bitkinin ideal aralığı
/// yeşil bant, minimum eşiği kesikli kırmızı çizgi olarak gösterilir.
class MoistureChart extends StatelessWidget {
  const MoistureChart({
    super.key,
    required this.readings,
    required this.range,
    required this.metric,
    this.plant,
  });

  final List<Reading> readings;
  final ChartRange range;
  final ChartMetric metric;
  final Plant? plant;

  double _valueOf(Reading r) =>
      metric == ChartMetric.moisture ? r.moisture : r.temperature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (readings.length < 2) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text('Grafik için yeterli veri yok.', style: text.bodyMedium),
        ),
      );
    }

    final now = DateTime.now();
    final minX = now.subtract(range.duration).millisecondsSinceEpoch.toDouble();
    final maxX = now.millisecondsSinceEpoch.toDouble();
    final spots = [
      for (final r in readings) FlSpot(r.time.millisecondsSinceEpoch.toDouble(), _valueOf(r)),
    ];

    final double minY;
    final double maxY;
    final double yInterval;
    if (metric == ChartMetric.moisture) {
      minY = 0;
      maxY = 100;
      yInterval = 25;
    } else {
      final values = spots.map((s) => s.y);
      var low = values.reduce(min);
      var high = values.reduce(max);
      if (plant != null) {
        low = min(low, plant!.tempMin);
        high = max(high, plant!.tempMax);
      }
      minY = (low - 2).floorToDouble();
      maxY = (high + 2).ceilToDouble();
      yInterval = max(1, ((maxY - minY) / 4).roundToDouble());
    }

    final xInterval = range == ChartRange.day
        ? const Duration(hours: 6).inMilliseconds.toDouble()
        : const Duration(days: 1).inMilliseconds.toDouble();
    final bottomFormat = range == ChartRange.day ? DateFormat.Hm('tr_TR') : DateFormat.E('tr_TR');

    final p = plant;
    final band = p == null
        ? null
        : metric == ChartMetric.moisture
            ? (p.idealMoistureMin.toDouble(), p.idealMoistureMax.toDouble())
            : (p.tempMin, p.tempMax);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              if (band != null)
                HorizontalRangeAnnotation(
                  y1: band.$1,
                  y2: band.$2,
                  color: AppColors.ideal.withValues(alpha: 0.12),
                ),
            ],
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (p != null && metric == ChartMetric.moisture)
                HorizontalLine(
                  y: p.minMoisture.toDouble(),
                  color: AppColors.danger.withValues(alpha: 0.8),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: text.labelSmall?.copyWith(color: AppColors.danger),
                    labelResolver: (_) => 'min ${formatPercent(p.minMoisture)}',
                  ),
                ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  final label = metric == ChartMetric.moisture
                      ? formatPercent(value)
                      : '${value.round()}°';
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(label, style: text.labelSmall),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                  final t = DateTime.fromMillisecondsSinceEpoch(value.round());
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(bottomFormat.format(t), style: text.labelSmall),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItems: (touched) => touched.map((spot) {
                final t = DateTime.fromMillisecondsSinceEpoch(spot.x.round());
                final value = metric == ChartMetric.moisture
                    ? formatPercent(spot.y)
                    : formatTemperature(spot.y);
                return LineTooltipItem(
                  '$value\n',
                  TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                      text: formatDateTime(t),
                      style: TextStyle(
                        color: scheme.onInverseSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: metric.color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    metric.color.withValues(alpha: 0.25),
                    metric.color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
