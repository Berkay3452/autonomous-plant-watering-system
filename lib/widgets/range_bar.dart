import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Değerin, ideal aralığa göre nerede olduğunu gösteren yatay çubuk.
///
/// [min]–[max] çubuğun ölçeğidir. [idealMin]–[idealMax] vurgulu bant,
/// [threshold] uyarı çizgisi, [value] işaretçi olarak çizilir.
class RangeBar extends StatelessWidget {
  const RangeBar({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.idealMin,
    this.idealMax,
    this.threshold,
    this.height = 10,
  });

  final double? value;
  final double min;
  final double max;
  final double? idealMin;
  final double? idealMax;
  final double? threshold;
  final double height;

  double _fraction(double v) => ((v - min) / (max - min)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return SizedBox(
        height: height + 8,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: p.track,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            if (idealMin != null && idealMax != null)
              Positioned(
                left: width * _fraction(idealMin!),
                width: width * (_fraction(idealMax!) - _fraction(idealMin!)),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            if (threshold != null)
              Positioned(
                left: width * _fraction(threshold!) - 1,
                child: Container(width: 2.5, height: height + 6, color: p.warnText),
              ),
            if (value != null)
              Positioned(
                left: width * _fraction(value!) - (height + 6) / 2,
                child: Container(
                  width: height + 6,
                  height: height + 6,
                  decoration: BoxDecoration(
                    color: p.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.sheet, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
