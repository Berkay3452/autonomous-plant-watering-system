# Otonom Bitki Sulama Sistemi

Bitkilerin toprak nemini ölçen ve kullanıcının mobil uygulamadan belirlediği zamanda, belirlediği miktarda otomatik sulama yapan ESP32 tabanlı bir sistem. Bu repo şu an **Flutter (Android) mobil uygulamasını** içerir. ESP32 yazılımı (firmware) sonradan `firmware/` klasörüne eklenecek.

> **Durum:** Uygulama arayüzü hazır ve **sahte (mock) bir cihazla** çalışır. Gerçek ESP32 bağlantısı henüz yok; haberleşme yöntemi (Firebase / MQTT / yerel ağ) ekipçe seçilecek. Ayrıntılar için `bitki_projesi_yol_haritası.pdf` dosyasına bakın.

## İçindekiler

- [Uygulama neler yapıyor](#uygulama-neler-yapıyor)
- [Kurulum (Windows)](#kurulum-windows)
- [Projeyi çalıştırma](#projeyi-çalıştırma)
- [Sahte cihazı deneme](#sahte-cihazı-deneme)
- [Testler ve kod kontrolü](#testler-ve-kod-kontrolü)
- [Proje yapısı](#proje-yapısı)
- [Gerçek cihaza geçiş](#gerçek-cihaza-geçiş)
- [Sık karşılaşılan sorunlar](#sık-karşılaşılan-sorunlar)
- [Ekip çalışma düzeni](#ekip-çalışma-düzeni)

## Uygulama neler yapıyor

Arayüz, `docs/design/` klasöründeki Claude Design çıktılarına (açık ve koyu tema) göre yapıldı. 2 saksı desteklenir.

| Ekran | İçerik |
|---|---|
| **Ana sayfa** | Saksı seçici (Saksı 1 / 2), bitki çizimi ve nem halkası, durum etiketi, toprak nemi, sıcaklık, su deposu, sonraki sulama, "Şimdi Sula". Zil simgesi Bildirimler'i açar. |
| **Saksılarım** | Her saksının bitkisi, durumu, nemi, sıcaklığı ve sıradaki sulaması; ortak su deposu. Karta dokununca bitki türü seçilir. |
| **Bitki türü** | 6 kategori (Tropikal, Sukulent, Kaktüs, Çiçekli, Aromatik, Sebze & Meyve). "Devam et" ile o kategorideki bitkilere geçilir; bitki ayrıntısı görülüp saksıya atanır, kendi bitkini de ekleyebilirsin. |
| **Sulama programı** | Saksı başına saat, haftanın günleri, su miktarı (%) ve açma/kapama. Ana sayfadaki "Sonraki sulama" kutusundan açılır. |
| **Geçmiş** | Gün / Hafta / Ay seçenekli toprak nemi çizgi grafiği (sulamalar işaretli) ve sıcaklık çubukları. |
| **Bildirimler** | Bitki susadı, su deposu azalıyor, cihaz çevrimdışı, sulama tamamlandı / yapılamadı. Susayan bitki için "Şimdi Sula" düğmesi vardır. |
| **Ayarlar** | Görünüm (Sistem / Açık / Koyu), dil (Türkçe / English), sıcaklık birimi (°C / °F). Altında güvenlik süreleri, bildirim eşikleri, profil ve cihaz ayarları. |

Bilinen eksikler:

- Telefon bildirim çubuğuna bildirim (şimdilik yalnızca uygulama içi) ve gerçek ESP32 haberleşmesi.
- Yazı tipleri (Baloo 2 ve Nunito) ilk açılışta internetten indirilir, telefonun internete bağlı olması gerekir.

## Kurulum (Windows)

Bu bölüm sıfırdan bir Windows bilgisayar içindir. Uygulama **Flutter 3.47.5 / Dart 3.13.4** ile geliştirildi (`pubspec.yaml` içinde `sdk: ^3.13.4`). Daha yeni bir Flutter sürümü de genelde çalışır. Dart ayrıca kurulmaz, Flutter ile birlikte gelir.

### 1. Git

[git-scm.com](https://git-scm.com/download/win) adresinden indirip kurun. Kontrol:

```bash
git --version
```

### 2. Flutter SDK

1. Resmi kurulum sayfasını açın: <https://docs.flutter.dev/install> ve Windows + Android seçeneğini izleyin.
2. SDK'yı boşluk ve Türkçe karakter içermeyen bir klasöre açın, örneğin `C:\src\flutter`. (`C:\Program Files` gibi yetki isteyen klasörlere açmayın.)
3. `C:\src\flutter\bin` klasörünü **Path** ortam değişkenine ekleyin: *Başlat → "Ortam değişkenlerini düzenle" → Kullanıcı değişkenleri → Path → Düzenle → Yeni*.
4. Açık olan tüm terminalleri kapatıp yenisini açın ve kontrol edin:

```bash
flutter --version
```

### 3. Android Studio ve Android SDK

Telefona uygulama yüklemek için Android SDK gerekir. En kolay yol Android Studio'dur.

1. [developer.android.com/studio](https://developer.android.com/studio) adresinden Android Studio'yu kurun.
2. İlk açılışta kurulum sihirbazını **Standard** seçeneğiyle tamamlayın. Android SDK, platform araçları ve JDK de bununla gelir.
3. Android Studio'da *More Actions → SDK Manager → SDK Tools* sekmesinde şunların işaretli olduğundan emin olun: **Android SDK Command-line Tools**, **Android SDK Platform-Tools**.
4. Lisansları kabul edin:

```bash
flutter doctor --android-licenses
```

Soruların hepsine `y` yazıp Enter'a basın.

### 4. VS Code (isteğe bağlı ama önerilir)

[code.visualstudio.com](https://code.visualstudio.com/) adresinden kurun, sonra şu eklentileri yükleyin: **Flutter** ve **Dart**.

### 5. Kurulumu doğrulama

```bash
flutter doctor
```

Şunların yanında yeşil işaret (`[√]`) olmalı:

- **Flutter**
- **Android toolchain**
- **Connected device** (telefon bağlıyken)

`Visual Studio - develop Windows apps` satırındaki kırmızı çarpı (`[X]`) **önemli değil**. O yalnızca Windows masaüstü uygulaması geliştirmek içindir, bu proje Android hedefler.

## Projeyi çalıştırma

### Kodu indirme

```bash
git clone https://github.com/Berkay3452/autonomous-plant-watering-system.git
cd autonomous-plant-watering-system
flutter pub get
```

`flutter pub get` projenin ihtiyaç duyduğu paketleri indirir. Yeni bir paket eklenince ya da `pubspec.yaml` değişince tekrar çalıştırılır.

### Seçenek A: Android telefonda (önerilen)

1. Telefonda **Geliştirici seçeneklerini** açın: *Ayarlar → Telefon hakkında → Yapı numarası*'na 7 kez dokunun.
2. *Ayarlar → Geliştirici seçenekleri → **USB hata ayıklama*** seçeneğini açın.
3. Telefonu **veri aktarabilen** bir USB kabloyla bağlayın (yalnızca şarj eden kablolar çalışmaz). Telefon ekranında çıkan *"USB hata ayıklamaya izin verilsin mi?"* sorusunda **İzin ver**'e dokunun.
4. Telefonun göründüğünü kontrol edin:

```bash
flutter devices
```

5. Uygulamayı başlatın:

```bash
flutter run
```

İlk derleme **birkaç dakika** sürebilir (Gradle bileşenleri iner). Sonrakiler çok daha hızlıdır. Uygulama açıkken terminalde:

| Tuş | Ne yapar |
|---|---|
| `r` | Kod değişikliğini anında uygular (hot reload) |
| `R` | Uygulamayı baştan başlatır (hot restart) |
| `q` | Çıkış |

### Seçenek B: Tarayıcıda (telefon yoksa)

Ekranlara hızlıca bakmak için yeterlidir:

```bash
flutter run -d chrome
```

Tarayıcıyı dar bir pencere yaparsanız (telefon boyutu) arayüz gerçeğine daha yakın görünür.

### Seçenek C: Kurulum dosyası (APK) üretme

```bash
flutter build apk
```

Dosya `build\app\outputs\flutter-apk\app-release.apk` konumunda oluşur. Telefona kopyalayıp açarak kurabilirsiniz (telefonda "bilinmeyen kaynaklardan yüklemeye izin ver" gerekebilir).

## Sahte cihazı deneme

Uygulama şu an ESP32'yi taklit eden `MockDeviceService` ile çalışır:

- Toprak zamanla kurur, sulayınca nem artar ve depo azalır.
- Planlı sulamayı cihaz tarafında kendisi çalıştırır.
- Güvenlik kuralları uygulanır: depo kritik seviyedeyse pompa kilitlenir, tek sulamada azami pompa süresi vardır, iki sulama arasında asgari bekleme vardır.

**Ayarlar → Simülasyon** bölümünden şunlar denenebilir:

| Kontrol | Denenen senaryo |
|---|---|
| Depoyu %12'ye düşür | "Su deposu azalıyor" bildirimi |
| Depoyu %3'e düşür | Kuru çalışma kilidi, pompa çalışmaz |
| Saksı 1 / 2 toprağını kurut | "Bitki susadı" bildirimi (60 sn sonra) |
| Cihazı çevrimdışı yap | Çevrimdışı bildirimi; programlı sulama cihazda sürer |
| Uyarı tekrar sürelerini sıfırla | Aynı uyarıyı hemen tekrar görmek için |

Bu bölüm yalnızca sahte cihazla çalışırken görünür.

**İlk açılışta:** Saksı 1'de Difenbahya, Saksı 2'de Barış Çiçeği vardır (tasarımdaki örnek). Saksı 2 son 30 saattir sulanmamış gibi başlar; bu yüzden bir süre sonra "Bitki susadı" bildirimi görürsünüz. Saksı 1 düzenli sulanmış gibi başlar. Her saksıda son 30 günün geçmişi hazır gelir.

**Programlı sulamayı denemek için:** Sulama programı ekranında saati şimdiden 2 dakika sonrasına, günü de bugüne ayarlayıp Kaydet'e basın. Süre dolunca cihaz kendisi sular ve "Sulama tamamlandı" bildirimi gelir.

**Demo için kısaltılan süreler** (Ayarlar'dan değiştirilebilir): iki sulama arası bekleme 1 dk (dokümandaki öneri 10 dk), "bitki susadı" doğrulama süresi 60 sn (öneri 5 dk).

> Uygulama verileri (saksı bitkileri, programlar, ayarlar, eklediğin bitkiler) telefonda saklanır. Sahte cihazın ölçümleri ise her açılışta yeniden üretilir.

## Testler ve kod kontrolü

```bash
flutter analyze   # kod hatalarını ve stil sorunlarını denetler
flutter test      # tüm testleri çalıştırır
```

Testler plan zamanlama mantığını, bitki kataloğunu, nem durumunu, grafik örneklemeyi ve sahte cihazın güvenlik kurallarını kapsar. Commit atmadan önce ikisinin de temiz geçmesi beklenir.

## Proje yapısı

```
lib/
  main.dart                 Giriş noktası; servisler ve provider'lar burada kurulur
  theme/app_theme.dart      Tasarımın renk paleti (açık/koyu), yazı tipleri, Material 3 tema
  models/                   Veri sınıfları (Plant, Pot, WateringSchedule, AppAlert ...)
  data/plant_catalog.dart   Hazır bitki profilleri (6 kategori)
  services/
    device_service.dart       Cihazla konuşan soyut arayüz
    mock_device_service.dart  ESP32'yi taklit eden sahte cihaz (2 saksı)
  providers/                Durum yönetimi (Provider)
  screens/                  Ekranlar (ana sayfa, saksılarım, geçmiş, ayarlar, bildirimler ...)
  widgets/                  Tekrar kullanılan parçalar (kart, nem halkası, grafikler, bitki çizimleri ...)
  l10n/                     Dil desteği: strings.dart (altyapı), en.dart (İngilizce çeviriler)
  utils/                    Tarih/sayı biçimlendirme, grafik hesapları
docs/design/                Claude Design ekran tasarımları (PNG, açık ve koyu)
test/                       Birim ve widget testleri
android/                    Android proje dosyaları
web/                        Tarayıcıda çalıştırmak için
```

Kullanılan paketler: `provider` (durum yönetimi), `shared_preferences` (yerel kayıt), `intl` (Türkçe biçim), `google_fonts` (yazı tipleri). Grafikler ve bitki çizimleri paket kullanmadan `CustomPainter` ile çizilir.

**Dil desteği (Türkçe / English):** Kodda metinler Türkçe yazılır ve `context.t('Metin')` ile çağrılır; Türkçe metin aynı zamanda çeviri anahtarıdır. İngilizce karşılığı `lib/l10n/en.dart` içindedir. Yeni bir metin eklerken:

1. Ekranda `context.t('Yeni metin')` (widget dışında `Strings.t(...)`) ile yaz. Değişken gerekiyorsa `{0}`, `{1}` kullan: `context.t('{0} için seçildi.', [ad])`.
2. `lib/l10n/en.dart` içine aynı Türkçe metni anahtar yaparak İngilizcesini ekle.
3. `flutter test` çalıştır. Çevirisi eksik bir metin varsa `test/l10n_test.dart` hangisi olduğunu söyler.

Dil Ayarlar'dan seçilir, telefonda saklanır ve uygulama yeniden açılınca korunur. Cihazdan gelen uyarılar ve bildirimler metin olarak değil değerleriyle saklanır; bu yüzden dil değişince eskileri de yeni dilde görünür.

**Tasarımı güncellemek için:** Renkler ve yazı tipleri yalnızca `lib/theme/app_theme.dart` içindedir. Ekran düzeni ilgili `lib/screens/` dosyasındadır. Bitki çizimleri `lib/widgets/plant_illustration.dart` içindedir.

## Gerçek cihaza geçiş

Mimari, haberleşme yöntemi seçilince yalnızca bir yeri değiştirecek şekilde kuruldu:

1. `lib/services/device_service.dart` içindeki `DeviceService` arayüzünü uygulayan yeni bir sınıf yazın (örn. `FirebaseDeviceService`).
2. `lib/main.dart` içindeki şu satırı yeni sınıfla değiştirin:

   ```dart
   final DeviceService device = MockDeviceService();
   ```

Ekranlar ve provider'lar değişmez. Güvenlik kuralları (kuru çalışma, azami süre, asgari bekleme) uygulamada değil **ESP32 firmware'inde** uygulanmalıdır.

## Sık karşılaşılan sorunlar

**`flutter` komutu bulunamıyor**
Flutter'ın `bin` klasörü Path'e eklenmemiş ya da terminal eski. Terminali kapatıp yenisini açın.

**`flutter devices` telefonu göstermiyor**
- Kablo yalnızca şarj ediyor olabilir, başka kablo deneyin.
- Telefondaki USB hata ayıklama iznini onaylayın.
- Bazı markalar (Samsung, Xiaomi vb.) Windows'ta kendi USB sürücüsünü ister.
- Bildirim çubuğunda USB modunu **Dosya aktarımı** yapın.

**`Multiple adb binaries found` uyarısı**
Bilgisayarda birden fazla `adb` kurulu. Genelde zararsızdır. Telefon algılanmıyorsa tek bir Android SDK kullanın ve diğerini Path'ten çıkarın.

**Android derlemesi `Could not close incremental caches` hatasıyla düşüyor**
Proje bir sürücüde (örn. `D:`), Flutter paket önbelleği başka sürücüde (`C:`) olduğunda Windows'ta görülen bilinen bir Kotlin sorunudur. `android/gradle.properties` içinde `kotlin.incremental=false` ayarı bunun için eklidir. Hata yine de çıkarsa projeyi `C:` sürücüsünde bir klasöre taşıyın.

**İlk derleme çok uzun sürüyor**
Gradle ve Android bileşenleri ilk seferde iner, normaldir. Takılırsa `flutter run -v` ile nerede beklediğini görebilirsiniz. Farklı bir ağ ya da VPN denemek de yardımcı olabilir.

**`flutter doctor`'da Visual Studio çarpısı**
Yok sayabilirsiniz, yalnızca Windows masaüstü uygulaması içindir.

**Paket hatası (`pub get` başarısız)**
İnternet bağlantısını kontrol edip `flutter pub get` komutunu tekrar çalıştırın. Sürüm çakışması olursa `flutter pub upgrade` deneyin.

## Ekip çalışma düzeni

- `main` dalı çalışan sürümü tutar.
- Yeni işler ayrı dallarda yapılır: `feature/app-...` (mobil uygulama), `feature/firmware-...` (ESP32).
- Dallar **Pull Request** ile `main`'e birleştirilir; küçük ve sık commit atılır.
- Commit'ten önce `flutter analyze` ve `flutter test` çalıştırılır.
- **Wi-Fi şifresi, API anahtarı, `google-services.json`, `secrets.h` gibi gizli bilgiler repoya konmaz**; `.gitignore`'a eklenir.

## Kaynaklar

- Flutter: <https://docs.flutter.dev>
- Dart: <https://dart.dev/guides>
- Flutter ilk uygulama alıştırması (İngilizce): <https://docs.flutter.dev/get-started/codelab>
- ESP32 / Espressif: <https://docs.espressif.com>
- PlatformIO: <https://docs.platformio.org>
- Firebase Flutter kurulumu: <https://firebase.google.com/docs/flutter/setup>

---

## Hızlı başlangıç: sırayla yapılacaklar

Yukarıdaki ayrıntıların özeti. Projeyi ilk kez açan biri bu adımları sırayla izlemelidir.

**Bilgisayarı hazırlama (yalnızca ilk sefer)**

1. [ ] **Git** kur: <https://git-scm.com/download/win>
2. [ ] **Flutter SDK**'yı indirip `C:\src\flutter` gibi bir klasöre aç: <https://docs.flutter.dev/install>
3. [ ] `C:\src\flutter\bin` klasörünü **Path** ortam değişkenine ekle, terminali kapatıp yeniden aç.
4. [ ] **Android Studio**'yu kur (Standard kurulum): <https://developer.android.com/studio>
5. [ ] Android lisanslarını kabul et:
   ```bash
   flutter doctor --android-licenses
   ```
6. [ ] Kurulumu kontrol et. *Flutter*, *Android toolchain* ve *Connected device* yeşil olmalı (Visual Studio çarpısı önemsiz):
   ```bash
   flutter doctor
   ```

**Projeyi alma ve çalıştırma**

7. [ ] Repoyu indir ve klasörüne gir:
   ```bash
   git clone https://github.com/Berkay3452/autonomous-plant-watering-system.git
   cd autonomous-plant-watering-system
   ```
8. [ ] Paketleri indir:
   ```bash
   flutter pub get
   ```
9. [ ] Telefonda **Geliştirici seçenekleri → USB hata ayıklama**'yı aç, telefonu veri kablosuyla bağla ve izni onayla.
10. [ ] Telefonun göründüğünü kontrol et:
    ```bash
    flutter devices
    ```
11. [ ] Uygulamayı başlat (ilk derleme birkaç dakika sürer):
    ```bash
    flutter run
    ```
    Telefon yoksa tarayıcıda: `flutter run -d chrome`

**Uygulamada ilk denemeler**

12. [ ] **Saksılarım** sekmesinde bir saksının kartına dokun, bir bitki kategorisi seç, *Devam et*'e bas, bir bitkiye dokunup *Saksı için seç*'e bas.
13. [ ] **Ana sayfa**'da **Şimdi Sula**'ya dokunup miktarı seç, sulamayı başlat. Nem halkası dolar, depo azalır.
14. [ ] Ana sayfada **Sonraki sulama** kutusuna dokun. Saati şimdiden 2 dakika sonrasına, günü bugüne ayarlayıp *Kaydet*'e bas. Süre dolunca cihaz kendisi sular.
15. [ ] **Geçmiş** sekmesinde Gün / Hafta / Ay grafiklerini incele.
16. [ ] **Ayarlar → Simülasyon**'dan depoyu düşürüp toprağı kurutarak ana sayfadaki **zil** simgesinden bildirimleri dene.

**Geliştirmeye başlamadan önce**

17. [ ] Yeni bir dal aç:
    ```bash
    git checkout -b feature/app-konu-adi
    ```
18. [ ] Değişiklik yaptıktan sonra kodu denetle:
    ```bash
    flutter analyze
    flutter test
    ```
19. [ ] Commit at, dalı gönder ve GitHub'da **Pull Request** aç:
    ```bash
    git add .
    git commit -m "Yapılan işin kısa açıklaması"
    git push -u origin feature/app-konu-adi
    ```
