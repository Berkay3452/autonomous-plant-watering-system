import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alerts_provider.dart';
import '../providers/pot_provider.dart';
import '../providers/settings_provider.dart';
import '../services/mock_device_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_header.dart';

/// Ayarlar: saksı, sulama güvenliği, bildirimler, görünüm, cihaz bilgisi ve
/// (sahte cihazda) simülasyon kontrolleri.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Kaydırıcılı sayı seçme penceresi.
  Future<int?> _pickNumber(
    BuildContext context, {
    required String title,
    required int value,
    required int min,
    required int max,
    int step = 1,
    required String Function(int) format,
    String? help,
  }) {
    var current = value.clamp(min, max);
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                format(current),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Slider(
                value: current.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min) ~/ step,
                onChanged: (v) => setState(() => current = v.round()),
              ),
              if (help != null)
                Text(help, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(context, current), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final pot = context.watch<PotProvider>();
    final device = pot.device;
    final mock = device is MockDeviceService ? device : null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
        children: [
          const SectionHeader(title: 'Saksı'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.yard_outlined),
                  title: const Text('Saksı'),
                  subtitle: Text('${pot.pot.name} · ${pot.plant?.name ?? 'bitki seçilmedi'}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_drink_outlined),
                  title: const Text('Tam doz (%100)'),
                  subtitle: const Text('Saksının bir seferde alabileceği en fazla su'),
                  trailing: Text('${pot.pot.fullDoseMl} ml'),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: 'Tam doz',
                      value: pot.pot.fullDoseMl,
                      min: 50,
                      max: 500,
                      step: 10,
                      format: (v) => '$v ml',
                      help: 'Uygulamadaki %50, bu miktarın yarısı demektir.',
                    );
                    if (v != null) pot.setFullDoseMl(v);
                  },
                ),
              ],
            ),
          ),

          const SectionHeader(title: 'Sulama ve güvenlik'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.auto_mode),
                  title: const Text('Otomatik mod'),
                  subtitle: Text(
                    pot.plant == null
                        ? 'Önce saksıya bitki atayın.'
                        : 'Nem ${formatPercent(pot.plant!.minMoisture)} altına inince kısa dozlarla '
                            '${formatPercent(pot.plant!.idealMoistureMin)} olana kadar sular.',
                  ),
                  value: settings.autoMode,
                  onChanged: settings.setAutoMode,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Azami pompa süresi'),
                  subtitle: const Text('Tek sulamada pompanın en fazla çalışma süresi'),
                  trailing: Text('${settings.maxPumpSeconds} sn'),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: 'Azami pompa süresi',
                      value: settings.maxPumpSeconds,
                      min: 5,
                      max: 120,
                      step: 5,
                      format: (v) => '$v sn',
                    );
                    if (v != null) settings.setMaxPumpSeconds(v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.hourglass_bottom),
                  title: const Text('İki sulama arası en az'),
                  subtitle: const Text('Aşırı sulama koruması'),
                  trailing: Text(formatMinutes(settings.minIntervalMinutes)),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: 'İki sulama arası en az',
                      value: settings.minIntervalMinutes,
                      min: 0,
                      max: 60,
                      format: formatMinutes,
                      help: 'Dokümandaki öneri 10 dk. Demo için 1 dk ayarlı.',
                    );
                    if (v != null) settings.setMinIntervalMinutes(v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Kuru çalışma eşiği'),
                  subtitle: const Text('Depo bu seviyedeyken pompalar kilitlenir'),
                  trailing: Text(formatPercent(settings.tankCriticalThreshold)),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: 'Kuru çalışma eşiği',
                      value: settings.tankCriticalThreshold,
                      min: 0,
                      max: 30,
                      format: formatPercent,
                    );
                    if (v != null) settings.setTankCriticalThreshold(v);
                  },
                ),
              ],
            ),
          ),

          const SectionHeader(title: 'Bildirimler'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.waves),
                  title: const Text('Depo uyarı eşiği'),
                  trailing: Text(formatPercent(settings.tankAlertThreshold)),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: 'Depo uyarı eşiği',
                      value: settings.tankAlertThreshold,
                      min: 5,
                      max: 50,
                      step: 5,
                      format: formatPercent,
                    );
                    if (v != null) settings.setTankAlertThreshold(v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: const Text('"Bitki susuz" için bekleme'),
                  subtitle: const Text('Nem bu süre boyunca eşiğin altında kalırsa'),
                  trailing: Text('${settings.dryConfirmSeconds} sn'),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: '"Bitki susuz" için bekleme',
                      value: settings.dryConfirmSeconds,
                      min: 0,
                      max: 600,
                      step: 30,
                      format: (v) => '$v sn',
                      help: 'Dokümandaki öneri 5 dk (300 sn).',
                    );
                    if (v != null) settings.setDryConfirmSeconds(v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wifi_off),
                  title: const Text('Çevrimdışı sayılma süresi'),
                  trailing: Text('${settings.offlineAfterSeconds} sn'),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: 'Çevrimdışı sayılma süresi',
                      value: settings.offlineAfterSeconds,
                      min: 10,
                      max: 300,
                      step: 10,
                      format: (v) => '$v sn',
                    );
                    if (v != null) settings.setOfflineAfterSeconds(v);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.repeat),
                  title: const Text('Aynı uyarının tekrar aralığı'),
                  trailing: Text(formatMinutes(settings.alertRepeatMinutes)),
                  onTap: () async {
                    final v = await _pickNumber(
                      context,
                      title: 'Tekrar aralığı',
                      value: settings.alertRepeatMinutes,
                      min: 0,
                      max: 720,
                      step: 30,
                      format: formatMinutes,
                      help: 'Dokümandaki öneri 6 sa. Test ederken düşürebilirsiniz.',
                    );
                    if (v != null) settings.setAlertRepeatMinutes(v);
                  },
                ),
              ],
            ),
          ),

          const SectionHeader(title: 'Görünüm'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Sistem'), icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Açık'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Koyu'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (v) => settings.setThemeMode(v.first),
              ),
            ),
          ),

          const SectionHeader(title: 'Cihaz'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.memory),
                  title: Text(device.name),
                  subtitle: const Text('Haberleşme yöntemi henüz seçilmedi (Firebase / MQTT / yerel ağ).'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Pompa debisi'),
                  trailing: Text('${device.pumpFlowMlPerSec.toStringAsFixed(0)} ml/sn'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Depo hacmi'),
                  trailing: Text('${device.tankCapacityMl.round()} ml'),
                ),
              ],
            ),
          ),

          if (mock != null) ...[
            const SectionHeader(title: 'Simülasyon (sahte cihaz)'),
            _SimulationCard(mock: mock),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, left: 4, right: 4),
              child: Text(
                'Bu bölüm yalnızca sahte cihazla çalışırken görünür. Gerçek ESP32 bağlanınca kaybolur.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimulationCard extends StatefulWidget {
  const _SimulationCard({required this.mock});

  final MockDeviceService mock;

  @override
  State<_SimulationCard> createState() => _SimulationCardState();
}

