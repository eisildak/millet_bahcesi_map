import 'package:flutter/material.dart';

/// POI kategorilerinin ikon ve renkleri. Haritadaki marker'lar ile POI kartı
/// aynı görsel dili kullansın diye tek yerde tutulur.
class PoiCategory {
  PoiCategory._();

  /// Genel (park) noktaları.
  static const Color generalColor = Color(0xFF3252a8);

  /// Etkinlik noktaları: etkinlik alanıyla aynı kırmızı; genel noktalardan ve
  /// mavi rota çizgisinden ayrışır.
  static const Color eventColor = Color(0xFFE53935);

  /// Etkinlik noktaları için önerilen kategoriler (event_config.dart'ta
  /// kullanılır). Listede olmayan bir kategori de yazılabilir; varsayılan
  /// ikonla gösterilir.
  static const List<String> eventCategories = [
    'Sahne',
    'Stant',
    'WC',
    'İlk Yardım',
    'Bilgi',
    'Giriş',
    'Yemek',
  ];

  static IconData icon(String category) {
    switch (category.toLowerCase()) {
      case 'wc':
        return Icons.wc;
      case 'kapı':
      case 'giriş':
        return Icons.login;
      case 'üniversite':
        return Icons.school;
      case 'sahne':
        return Icons.festival;
      case 'stant':
        return Icons.storefront;
      case 'ilk yardım':
        return Icons.medical_services;
      case 'bilgi':
        return Icons.info;
      case 'yemek':
        return Icons.restaurant;
      case 'hedef':
        return Icons.flag;
      default:
        return Icons.location_on;
    }
  }

  static Color color({required bool isEvent}) =>
      isEvent ? eventColor : generalColor;
}
