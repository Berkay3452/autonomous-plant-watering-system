import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tasarımdaki hap biçimli segment kontrolü (Saksı 1 / Saksı 2, Gün / Hafta / Ay,
/// Türkçe / English...).
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.disabled = const {},
  });

  /// (değer, etiket) çiftleri.
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;

  /// Seçilemeyen değerler. Dokununca [onChanged] çağrılmaz.
  final Set<T> disabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.titleSmall;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.control, borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: [
          for (final (itemValue, label) in items)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(itemValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: itemValue == value ? p.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    label,
                    style: style?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: itemValue == value
                          ? p.onPrimary
                          : disabled.contains(itemValue)
                              ? p.textMuted.withValues(alpha: 0.6)
                              : p.text,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
