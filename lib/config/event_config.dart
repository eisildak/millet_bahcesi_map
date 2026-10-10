import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/point_of_interest.dart';

/// Etkinliğe özel ayarlar.
///
/// Proje farklı açık alanlarda farklı etkinliklere hızla uyarlanabilsin diye
/// etkinliğe bağlı bilgiler (ad, alan sınırı) tek yerde tutulur. Yeni bir
/// etkinlik için [currentEvent]'i değiştirmek yeterlidir.
class EventConfig {
  const EventConfig({
    required this.name,
    required this.boundary,
    this.pois = const <PointOfInterest>[],
    this.initialZoom = 17.0,
  });

  final String name;

  /// Etkinlik alanının sınırı: sıralı köşe noktaları (poligon otomatik
  /// kapatılır). Boşsa haritada sınır çizilmez.
  final List<LatLng> boundary;

  /// Etkinliğe özel noktalar (sahne, stantlar, WC'ler...). Parkın genel
  /// noktalarına (POIData) ek olarak gösterilir, kırmızı marker ile ayrışır.
  /// Kategori için bkz. PoiCategory.eventCategories.
  final List<PointOfInterest> pois;

  /// Harita açılışında / "etkinlik alanına git" butonunda kullanılan zoom.
  final double initialZoom;

  bool get hasBoundary => boundary.length >= 3;

  /// Sınırın kapsadığı dikdörtgenin merkezi (sınır yoksa [fallbackCenter]).
  LatLng get center {
    if (!hasBoundary) return fallbackCenter;
    double minLat = boundary.first.latitude, maxLat = minLat;
    double minLng = boundary.first.longitude, maxLng = minLng;
    for (final p in boundary) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  /// Sınır tanımlı değilse kullanılacak merkez (Millet Bahçesi geneli).
  static const LatLng fallbackCenter = LatLng(38.704200, 35.509500);

  /// Nokta etkinlik alanının içinde mi? (ray casting)
  bool contains(LatLng p) {
    if (!hasBoundary) return false;
    bool inside = false;
    for (int i = 0, j = boundary.length - 1; i < boundary.length; j = i++) {
      final a = boundary[i];
      final b = boundary[j];
      final crosses = (a.latitude > p.latitude) != (b.latitude > p.latitude);
      if (crosses &&
          p.longitude <
              (b.longitude - a.longitude) *
                      (p.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// Aktif etkinlik: Kayseri Millet Bahçesi içindeki etkinlik alanı (~7 ha).
const EventConfig currentEvent = EventConfig(
  name: 'Kayseri Millet Bahçesi Etkinliği',
  initialZoom: 17.0,
  // Etkinlik noktaları. Koordinat toplamak için: uygulamada haritaya dokunun,
  // açılan "Seçilen nokta" kartındaki "Koordinatı kopyala" ile alın.
  // Örnek:
  //   PointOfInterest(
  //     id: 'event-sahne',            // benzersiz, 'event-' ile başlasın
  //     name: 'Ana Sahne',
  //     description: 'Konserler ve açılış töreni',
  //     latitude: 38.69840,
  //     longitude: 35.51350,
  //     category: 'Sahne',            // Sahne, Stant, WC, İlk Yardım, Bilgi, Giriş, Yemek
  //   ),
  pois: <PointOfInterest>[
    // TODO: Sahne, stant ve WC koordinatları eklenecek.
  ],
  boundary: <LatLng>[
    LatLng(38.69713845378929, 35.51248595679107),
    LatLng(38.69720441200745, 35.51358461071829),
    LatLng(38.6972548506038, 35.514101624331104),
    LatLng(38.69732856848833, 35.514469499401756),
    LatLng(38.69739452703199, 35.51491194303125),
    LatLng(38.697464364752456, 35.515200276964265),
    LatLng(38.69744496539249, 35.51531958755723),
    LatLng(38.69768939694344, 35.51542398432608),
    LatLng(38.697852350846624, 35.51545878324904),
    LatLng(38.69812781969582, 35.515483639622566),
    LatLng(38.69841104712466, 35.515483639622566),
    LatLng(38.698562359948916, 35.51539415667784),
    LatLng(38.6989619794584, 35.515110794019535),
    LatLng(38.699214165378315, 35.514867201558886),
    LatLng(38.69928012154913, 35.51472303459238),
    LatLng(38.6994197932395, 35.51442972938466),
    LatLng(38.69945471111945, 35.51418613692401),
    LatLng(38.69953618610642, 35.51384311896922),
    LatLng(38.699547825382695, 35.51365918180505),
    LatLng(38.69954394562416, 35.51332113512497),
    LatLng(38.6995051480271, 35.5130576575655),
    LatLng(38.69937711580747, 35.51270469706129),
    LatLng(38.699225804707, 35.512326880183544),
    LatLng(38.69905897414822, 35.512142943019384),
    LatLng(38.69886886443241, 35.51193414948169),
    LatLng(38.69871367245303, 35.51184963781166),
    LatLng(38.69855072051227, 35.51180489633929),
    LatLng(38.69830241207909, 35.5117352984934),
    LatLng(38.698147218870574, 35.51169055702103),
    LatLng(38.69797650595223, 35.511720384669275),
    LatLng(38.69781355233191, 35.511750212317516),
    LatLng(38.69764671847884, 35.511949063305806),
    LatLng(38.69744884526492, 35.512142943019384),
    LatLng(38.697297530084896, 35.51235670783179),
    LatLng(38.69719665312036, 35.512495903523586),
  ],
);
