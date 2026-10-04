import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/alerts_provider.dart';
import '../providers/pots_provider.dart';
import '../providers/settings_provider.dart';
import '../services/mock_device_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_segmented.dart';

/// Ayarlar: tasarımdaki Görünüm, Dil ve Sıcaklık birimi kartları; altında
/// sulama güvenliği, bildirim eşikleri ve cihaz ayarları.
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: context.palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('Vazgeç'))),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
              onPressed: () => Navigator.pop(context, current),
              child: Text(context.t('Kaydet')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, SettingsProvider settings) async {
    final controller = TextEditingController(text: settings.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Adın')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: context.t('Örn. Berkay')),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('Vazgeç'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.t('Kaydet')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) settings.setUserName(name);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final pots = context.watch<PotsProvider>();
    final device = pots.device;
    final mock = device is MockDeviceService ? device : null;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 22, AppSpacing.page, 120),
          children: [
            Text(t('Ayarlar'), style: text.headlineMedium),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.contrast_rounded,
              title: t('Görünüm'),
              child: Row(
                children: [
                  for (final mode in ThemeMode.values) ...[
                    if (mode != ThemeMode.values.first) const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeTile(
                        mode: mode,
                        selected: settings.themeMode == mode,
                        onTap: () => settings.setThemeMode(mode),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.language_rounded,
              title: t('Dil'),
              child: PillSegmented<AppLang>(
                items: [for (final lang in AppLang.values) (lang, lang.label)],
                value: settings.language,
                onChanged: settings.setLanguage,
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.thermostat_rounded,
              title: t('Sıcaklık birimi'),
              child: PillSegmented<bool>(
                items: [(false, t('Celsius (°C)')), (true, t('Fahrenheit (°F)'))],
                value: settings.fahrenheit,
                onChanged: settings.setFahrenheit,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
              child: Text(t('Sulama ve güvenlik'), style: text.titleLarge),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.auto_mode_rounded),
                    title: Text(t('Nem eşiğine göre otomatik mod')),
                    subtitle: Text(
                      t('Nem bitkinin minimum değerinin altına inince cihaz kısa dozlarla sular.'),
                    ),
                    value: settings.autoMode,
                    onChanged: settings.setAutoMode,
                  ),
                  const Divider(),
                  for (final pot in pots.pots) ...[
                    ListTile(
                      leading: const Icon(Icons.local_drink_outlined),
                      title: Text(t('{0} tam doz (%100)', [t(pot.name)])),
                      subtitle: Text(t('Saksının bir seferde alabileceği en fazla su')),
                      trailing: Text('${pot.fullDoseMl} ml', style: text.titleSmall),
                      onTap: () async {
                        final v = await _pickNumber(
                          context,
                          title: t('{0} tam doz', [t(pot.name)]),
                          value: pot.fullDoseMl,
                          min: 50,
                          max: 500,
                          step: 10,
                          format: (v) => '$v ml',
                          help: t('Uygulamadaki %50, bu miktarın yarısı demektir.'),
                        );
                        if (v != null) pots.setFullDoseMl(pot.id, v);
                      },
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(t('Azami pompa süresi')),
                    subtitle: Text(t('Tek sulamada pompanın en fazla çalışma süresi')),
                    trailing: Text(t('{0} sn', [settings.maxPumpSeconds]), style: text.titleSmall),
                    onTap: () async {
                      final v = await _pickNumber(
                        context,
                        title: t('Azami pompa süresi'),
                        value: settings.maxPumpSeconds,
                        min: 5,
                        max: 120,
                        step: 5,
                        format: (v) => Strings.t('{0} sn', [v]),
                      );
                      if (v != null) settings.setMaxPumpSeconds(v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.hourglass_bottom_rounded),
                    title: Text(t('İki sulama arası en az')),
                    subtitle: Text(t('Aşırı sulama koruması')),
                    trailing: Text(formatMinutes(settings.minIntervalMinutes), style: text.titleSmall),
                    onTap: () async {
                      final v = await _pickNumber(
                        context,
                        title: t('İki sulama arası en az'),
                        value: settings.minIntervalMinutes,
                        min: 0,
                        max: 60,
                        format: formatMinutes,
                        help: t('Dokümandaki öneri 10 dk. Demo için 1 dk ayarlı.'),
                      );
                      if (v != null) settings.setMinIntervalMinutes(v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: Text(t('Kuru çalışma eşiği')),
                    subtitle: Text(t('Depo bu seviyedeyken pompalar kilitlenir')),
                    trailing: Text(formatPercent(settings.tankCriticalThreshold), style: text.titleSmall),
                    onTap: () async {
                      final v = await _pickNumber(
                        context,
                        title: t('Kuru çalışma eşiği'),
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

            Padding(
              padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
              child: Text(t('Bildirimler'), style: text.titleLarge),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.propane_tank_outlined),
                    title: Text(t('Depo uyarı eşiği')),
                    trailing: Text(formatPercent(settings.tankAlertThreshold), style: text.titleSmall),
                    onTap: () async {
                      final v = await _pickNumber(
                        context,
                        title: t('Depo uyarı eşiği'),
                        value: settings.tankAlertThreshold,
                        min: 5,
                        max: 50,
                        step: 5,
                        format: formatPercent,
                      );
                      if (v != null) settings.setTankAlertThreshold(v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.water_drop_outlined),
                    title: Text(t('"Bitki susadı" için bekleme')),
                    subtitle: Text(t('Nem bu süre boyunca eşiğin altında kalırsa')),
                    trailing: Text(t('{0} sn', [settings.dryConfirmSeconds]), style: text.titleSmall),
                    onTap: () async {
                      final v = await _pickNumber(
                        context,
                        title: t('"Bitki susadı" için bekleme'),
                        value: settings.dryConfirmSeconds,
                        min: 0,
                        max: 600,
                        step: 30,
                        format: (v) => Strings.t('{0} sn', [v]),
                        help: t('Dokümandaki öneri 5 dk (300 sn).'),
                      );
                      if (v != null) settings.setDryConfirmSeconds(v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.wifi_off_rounded),
                    title: Text(t('Çevrimdışı sayılma süresi')),
                    trailing: Text(t('{0} sn', [settings.offlineAfterSeconds]), style: text.titleSmall),
                    onTap: () async {
                      final v = await _pickNumber(
                        context,
                        title: t('Çevrimdışı sayılma süresi'),
                        value: settings.offlineAfterSeconds,
                        min: 10,
                        max: 300,
                        step: 10,
                        format: (v) => Strings.t('{0} sn', [v]),
                      );
                      if (v != null) settings.setOfflineAfterSeconds(v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.repeat_rounded),
                    title: Text(t('Aynı uyarının tekrar aralığı')),
                    trailing: Text(formatMinutes(settings.alertRepeatMinutes), style: text.titleSmall),
                    onTap: () async {
                      final v = await _pickNumber(
                        context,
                        title: t('Tekrar aralığı'),
                        value: settings.alertRepeatMinutes,
                        min: 0,
                        max: 720,
                        step: 30,
                        format: formatMinutes,
                        help: t('Dokümandaki öneri 6 sa. Test ederken düşürebilirsin.'),
                      );
                      if (v != null) settings.setAlertRepeatMinutes(v);
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
              child: Text(t('Profil ve cihaz'), style: text.titleLarge),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(t('Adın')),
                    subtitle: Text(t('Ana sayfadaki karşılamada görünür')),
                    trailing: Text(settings.userName, style: text.titleSmall),
                    onTap: () => _editName(context, settings),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.memory_rounded),
                    title: Text(t(device.name)),
                    subtitle: Text(t('Haberleşme yöntemi henüz seçilmedi (Firebase / MQTT / yerel ağ).')),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.speed_rounded),
                    title: Text(t('Pompa debisi')),
                    trailing: Text('${device.pumpFlowMlPerSec.toStringAsFixed(0)} ml/${t('sn')}', style: text.titleSmall),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(t('Depo hacmi')),
                    trailing: Text('${device.tankCapacityMl.round()} ml', style: text.titleSmall),
                  ),
                ],
              ),
            ),

            if (mock != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
                child: Text(t('Simülasyon (sahte cihaz)'), style: text.titleLarge),
              ),
              _SimulationCard(mock: mock),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm, left: 4, right: 4),
                child: Text(
                  t('Bu bölüm yalnızca sahte cihazla çalışırken görünür. Gerçek ESP32 bağlanınca kaybolur.'),
                  style: text.bodySmall?.copyWith(color: p.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Başlıklı ayar kartı (Görünüm, Dil, Sıcaklık birimi).
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.okBg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: p.okFg),
              ),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Görünüm seçeneği: Sistem / Açık / Koyu önizlemeli kutu.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.mode, required this.selected, required this.onTap});

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  static const _lightBg = Color(0xFFE6F3BF);
  static const _darkBg = Color(0xFF2B7337);

  String _label(BuildContext context) => switch (mode) {
        ThemeMode.system => context.t('Sistem'),
        ThemeMode.light => context.t('Açık'),
        ThemeMode.dark => context.t('Koyu'),
      };

  Widget _preview() {
    final light = Container(
      color: _lightBg,
      alignment: Alignment.center,
      child: Container(
        width: 46,
        height: 26,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      ),
    );
    final dark = Container(
      color: _darkBg,
      alignment: Alignment.center,
      child: Container(
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    return switch (mode) {
      ThemeMode.light => light,
      ThemeMode.dark => dark,
      ThemeMode.system => Row(
          children: [Expanded(child: light), Expanded(child: dark)],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        decoration: BoxDecoration(
          color: selected ? p.control : p.tile,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? p.primary : Colors.transparent, width: 3),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(height: 62, width: double.infinity, child: _preview()),
            ),
            const SizedBox(height: 8),
            Text(_label(context), style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
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
    final pots = context.read<PotsProvider>().pots;
    final t = context.t;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.wifi_off_rounded),
            title: Text(t('Cihazı çevrimdışı yap')),
            subtitle: Text(t('Veri gelmez; programlı sulama cihazda sürer.')),
            value: mock.isOffline,
            onChanged: (v) => setState(() => mock.setOffline(v)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.water_rounded),
            title: Text(t('Depoyu doldur')),
            onTap: () {
              mock.refillTank();
              _done(t('Depo %100 dolduruldu.'));
            },
          ),
          ListTile(
            leading: const Icon(Icons.water_damage_outlined),
            title: Text(t('Depoyu %12\'ye düşür')),
            subtitle: Text(t('"Su deposu azalıyor" uyarısını dener')),
            onTap: () {
              mock.setTankLevel(12);
              _done(t('Depo %12\'ye düşürüldü.'));
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded),
            title: Text(t('Depoyu %3\'e düşür')),
            subtitle: Text(t('Kuru çalışma kilidini dener')),
            onTap: () {
              mock.setTankLevel(3);
              _done(t('Depo %3\'e düşürüldü, pompa kilitlenecek.'));
            },
          ),
          for (final pot in pots)
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(t('{0} toprağını kurut', [t(pot.name)])),
              subtitle: Text(t('Nemi %15\'e indirir, "bitki susadı" uyarısını dener')),
              onTap: () {
                mock.drySoil(pot.id);
                _done(t('{0} nemi %15\'e indirildi.', [t(pot.name)]));
              },
            ),
          SwitchListTile(
            secondary: const Icon(Icons.fast_forward_rounded),
            title: Text(t('Hızlı kuruma')),
            subtitle: Text(t('Toprak 10 kat hızlı kurur')),
            value: mock.dryingMultiplier > 1,
            onChanged: (v) => setState(() => mock.setDryingMultiplier(v ? 10 : 1)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: Text(t('Uyarı tekrar sürelerini sıfırla')),
            subtitle: Text(t('Aynı uyarıyı hemen tekrar görebilmek için')),
            onTap: () {
              context.read<AlertsProvider>().resetCooldowns();
              _done(t('Uyarı tekrar süreleri sıfırlandı.'));
            },
          ),
        ],
      ),
    );
  }
}
