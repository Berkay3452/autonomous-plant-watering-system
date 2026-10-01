import 'package:flutter/material.dart';

import '../models/pot.dart';
import '../theme/app_theme.dart';

/// Saksının nem durumunu gösteren küçük etiket.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final PotStatus status;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forStatus(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppColors.iconForStatus(status), size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
