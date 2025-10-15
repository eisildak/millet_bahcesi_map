import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/point_of_interest.dart';
import '../services/map_service.dart';
import '../services/location_service.dart';

class POIBottomSheet extends StatelessWidget {
  final PointOfInterest poi;

  const POIBottomSheet({
    super.key,
    required this.poi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Çekme çubuğu
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // POI başlığı ve kategori
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getCategoryColor(poi.category),
                radius: 24,
                child: Icon(
                  _getCategoryIcon(poi.category),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      poi.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  final mapService = Provider.of<MapService>(context, listen: false);
                  mapService.stopNavigation();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // POI açıklaması
          Text(
            poi.description,
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 20),

          // Aksiyon butonları
          Row(
            children: [
              // Navigasyonu başlat butonu
              Expanded(
                child: Consumer2<MapService, LocationService>(
                  builder: (context, mapService, locationService, child) {
                    return ElevatedButton.icon(
                      onPressed: () => _startNavigation(context, mapService, locationService),
                      icon: Icon(locationService.currentPosition != null 
                          ? Icons.directions_walk 
                          : Icons.location_searching),
                      label: Text(locationService.currentPosition != null 
                          ? 'Yürüyerek Git' 
                          : 'Konum Al & Git'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Paylaş butonu
              ElevatedButton.icon(
                onPressed: () => _sharePOI(context),
                icon: const Icon(Icons.share),
                label: const Text('Paylaş'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Konum bilgisi
          Consumer<LocationService>(
            builder: (context, locationService, child) {
              if (locationService.currentPosition != null) {
                final distance = locationService.calculateDistance(
                  locationService.currentPosition!.latitude,
                  locationService.currentPosition!.longitude,
                  poi.latitude,
                  poi.longitude,
                );

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Konumunuzdan ${distance.toInt()} metre uzaklıkta',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Mesafe bilgisi için konum iznini verin',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Alt boşluk (Safe area için)
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _startNavigation(BuildContext context, MapService mapService, LocationService locationService) async {
    // Eğer konum yoksa önce konum al
    if (locationService.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum alınıyor...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      await locationService.getCurrentLocation();
      
      // Hala konum alınamadıysa hata göster
      if (locationService.currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum alınamadı: ${locationService.error ?? "Bilinmeyen hata"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: () => _startNavigation(context, mapService, locationService),
            ),
          ),
        );
        return;
      }
    }
    
    final userLocation = LatLng(
      locationService.currentPosition!.latitude,
      locationService.currentPosition!.longitude,
    );
    
    mapService.startNavigation(poi, userLocation);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${poi.name} noktasına yürüyerek navigasyon başlatıldı'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Durdur',
          onPressed: () => mapService.stopNavigation(),
        ),
      ),
    );
  }

  void _sharePOI(BuildContext context) {
    final shareText = '''
🌳 Kayseri Millet Bahçesi - ${poi.name}

📍 Kategori: ${poi.category}
📝 ${poi.description}

🗺️ Konum: ${poi.latitude.toStringAsFixed(6)}, ${poi.longitude.toStringAsFixed(6)}

📱 Kayseri Millet Bahçesi Harita Uygulaması ile paylaşıldı
''';

    // Gerçek uygulamada share_plus paketi kullanılabilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paylaş fonksiyonu hazırlanıyor...'),
        action: SnackBarAction(
          label: 'Kopyala',
          onPressed: () {
            // Clipboard'a kopyalama burada yapılacak
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Tüm kategoriler için mavi renk
    switch (category.toLowerCase()) {
      case 'wc':
        return const Color(0xFF3252a8);
      case 'kapı':
        return const Color(0xFF3252a8);
      case 'üniversite':
        return const Color(0xFF3252a8);
      default:
        return const Color(0xFF3252a8);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wc':
        return Icons.wc;
      case 'kapı':
        return Icons.login;
      case 'üniversite':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }
}