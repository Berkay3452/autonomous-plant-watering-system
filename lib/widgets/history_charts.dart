import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/reading.dart';
import '../models/watering_event.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/history_math.dart';

/// Geçmiş ekranındaki toprak nemi çizgi grafiği. Çizgi yumuşatılır, altı
/// doldurulur; sulamalar işaretle gösterilir. Yatay kesikli çizgiler %0, %50
/// ve %100 seviyelerini belirtir.
class MoistureLineChart extends StatelessWidget {
  const MoistureLineChart({
    super.key,
    required this.points,
    required this.window,
    required this.events,
    this.height = 190,
  });

  final List<Reading> points;
  final ChartWindow window;
  final List<WateringEvent> events;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinePainter(
          points: points,
          window: window,
          events: events,
          palette: p,
          tickStyle: text.labelMedium!.copyWith(color: p.textMuted, fontSize: 12),
          markerStyle: text.labelMedium!.copyWith(color: p.text, fontSize: 12.5),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.window,
    required this.events,
    required this.palette,
    required this.tickStyle,
    required this.markerStyle,
  });

  final List<Reading> points;
  final ChartWindow window;
  final List<WateringEvent> events;
  final AppPalette palette;
  final TextStyle tickStyle;
  final TextStyle markerStyle;

  static const _topPad = 26.0;
  static const _labelHeight = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final top = _topPad;
    final bottom = size.height - _labelHeight;
    final chartH = bottom - top;
    final spanMs = max(1, window.end.difference(window.start).inMilliseconds);

    double xOf(DateTime t) =>
        w * (t.difference(window.start).inMilliseconds / spanMs).clamp(0.0, 1.0);
    double yOf(double moisture) => bottom - chartH * (moisture.clamp(0, 100) / 100);

    // Kesikli yatay çizgiler.
    for (final level in const [100.0, 50.0, 0.0]) {
      _dashed(canvas, Offset(0, yOf(level)), Offset(w, yOf(level)), palette.chartGrid);
    }

    final visible = points.where((r) => !r.time.isBefore(window.start)).toList();
    final offsets = [for (final r in visible) Offset(xOf(r.time), yOf(r.moisture))];

    if (offsets.length >= 2) {
      final line = _smooth(offsets);
      final area = Path.from(line)
        ..lineTo(offsets.last.dx, bottom)
        ..lineTo(offsets.first.dx, bottom)
        ..close();
      canvas.drawPath(area, Paint()..color = palette.chartFill);
      canvas.drawPath(
        line,
        Paint()
          ..color = palette.chartLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Sulama işaretleri.
    final inWindow = events
        .where((e) => e.success && !e.time.isBefore(window.start) && !e.time.isAfter(window.end))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final ringColor = palette.isDark ? Colors.white : palette.chartLine;
    Offset? lastMarker;
    DateTime? lastMarkerTime;
    for (final e in inWindow) {
      final y = _nearestY(visible, e.time, yOf);
      if (y == null) continue;
      final center = Offset(xOf(e.time), y);
      canvas.drawCircle(center, 8.5, Paint()..color = palette.accent);
      canvas.drawCircle(
        center,
        8.5,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      lastMarker = center;
      lastMarkerTime = e.time;
    }
    // Yalnızca günlük grafikte son sulamanın saatini yaz.
    if (lastMarker != null && window.end.difference(window.start) <= const Duration(days: 1, hours: 1)) {
      _text(
        canvas,
        Strings.t('{0} sulama', [formatTime(lastMarkerTime!)]),
        markerStyle,
        Offset(lastMarker.dx, lastMarker.dy - 30),
        w,
        centered: true,
      );
    }

    // Güncel değer noktası.
    if (offsets.isNotEmpty) {
      final end = offsets.last;
      canvas.drawCircle(end, 7, Paint()..color = Colors.white);
      canvas.drawCircle(
        end,
        7,
        Paint()
          ..color = palette.chartLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }

    // Alt eksen etiketleri.
    for (final tick in window.ticks) {
      _text(canvas, tick.label, tickStyle, Offset(xOf(tick.time), size.height - 20), w, centered: true);
    }
  }

  double? _nearestY(List<Reading> readings, DateTime t, double Function(double) yOf) {
    if (readings.isEmpty) return null;
    var best = readings.first;
    var bestDiff = best.time.difference(t).abs();
    for (final r in readings) {
      final diff = r.time.difference(t).abs();
      if (diff < bestDiff) {
        best = r;
        bestDiff = diff;
      }
    }
    return yOf(best.moisture);
  }

  /// Noktalardan geçen yumuşak (Catmull-Rom) eğri.
  Path _smooth(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 5.0;
    const gap = 5.0;
    var x = a.dx;
    while (x < b.dx) {
      canvas.drawLine(Offset(x, a.dy), Offset(min(x + dash, b.dx), a.dy), paint);
      x += dash + gap;
    }
  }

  void _text(Canvas canvas, String text, TextStyle style, Offset anchor, double maxWidth,
      {bool centered = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final raw = centered ? anchor.dx - tp.width / 2 : anchor.dx;
    final dx = raw.clamp(0.0, max(0.0, maxWidth - tp.width)).toDouble();
    tp.paint(canvas, Offset(dx, anchor.dy));
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.window != window ||
      old.events != events ||
      old.palette != palette;
}

/// Sıcaklık çubuk grafiği. Çubuk yüksekliği 0–40 °C ölçeğinde çizilir;
/// vurgulu çubuk güncel değerdir. Veri olmayan dilimlerde kısa bir iz görünür.
class TemperatureBars extends StatelessWidget {
  const TemperatureBars({super.key, required this.buckets, this.height = 168});

  final List<BarBucket> buckets;
  final double height;

  static const _maxCelsius = 40.0;
  static const _labelHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final barArea = height - _labelHeight;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final b in buckets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: b.value == null
                              ? 8
                              : max(14.0, barArea * (b.value! / _maxCelsius).clamp(0.0, 1.0)),
                          decoration: BoxDecoration(
                            color: b.value == null
                                ? p.bar.withValues(alpha: 0.3)
                                : (b.highlight ? p.barHighlight : p.bar),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 2, color: p.chartGrid),
          SizedBox(
            height: _labelHeight - 2,
            child: Row(
              children: [
                for (final b in buckets)
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          b.label,
                          style: text.labelMedium?.copyWith(
                            fontSize: 12.5,
                            color: b.highlight ? p.primary : p.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
