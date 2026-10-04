import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/alert.dart';
import '../providers/alerts_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_nav.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'pots_screen.dart';
import 'settings_screen.dart';

/// Alt gezinme çubuklu ana iskelet: Ana sayfa, Saksılarım, Geçmiş, Ayarlar.
/// Bildirimler ana sayfadaki zil simgesinden açılır.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  StreamSubscription<AppAlert>? _alertSub;

  static const _tabs = [
    NavTab('Ana sayfa', Icons.home_outlined, Icons.home_rounded),
    NavTab('Saksılarım', Icons.yard_outlined, Icons.yard),
    NavTab('Geçmiş', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    NavTab('Ayarlar', Icons.settings_outlined, Icons.settings),
  ];

  // Sekme adları sabit Türkçe metindir; ekranda çevrilerek gösterilir.

  @override
  void initState() {
    super.initState();
    _alertSub = context.read<AlertsProvider>().newAlerts.listen(_showAlert);
  }

  void _openNotifications() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  void _showAlert(AppAlert alert) {
    if (!mounted) return;
    final p = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              alert.type.isWarning ? Icons.notifications_active_outlined : Icons.check_circle_outline,
              color: alert.type.isWarning ? const Color(0xFFFCE3CC) : p.accent,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('${alert.title}. ${alert.message}')),
          ],
        ),
        action: SnackBarAction(label: Strings.t('Gör'), onPressed: _openNotifications),
        duration: const Duration(seconds: 5),
      ));
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenNotifications: _openNotifications),
          const PotsScreen(),
          const HistoryScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNav(
        tabs: [
          for (final tab in _tabs) NavTab(context.t(tab.label), tab.icon, tab.selectedIcon),
        ],
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
