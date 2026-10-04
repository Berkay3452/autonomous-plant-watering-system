import 'package:flutter/material.dart';

import '../models/pot.dart';
import '../theme/app_theme.dart';

/// Saksının durumunu gösteren hap biçimli etiket ("İyi durumda",
/// "Sulama gerekli").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, icon) = switch (tone) {
      StatusTone.good => (p.accent, p.onAccent, Icons.check_rounded),
      StatusTone.warn => (p.warnBg, p.warnFg, Icons.water_drop_outlined),
      StatusTone.neutral => (p.control, p.text, Icons.info_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}
