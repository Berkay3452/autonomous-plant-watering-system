import 'package:flutter/material.dart';

import '../providers/pot_provider.dart';
import '../theme/app_theme.dart';

/// Cihaz bağlantı durumu etiketi (çevrimiçi / bağlanıyor / çevrimdışı).
class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({super.key, required this.connection});

  final DeviceConnection connection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (connection) {
      DeviceConnection.online => ('Çevrimiçi', AppColors.ideal, Icons.wifi),
      DeviceConnection.connecting => ('Bağlanıyor', scheme.outline, Icons.sync),
      DeviceConnection.offline => ('Çevrimdışı', AppColors.danger, Icons.wifi_off),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connection == DeviceConnection.connecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
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
