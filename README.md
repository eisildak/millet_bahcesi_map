# Kayseri Millet Bahçesi Harita Uygulaması

Kayseri Millet Bahçesi için interaktif harita ve navigasyon uygulaması. Flutter ile geliştirilmiş, kullanıcı dostu arayüzü ile ziyaretçilere ilgi noktalarını keşfetme ve yol tarifi alma imkanı sunar.

## 🌟 Özellikler

- 🗺️ **Interaktif Harita**: Google Maps entegrasyonu ile detaylı harita görünümü
- 📍 **İlgi Noktaları**: Bahçe içerisindeki önemli noktaların işaretlenmesi
- 🔍 **Akıllı Arama**: İlgi noktalarını isim, kategori ve açıklama bazında arama
- 🧭 **Navigasyon**: Yürüyerek yol tarifi ve adım adım rehberlik
- 📱 **Kullanıcı Dostu**: Modern ve sezgisel arayüz tasarımı
- 🌐 **Konum Servisleri**: GPS ile mevcut konum tespiti ve mesafe hesaplama

## 📋 İçerik

### İlgi Noktaları
- **NNY Stant-1**: Ana giriş yakınında yer alan bilgi standı
- **Çocuk Oyun Alanı**: Modern oyun ekipmanları ile donatılmış güvenli alan
- **Yürüyüş Parkuru**: Sağlık yürüyüşü için hazırlanmış parkur
- **Bahçe Kafesi**: Doğal manzara eşliğinde dinlenme alanı
- **Tesis Alanları**: WC, piknik alanları ve diğer kolaylıklar
- **Süs Havuzu**: Fıskiyeli dekoratif su öğesi

### Kategoriler
- 🔵 **Bilgi Standı**: Danışma ve bilgilendirme noktaları
- 🟠 **Eğlence**: Çocuk oyun alanları, piknik alanları
- 🟢 **Spor**: Yürüyüş parkurları, spor alanları
- 🟣 **Restoran**: Kafeler ve yeme-içme alanları
- 🔵 **Tesis**: WC, lavabo ve diğer kolaylıklar
- 🟡 **Doğa**: Süs havuzları, peyzaj alanları

## 🚀 Kurulum

### Gereksinimler
- Flutter 3.0.0 veya üzeri
- Dart 3.0.0 veya üzeri
- Google Maps API Key

### Google Cloud Ayarları
Google Cloud Console'dan aşağıdaki API'ları aktif edin:
1. **Maps JavaScript API**
2. **Directions API**
3. **Places API**
4. **Geocoding API**

### Proje Kurulumu

```bash
# Projeyi klonlayın
git clone https://github.com/eisildak/millet_bahcesi_map.git
cd millet_bahcesi_map

# Bağımlılıkları yükleyin
flutter pub get

# JSON serializasyon dosyalarını oluşturun
flutter pub get
```

### API Key Ayarları

⚠️ **Önemli**: Google Maps API Key'inizi güvenli bir şekilde saklayın ve GitHub'a yüklemeyin!

#### 1. API Key Dosyası Oluşturma
`lib/config/api_keys.dart` dosyasını oluşturun:
```dart
class ApiKeys {
  static const String googleMapsApiKey = 'AIzaSyAMw4PWCXo9PDv0VXCY58l8S3Vzub8h5wo';
}
```

#### 2. Android
`android/app/src/main/AndroidManifest.xml` dosyasında:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

#### 3. iOS
`ios/Runner/AppDelegate.swift` dosyasında:
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### Kod İçinde
`lib/services/map_service.dart` dosyasında:
```dart
static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
```

## 🎯 Kullanım

### Ana Özellikler

1. **Harita Görünümü**: Uygulama açıldığında Kayseri Millet Bahçesi merkez alınarak harita yüklenir
2. **Arama**: Üst menüdeki arama ikonu ile ilgi noktalarını arayabilirsiniz
3. **Navigasyon**: Bir noktaya tıkladığınızda "Yürüyerek Git" butonu ile navigasyon başlatılır
4. **Konum**: GPS ikonuna basarak mevcut konumunuza odaklanabilirsiniz
5. **Kategori Filtreleme**: Arama ekranında kategori çipleri ile filtreleme yapabilirsiniz

### Önemli Notlar
- Navigasyon için konum izni gereklidir
- İnternet bağlantısı harita yükleme için gereklidir
- API key sınırlamaları nedeniyle yoğun kullanımda rate limit uyarısı alabilirsiniz

## 🏗️ Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── models/                   # Veri modelleri
│   └── point_of_interest.dart
├── services/                 # İş mantığı servisleri
│   ├── location_service.dart
│   └── map_service.dart
├── screens/                  # Ekran bileşenleri
│   └── map_screen.dart
└── widgets/                  # UI bileşenleri
    ├── search_widget.dart
    ├── poi_bottom_sheet.dart
    └── navigation_controls.dart
```

## 🔧 Geliştirme

### Yeni İlgi Noktası Ekleme
`lib/models/point_of_interest.dart` dosyasındaki `POIData.kayseriMilletBahcesi` listesine yeni nokta ekleyin:

```dart
const PointOfInterest(
  id: 'yeni-nokta-id',
  name: 'Yeni Nokta Adı',
  description: 'Nokta açıklaması',
  latitude: 38.7540,
  longitude: 35.4580,
  category: 'Kategori',
),
```

### Kategori Ekleme
`SearchWidget` ve `POIBottomSheet` widget'larında yeni kategori için renk ve ikon tanımlamaları yapın.

## 📱 Platform Desteği

- ✅ Android 5.0+ (API 21+)
- ✅ iOS 11.0+
- ❌ Web (Google Maps plugin limitasyonları)
- ❌ Desktop (Konum servisleri eksikliği)

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'e push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## TODO
1- NNY logosu düzenlenecek.
2- web app applyfy'a yğklenecek
3- mobile appler için QR oluşturulacak. 

## 📄 Lisans

Bu proje MIT lisansı ile lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasını inceleyiniz.

## 📞 İletişim

- **Proje**: [millet_bahcesi_map](https://github.com/eisildak/millet_bahcesi_map)
- **Geliştirici**: eisildak

## 📝 Changelog

### v1.0.0 (Mevcut)
- 🎉 İlk sürüm yayınlandı
- 🗺️ Google Maps entegrasyonu
- 📍 8 adet ilgi noktası eklendi
- 🔍 Arama ve filtreleme özelliği
- 🧭 Yürüyerek navigasyon desteği
- 📱 Modern UI tasarımı


## 📝 TODO
1- ✅ nny logo büyüyecek (Tamamlandı - 120x120px)
2- ✅ hazırlayan ve danışman ismi eklenecek (Tamamlandı)
   - Hazırlayan: Erol IŞILDAK
   - Danışman: Öğr.Gör. Gülsüm KEMERLİ
3- ✅ apple - android logo değişecek (Tamamlandı)
4- Harita sorunu çözülecek
5- ✅ Android APK için QR kod eklendi
6- Web hosting'e yüklenecek
---

⭐ **Kayseri Millet Bahçesi'nde keyifli geziler dileriz!** 🌳