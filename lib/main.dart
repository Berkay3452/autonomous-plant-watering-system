import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/strings.dart';
import 'providers/alerts_provider.dart';
import 'providers/plants_provider.dart';
import 'providers/pots_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/app_shell.dart';
import 'services/device_service.dart';
import 'services/mock_device_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final prefs = await SharedPreferences.getInstance();

  // Haberleşme seçilince yalnızca bu satır değişecek (örn. FirebaseDeviceService).
  final DeviceService device = MockDeviceService();

  final settings = SettingsProvider(prefs);
  Intl.defaultLocale = Strings.localeName;
  Intl.defaultLocale = Strings.localeName;
  final plants = PlantsProvider(prefs);
  final pots = PotsProvider(prefs: prefs, device: device, plants: plants, settings: settings);
  final schedules = ScheduleProvider(
    prefs: prefs,
    device: device,
    potIds: [for (final pot in pots.pots) pot.id],
  );
  final alerts = AlertsProvider(prefs: prefs, device: device, pots: pots, settings: settings);

  runApp(PlantWateringApp(
    settings: settings,
    plants: plants,
    pots: pots,
    schedules: schedules,
    alerts: alerts,
  ));

  // Arayüz açıldıktan sonra cihaza bağlan.
  alerts.init();
  await schedules.init();
  await pots.init();
}

class PlantWateringApp extends StatelessWidget {
  const PlantWateringApp({
    super.key,
    required this.settings,
    required this.plants,
    required this.pots,
    required this.schedules,
    required this.alerts,
  });

  final SettingsProvider settings;
  final PlantsProvider plants;
  final PotsProvider pots;
  final ScheduleProvider schedules;
  final AlertsProvider alerts;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: plants),
        ChangeNotifierProvider.value(value: pots),
        ChangeNotifierProvider.value(value: schedules),
        ChangeNotifierProvider.value(value: alerts),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          onGenerateTitle: (context) => context.t('Bitki Sulama'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          locale: settings.language.locale,
          supportedLocales: [for (final lang in AppLang.values) lang.locale],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppShell(),
        ),
      ),
    );
  }
}
