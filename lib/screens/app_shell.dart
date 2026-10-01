import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../providers/alerts_provider.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';
import 'home_screen.dart';
import 'plants_screen.dart';
import 'settings_screen.dart';

/// Alt gezinme çubuklu ana iskelet: Panel, Bitkiler, Bildirimler, Ayarlar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  StreamSubscription<AppAlert>? _alertSub;

  static const _alertsTab = 2;

  @override
  void initState() {
    super.initState();
    _alertSub = context.read<AlertsProvider>().newAlerts.listen(_showAlert);
  }

  void _showAlert(AppAlert alert) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              alert.type.icon,
              color: alert.type.isWarning ? AppColors.warning : AppColors.ideal,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('${alert.type.label}: ${alert.message}')),
          ],
        ),
        action: _index == _alertsTab
            ? null
            : SnackBarAction(label: 'Gör', onPressed: () => setState(() => _index = _alertsTab)),
        duration: const Duration(seconds: 5),
      ));
  }

  void goToTab(int index) => setState(() => _index = index);

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<AlertsProvider, int>((a) => a.unreadCount);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenAlerts: () => goToTab(_alertsTab)),
          const PlantsScreen(),
          const AlertsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goToTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_florist_outlined),
            selectedIcon: Icon(Icons.local_florist),
            label: 'Bitkiler',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Bildirimler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
