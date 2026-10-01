import '../models/device_config.dart';
import '../models/device_snapshot.dart';
import '../models/reading.dart';
import '../models/schedule.dart';
import '../models/watering_event.dart';

/// Uygulamanın cihazla (ESP32) konuştuğu soyut arayüz.
///
/// Şimdilik [MockDeviceService] sahte veri üretir. Haberleşme yöntemi
/// (Firebase / MQTT / yerel ağ) seçilince yalnızca bu arayüzün yeni bir
/// uygulaması yazılır; ekranlar ve provider'lar değişmez.
abstract class DeviceService {
  /// Gerçek ya da sahte cihazın adı (Ayarlar ekranında gösterilir).
  String get name;

  bool get isConnected;

  /// Pompa debisi (ml/sn). Doküman 3.4'teki kalibrasyonla ölçülür.
  double get pumpFlowMlPerSec;

  /// Depo hacmi (ml).
  double get tankCapacityMl;

  /// Canlı ölçümler. Cihaz çevrimdışıyken veri gelmez.
  Stream<DeviceSnapshot> get snapshots;

  /// Tamamlanan ya da engellenen sulamalar.
  Stream<WateringEvent> get events;

  DeviceSnapshot? get lastSnapshot;

  Future<void> connect();

  Future<void> disconnect();

  Future<List<Reading>> fetchHistory(String potId, Duration range);

  /// "Şimdi sula" komutu. Güvenlik kuralları cihazda kontrol edilir.
  Future<WateringResult> waterNow(String potId, int amountPercent);

  /// Planları cihaz belleğine yazar.
  Future<void> syncSchedules(List<WateringSchedule> schedules);

  Future<void> updateConfig(DeviceConfig config);

  void dispose();
}
