/// İngilizce çeviriler. Anahtar, kodda yazılan Türkçe metindir.
///
/// `{0}`, `{1}` yer tutucuları çeviride de aynen korunmalıdır.
/// Eksik çeviri `test/l10n_test.dart` ile yakalanır.
const Map<String, String> enStrings = {
  // ---------------------------------------------------------------------------
  // Gezinme ve ortak
  'Ana sayfa': 'Home',
  'Saksılarım': 'My pots',
  'Geçmiş': 'History',
  'Ayarlar': 'Settings',
  'Gör': 'View',
  'Geri': 'Back',
  'Vazgeç': 'Cancel',
  'Kaydet': 'Save',
  'Sil': 'Delete',
  'Düzenle': 'Edit',
  'Temizle': 'Clear',
  'Kapalı': 'Off',
  'Şimdi': 'Now',
  'Bugün': 'Today',
  'Dün': 'Yesterday',
  'sn': 's',
  '{0} sn': '{0} s',
  '{0} dk': '{0} min',
  '{0} sa': '{0} h',
  '{0} sa {1} dk': '{0} h {1} min',

  // Saksılar
  'Saksı': 'Pot',
  'Saksı 1': 'Pot 1',
  'Saksı 2': 'Pot 2',
  'Saksı seç': 'Choose pot',
  'Bitki seçilmedi': 'No plant selected',
  'Boş saksı': 'Empty pot',
  'Boş': 'Empty',

  // ---------------------------------------------------------------------------
  // Ana sayfa
  'Merhaba, {0}': 'Hello, {0}',
  'Bildirimler': 'Notifications',
  'Cihaza ulaşılamıyor': 'Device unreachable',
  'Cihaza bağlanılıyor': 'Connecting to device',
  'Saksına bir bitki seç': 'Pick a plant for your pot',
  'Bitkinin suya ihtiyacı var': 'Your plant needs water',
  'Bitkin biraz kuru': 'Your plant is a bit dry',
  'Bitkin fazla ıslak': 'Your plant is too wet',
  'Bitkin iyi görünüyor': 'Your plant looks good',
  'Toprak nemi': 'Soil moisture',
  'Sıcaklık': 'Temperature',
  'Su deposu': 'Water tank',
  'Sonraki sulama': 'Next watering',
  'Şimdi Sula': 'Water Now',
  'Cihazdan veri gelmiyor. Programlı sulama cihazda sürer.':
      'No data from the device. Scheduled watering keeps running on the device.',

  // Saksılarım
  '{0} saksı bağlı': '{0} pots connected',
  'Cihaz çevrimdışı': 'Device offline',
  'Nem': 'Moisture',
  'Sıradaki': 'Next',
  'Depo kritik seviyede, pompalar kilitli.': 'Tank is critically low, pumps are locked.',
  'Depo azalıyor, yakında doldurman gerekebilir.': 'Tank is running low, you may need to refill soon.',

  // Bitki türü ve listesi
  'Bitki türü': 'Plant type',
  '{0} için bitki kategorisini seç. Sulama önerileri buna göre ayarlanır.':
      'Choose a plant category for {0}. Watering suggestions are adjusted to it.',
  'Devam et': 'Continue',
  'Saksıdaki bitkiyi seç. Nem eşikleri ve sıcaklık önerileri ona göre ayarlanır.':
      'Choose the plant in the pot. Moisture thresholds and temperature suggestions follow it.',
  'Özel': 'Custom',
  'Nem {0} · {1}': 'Moisture {0} · {1}',
  'Kendi bitkini ekle': 'Add your own plant',
  '{0} için {1} seçildi.': '{1} selected for {0}.',
  '{0} silinsin mi?': 'Delete {0}?',
  'Bu bitki bir saksıya atanmışsa saksı boşaltılır.': 'If this plant is in a pot, the pot will be emptied.',
  '{0} için seçili': 'Selected for {0}',
  '{0} için seç': 'Select for {0}',
  'min {0} · ideal {1}': 'min {0} · ideal {1}',
  'Su ihtiyacı': 'Water need',

  // Bitki formu
  'Yeni bitki': 'New plant',
  'Bitkiyi düzenle': 'Edit plant',
  'Bitki adı': 'Plant name',
  'Bir ad gir': 'Enter a name',
  'Kategori': 'Category',
  'Minimum nem': 'Minimum moisture',
  'Bu değerin altında "bitki susadı" bildirimi gider ve otomatik modda sulama başlar.':
      'Below this value you get a "plant is thirsty" notification and automatic mode starts watering.',
  'İdeal nem aralığı': 'Ideal moisture range',
  'Uygun sıcaklık': 'Suitable temperature',
  'Bakım notu (isteğe bağlı)': 'Care note (optional)',
  'Minimum nem, ideal aralığın alt sınırından büyük olamaz.':
      'Minimum moisture cannot be higher than the lower limit of the ideal range.',

  // Sulama programı
  'Sulama programı': 'Watering schedule',
  'Otomatik sulama': 'Automatic watering',
  '{0} program saatinde sulanır': '{0} is watered at the scheduled time',
  'Program kapalı, otomatik sulama yapılmaz': 'Schedule is off, no automatic watering',
  'Sulama saati': 'Watering time',
  'Program kapalı.': 'Schedule is off.',
  'Sulama günü seçilmedi.': 'No watering day selected.',
  'Sıradaki sulama: {0} ({1})': 'Next watering: {0} ({1})',
  'Su miktarı': 'Water amount',
  '≈ {0} ml · pompa {1}': '≈ {0} ml · pump {1}',
  ' (azami süreyle sınırlı)': ' (limited by the maximum time)',
  'En az bir gün seç.': 'Select at least one day.',
  'Sulama programı kaydedildi.': 'Watering schedule saved.',

  // Geçmiş
  'Sulama': 'Watering',
  '{0} sulama': '{0} watering',
  'Gün': 'Day',
  'Hafta': 'Week',
  'Ay': 'Month',

  // Bildirimler
  'Tümünü okundu say': 'Mark all as read',
  'Tüm bildirimleri temizle': 'Clear all notifications',
  'Tüm bildirimler silinsin mi?': 'Delete all notifications?',
  'Bildirim yok': 'No notifications',
  'Bitkin susadığında, depo azaldığında ya da cihaz çevrimdışı olduğunda burada görünür.':
      'They appear here when your plant is thirsty, the tank runs low or the device goes offline.',
  '{0} susadı': '{0} is thirsty',
  'Su deposu azalıyor': 'Water tank is running low',
  'Sulama yapılamadı': 'Watering failed',
  'Sulama tamamlandı': 'Watering complete',
  "Toprak nemi %{0}'e düştü. Sulama zamanı.": 'Soil moisture dropped to {0}%. Time to water.',
  'Depo seviyesi %{0}. Pompalar kilitlendi, depoyu doldur.': 'Tank level is {0}%. Pumps are locked, refill the tank.',
  'Depo seviyesi %{0}. Yakında doldurman gerekebilir.': 'Tank level is {0}%. You may need to refill soon.',
  "Cihazdan {0} sn'dir veri gelmiyor. Programlı sulama cihazda sürer.":
      'No data from the device for {0} s. Scheduled watering keeps running on the device.',
  '{0} · %{1} su verildi.': '{0} · {1}% water given.',
  '{0}: {1}': '{0}: {1}',
  'Bir güvenlik kuralı sulamayı engelledi.': 'A safety rule blocked the watering.',

  // Şimdi sula penceresi
  'Şimdi sula': 'Water now',
  'Sulamayı başlat': 'Start watering',
  'Gönderiliyor…': 'Sending…',
  'Cihaz çevrimdışı. Komut gönderilemez.': 'Device is offline. The command cannot be sent.',
  'Depo kritik seviyede, pompa kilitli. Önce depoyu doldur.': 'Tank is critically low and the pump is locked. Refill the tank first.',
  'Pompa şu anda çalışıyor.': 'The pump is running right now.',
  '≈ {0} ml su · pompa {1} çalışır': '≈ {0} ml of water · pump runs for {1}',
  'Azami pompa süresi nedeniyle doz sınırlandı.': 'Dose was limited by the maximum pump time.',
  '%100 = tam doz ({0} ml). Ayarlar ekranından değiştirilebilir.': '100% = full dose ({0} ml). You can change it in Settings.',
  'Sulama başladı: ≈ {0} ml, {1}.': 'Watering started: ≈ {0} ml, {1}.',
  'Sulama başlatılamadı. {0}': 'Could not start watering. {0}',

  // Cihaz mesajları
  'Cihaza ulaşılamıyor.': 'Device is unreachable.',
  'Cihaz çevrimdışı, komut gönderilemedi.': 'Device is offline, the command could not be sent.',
  'Cihaza bağlanılamadı: {0}': 'Could not connect to the device: {0}',
  'Bu saksı cihazda tanımlı değil.': 'This pot is not defined on the device.',
  'Pompa zaten çalışıyor.': 'The pump is already running.',
  'Depo kritik seviyede, pompa kilitli (kuru çalışma koruması).':
      'Tank is critically low, pump is locked (dry-run protection).',
  'Son sulamanın üzerinden yeterli süre geçmedi. {0} sonra tekrar deneyin (aşırı sulama koruması).':
      'Not enough time has passed since the last watering. Try again in {0} (overwatering protection).',
  'Azami pompa süresi ({0} sn) nedeniyle doz kısaltıldı.': 'Dose was shortened because of the maximum pump time ({0} s).',
  'Depo kritik seviyeye düştü, pompa erken durduruldu.': 'Tank dropped to a critical level, the pump stopped early.',

  // Zaman ifadeleri
  'az önce': 'just now',
  '{0} dk önce': '{0} min ago',
  '{0} sa önce': '{0} h ago',
  'dün {0}': 'yesterday {0}',
  'Bugün {0}': 'Today {0}',
  'Yarın {0}': 'Tomorrow {0}',
  'şimdi': 'now',
  '{0} sn sonra': 'in {0} s',
  '{0} dk sonra': 'in {0} min',
  '{0} sa {1} dk sonra': 'in {0} h {1} min',
  '{0} sa sonra': 'in {0} h',
  '{0} gün sonra': 'in {0} days',

  // ---------------------------------------------------------------------------
  // Ayarlar
  'Adın': 'Your name',
  'Örn. Berkay': 'e.g. Berkay',
  'Görünüm': 'Appearance',
  'Sistem': 'System',
  'Açık': 'Light',
  'Koyu': 'Dark',
  'Dil': 'Language',
  'Sıcaklık birimi': 'Temperature unit',
  'Celsius (°C)': 'Celsius (°C)',
  'Fahrenheit (°F)': 'Fahrenheit (°F)',
  'Sulama ve güvenlik': 'Watering and safety',
  'Nem eşiğine göre otomatik mod': 'Automatic mode by moisture threshold',
  'Nem bitkinin minimum değerinin altına inince cihaz kısa dozlarla sular.':
      'When moisture falls below the plant\'s minimum, the device waters in short doses.',
  '{0} tam doz (%100)': '{0} full dose (100%)',
  '{0} tam doz': '{0} full dose',
  'Saksının bir seferde alabileceği en fazla su': 'The most water the pot can take at once',
  'Uygulamadaki %50, bu miktarın yarısı demektir.': '50% in the app means half of this amount.',
  'Azami pompa süresi': 'Maximum pump time',
  'Tek sulamada pompanın en fazla çalışma süresi': 'The longest the pump runs in a single watering',
  'İki sulama arası en az': 'Minimum time between waterings',
  'Aşırı sulama koruması': 'Overwatering protection',
  'Dokümandaki öneri 10 dk. Demo için 1 dk ayarlı.': 'The document recommends 10 min. Set to 1 min for the demo.',
  'Kuru çalışma eşiği': 'Dry-run threshold',
  'Depo bu seviyedeyken pompalar kilitlenir': 'Pumps are locked when the tank is at this level',
  'Depo uyarı eşiği': 'Tank alert threshold',
  '"Bitki susadı" için bekleme': 'Wait before "plant is thirsty"',
  'Nem bu süre boyunca eşiğin altında kalırsa': 'If moisture stays below the threshold for this long',
  'Dokümandaki öneri 5 dk (300 sn).': 'The document recommends 5 min (300 s).',
  'Çevrimdışı sayılma süresi': 'Time before device counts as offline',
  'Aynı uyarının tekrar aralığı': 'Repeat interval for the same alert',
  'Tekrar aralığı': 'Repeat interval',
  'Dokümandaki öneri 6 sa. Test ederken düşürebilirsin.':
      'The document recommends 6 h. You can lower it while testing.',
  'Profil ve cihaz': 'Profile and device',
  'Ana sayfadaki karşılamada görünür': 'Shown in the greeting on the home screen',
  'Sahte cihaz (mock)': 'Mock device',
  'Haberleşme yöntemi henüz seçilmedi (Firebase / MQTT / yerel ağ).':
      'Communication method not chosen yet (Firebase / MQTT / local network).',
  'Pompa debisi': 'Pump flow rate',
  'Depo hacmi': 'Tank capacity',
  'Simülasyon (sahte cihaz)': 'Simulation (mock device)',
  'Bu bölüm yalnızca sahte cihazla çalışırken görünür. Gerçek ESP32 bağlanınca kaybolur.':
      'This section only appears with the mock device. It disappears once a real ESP32 is connected.',
  'Cihazı çevrimdışı yap': 'Take device offline',
  'Veri gelmez; programlı sulama cihazda sürer.': 'No data arrives; scheduled watering continues on the device.',
  'Depoyu doldur': 'Refill tank',
  'Depo %100 dolduruldu.': 'Tank filled to 100%.',
  "Depoyu %12'ye düşür": 'Drop tank to 12%',
  '"Su deposu azalıyor" uyarısını dener': 'Tries the "Water tank is running low" alert',
  "Depo %12'ye düşürüldü.": 'Tank dropped to 12%.',
  "Depoyu %3'e düşür": 'Drop tank to 3%',
  'Kuru çalışma kilidini dener': 'Tries the dry-run lock',
  "Depo %3'e düşürüldü, pompa kilitlenecek.": 'Tank dropped to 3%, the pump will lock.',
  '{0} toprağını kurut': 'Dry out {0} soil',
  "Nemi %15'e indirir, \"bitki susadı\" uyarısını dener": 'Lowers moisture to 15% and tries the "plant is thirsty" alert',
  "{0} nemi %15'e indirildi.": '{0} moisture lowered to 15%.',
  'Hızlı kuruma': 'Fast drying',
  'Toprak 10 kat hızlı kurur': 'Soil dries 10 times faster',
  'Uyarı tekrar sürelerini sıfırla': 'Reset alert repeat timers',
  'Aynı uyarıyı hemen tekrar görebilmek için': 'To see the same alert again right away',
  'Uyarı tekrar süreleri sıfırlandı.': 'Alert repeat timers reset.',

  // ---------------------------------------------------------------------------
  // Uygulama adı
  'Bitki Sulama': 'Plant Watering',

  // ---------------------------------------------------------------------------
  // Bitki kategorileri
  'Tropikal': 'Tropical',
  'Sukulent': 'Succulent',
  'Kaktüs': 'Cactus',
  'Çiçekli': 'Flowering',
  'Aromatik': 'Herbs',
  'Sebze & Meyve': 'Vegetables & Fruit',
  'Tropikal bitki': 'Tropical plant',
  'Sukulent bitki': 'Succulent plant',
  'Çiçekli bitki': 'Flowering plant',
  'Aromatik bitki': 'Herb',
  'Sebze & meyve': 'Vegetable & fruit',
  'Az su': 'Low water',
  'Orta su': 'Medium water',
  'Çok az su': 'Very low water',
  'Bol su': 'High water',

  // Su ihtiyacı
  'Düşük': 'Low',
  'Orta': 'Medium',
  'Orta / Yüksek': 'Medium / High',
  'Yüksek': 'High',

  // Değerlerin kaynağı
  'Proje dokümanındaki değerler': 'Values from the project document',
  'Nem değerleri dokümandan, sıcaklık aralığı tahmini': 'Moisture values from the document, temperature range estimated',
  'Genel bakım bilgisi, ekipçe doğrulanmalı': 'General care information, to be verified by the team',
  'Kullanıcı tarafından eklendi': 'Added by user',

  // Saksı durumları
  'Veri yok': 'No data',
  'Veri bekleniyor': 'Waiting for data',
  'Sulama gerekli': 'Needs water',
  'Biraz kuru': 'A bit dry',
  'Yakında sulanmalı': 'Water soon',
  'İyi durumda': 'In good shape',
  'Sulama gerekmiyor': 'No watering needed',
  'Fazla ıslak': 'Too wet',

  // Sulama kaynağı
  'Manuel': 'Manual',
  'Programlı': 'Scheduled',
  'Otomatik': 'Automatic',

  // ---------------------------------------------------------------------------
  // Bitki adları
  'Difenbahya': 'Dieffenbachia',
  'Barış Çiçeği': 'Peace lily',
  'Salon sarmaşığı': 'Pothos',
  'Aloe vera': 'Aloe vera',
  'Para ağacı': 'Jade plant',
  'Paşa kılıcı': 'Snake plant',
  'Dikenli armut': 'Prickly pear',
  'Sardunya': 'Geranium',
  'Afrika menekşesi': 'African violet',
  'Saksı gülü': 'Potted rose',
  'Fesleğen': 'Basil',
  'Nane': 'Mint',
  'Biberiye': 'Rosemary',
  'Domates': 'Tomato',
  'Biber': 'Pepper',
  'Marul': 'Lettuce',
  'Çilek': 'Strawberry',

  // Bitki bakım notları
  'Üst toprak hafifçe kuruyunca sulanır. Soğuk cereyandan ve uzun süre ıslak toprakta kalmaktan hoşlanmaz.':
      'Water when the top soil dries slightly. Dislikes cold drafts and sitting in wet soil for long.',
  'Spathiphyllum. Susuz kalınca yaprakları belirgin şekilde sarkar; nemli toprağı sever.':
      'Spathiphyllum. Its leaves droop noticeably when it is thirsty; likes moist soil.',
  'Pothos. Bakımı kolaydır; üst toprak kuruyunca sulanır.': 'Easy to care for; water when the top soil is dry.',
  'Yapraklarında su depolar. Toprak iyice kuruduktan sonra sulanmalıdır; fazla su kök çürümesine yol açar.':
      'Stores water in its leaves. Water only after the soil is fully dry; too much water causes root rot.',
  'Crassula ovata. Sulamalar arasında toprağın kurumasını ister.': 'Crassula ovata. Wants the soil to dry out between waterings.',
  'Sansevieria. Az su ister, kuraklığa çok dayanıklıdır.': 'Sansevieria. Needs little water and tolerates drought very well.',
  'Çok az su ister. Kışın sulama büyük ölçüde azaltılır.': 'Needs very little water. Watering is greatly reduced in winter.',
  'Opuntia. Güneşi ve kuru toprağı sever; fazla sudan çabuk çürür.': 'Opuntia. Loves sun and dry soil; rots quickly with too much water.',
  'Bol güneş ister. Toprağı hafif kuruyunca sulanır.': 'Wants lots of sun. Water when the soil dries slightly.',
  'Yapraklarının ıslanmasını sevmez; toprağı hafif nemli kalmalı.': 'Dislikes wet leaves; keep the soil slightly moist.',
  'Düzenli ve bol sulama ister, ama kökleri su içinde kalmamalı.': 'Needs regular, generous watering, but the roots should not sit in water.',
  'Toprağı nemli ama su birikmemiş olmalı. Soğuğa duyarlıdır.': 'Soil should be moist but not waterlogged. Sensitive to cold.',
  'Bol su ister ve hızlı yayılır. Toprağı sürekli hafif nemli tutulmalıdır.':
      'Needs plenty of water and spreads fast. Keep the soil slightly moist at all times.',
  'Kuraklığa dayanıklıdır, fazla sudan hoşlanmaz.': 'Drought tolerant; dislikes too much water.',
  'Düzenli ve dengeli sulama ister. Toprağın tamamen kurumasına ve uzun süre çok ıslak kalmasına dikkat edilmelidir.':
      'Needs regular, balanced watering. Avoid letting the soil dry out completely or stay very wet for long.',
  'Sıcağı sever. Üst toprak hafifçe kuruduğunda sulanır.': 'Loves warmth. Water when the top soil dries slightly.',
  'Serin ortamı ve sürekli nemli toprağı sever. Sıcakta çabuk strese girer.':
      'Likes cool surroundings and constantly moist soil. Stresses quickly in the heat.',
  'Toprağı eşit nemli ister; meyveler toprağa değmemeli.': 'Wants evenly moist soil; the fruit should not touch the soil.',
};
