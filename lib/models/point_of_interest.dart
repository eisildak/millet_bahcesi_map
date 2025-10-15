import 'package:json_annotation/json_annotation.dart';

part 'point_of_interest.g.dart';

@JsonSerializable()
class PointOfInterest {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final String? imageUrl;
  final bool isActive;

  const PointOfInterest({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.imageUrl,
    this.isActive = true,
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) =>
      _$PointOfInterestFromJson(json);

  Map<String, dynamic> toJson() => _$PointOfInterestToJson(this);

  @override
  String toString() => 'POI: $name ($category)';
}

// Kayseri Millet Bahçesi WC Tesisleri
class POIData {
  static List<PointOfInterest> kayseriMilletBahcesi = [
    // WC Tesisleri - Güncel koordinatlar
    const PointOfInterest(
      id: 'wc-1',
      name: 'WC 1',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.709938,
      longitude: 35.501325,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-2',
      name: 'WC 2',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.707195,
      longitude: 35.504590,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-4',
      name: 'WC 4',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.706149,
      longitude: 35.502753,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-5',
      name: 'WC 5',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.705718,
      longitude: 35.505145,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-6',
      name: 'WC 6',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.703742,
      longitude: 35.512548,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-7',
      name: 'WC 7',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.699986,
      longitude: 35.518959,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-8',
      name: 'WC 8',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.699440,
      longitude: 35.514936,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-9',
      name: 'WC 9',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.697539,
      longitude: 35.515639,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-10',
      name: 'WC 10',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.698896,
      longitude: 35.511648,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-11',
      name: 'WC 11',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.705661,
      longitude: 35.505108,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-12',
      name: 'WC 12',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.706117,
      longitude: 35.502769,
      category: 'WC',
    ),
    const PointOfInterest(
      id: 'wc-13',
      name: 'WC 13',
      description: 'Temiz ve modern tuvalet tesisi',
      latitude: 38.707254,
      longitude: 35.504575,
      category: 'WC',
    ),
    
    // Giriş Kapıları
    const PointOfInterest(
      id: 'kosk-kisla-kapisi',
      name: 'Köşk Kışla Kapısı',
      description: 'Köşk Kışla bölgesinden ana giriş',
      latitude: 38.704674,
      longitude: 35.512708,
      category: 'Kapı',
    ),
    const PointOfInterest(
      id: 'universite-kapisi',
      name: 'Üniversite Kapısı',
      description: 'Üniversite tarafından ana giriş kapısı',
      latitude: 38.700358,
      longitude: 35.520671,
      category: 'Kapı',
    ),
    const PointOfInterest(
      id: 'cay-baglari-kapisi',
      name: 'Çay Bağları Kapısı',
      description: 'Çay bağları bölgesinden giriş kapısı',
      latitude: 38.696882,
      longitude: 35.512029,
      category: 'Kapı',
    ),
    const PointOfInterest(
      id: 'hava-ikmal-kapisi',
      name: 'Hava İkmal Kapısı',
      description: 'Hava İkmal Merkezi yakınından giriş',
      latitude: 38.707871,
      longitude: 35.496607,
      category: 'Kapı',
    ),
    const PointOfInterest(
      id: 'talas-bulvari-kapisi',
      name: 'Talas Bulvarı Kapısı',
      description: 'Talas Bulvarı üzerinden ana giriş',
      latitude: 38.708910,
      longitude: 35.504365,
      category: 'Kapı',
    ),
    
    // Üniversite Standı
    const PointOfInterest(
      id: 'nny-universite-standi',
      name: 'Nuh Naci Yazgan Üniversitesi Standı',
      description: 'Nuh Naci Yazgan Üniversitesi tanıtım standı ve bilgi merkezi',
      latitude: 38.701216,
      longitude: 35.513943,
      category: 'Üniversite',
    ),
  ];
}