class _SimulationCardState extends State<_SimulationCard> {
  void _done(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final mock = widget.mock;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.wifi_off),
            title: const Text('Cihazı çevrimdışı yap'),
            subtitle: const Text('Veri gelmez; planlı sulama cihazda sürer.'),
            value: mock.isOffline,
            onChanged: (v) => setState(() => mock.setOffline(v)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.water),
            title: const Text('Depoyu doldur'),
            onTap: () {
              mock.refillTank();
              _done('Depo %100 dolduruldu.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_damage_outlined),
            title: const Text('Depoyu %12\'ye düşür'),
            subtitle: const Text('"Depo düşük" uyarısını dener'),
            onTap: () {
              mock.setTankLevel(12);
              _done('Depo %12\'ye düşürüldü.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Depoyu %3\'e düşür'),
            subtitle: const Text('Kuru çalışma kilidini dener'),
            onTap: () {
              mock.setTankLevel(3);
              _done('Depo %3\'e düşürüldü, pompa kilitlenecek.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Toprağı kurut'),
            subtitle: const Text('Nemi %15\'e indirir, "bitki susuz" uyarısını dener'),
            onTap: () {
              mock.drySoil();
              _done('Toprak nemi %15\'e indirildi.');
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fast_forward),
            title: const Text('Hızlı kuruma'),
            subtitle: const Text('Toprak 10 kat hızlı kurur'),
            value: mock.dryingMultiplier > 1,
            onChanged: (v) => setState(() => mock.setDryingMultiplier(v ? 10 : 1)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Uyarı tekrar sürelerini sıfırla'),
            subtitle: const Text('Aynı uyarıyı hemen tekrar görebilmek için'),
            onTap: () {
              context.read<AlertsProvider>().resetCooldowns();
              _done('Uyarı tekrar süreleri sıfırlandı.');
            },
          ),
        ],
      ),
    );
  }
}
