import 'package:flutter/material.dart';

enum AlertType {
  plantDry('Bitki susuz', Icons.water_drop_outlined, isWarning: true),
  tankLow('Depo seviyesi düşük', Icons.waves, isWarning: true),
  deviceOffline('Cihaz çevrimdışı', Icons.wifi_off, isWarning: true),
  wateringBlocked('Sulama yapılamadı', Icons.block, isWarning: true),
  wateringDone('Sulama tamamlandı', Icons.check_circle_outline, isWarning: false);

  const AlertType(this.label, this.icon, {required this.isWarning});

  final String label;
  final IconData icon;
  final bool isWarning;
}

/// Uygulama içi bildirim kaydı.
class AppAlert {
  const AppAlert({
    required this.id,
    required this.type,
    required this.time,
    required this.message,
    this.potId,
    this.read = false,
  });

  final String id;
  final AlertType type;
  final String? potId;
  final DateTime time;
  final String message;
  final bool read;

  AppAlert copyWith({bool? read}) => AppAlert(
        id: id,
        type: type,
        potId: potId,
        time: time,
        message: message,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'potId': potId,
        'time': time.toIso8601String(),
        'message': message,
        'read': read,
      };

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: json['id'] as String,
      type: AlertType.values.byName(json['type'] as String),
      potId: json['potId'] as String?,
      time: DateTime.parse(json['time'] as String),
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
    );
  }
}
