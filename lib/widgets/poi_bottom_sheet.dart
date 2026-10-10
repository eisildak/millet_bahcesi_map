import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/event_config.dart';
import '../models/point_of_interest.dart';
import '../models/poi_category.dart';
import '../services/map_service.dart';
import '../services/location_service.dart';

class POIBottomSheet extends StatelessWidget {
  final PointOfInterest poi;

  const POIBottomSheet({super.key, required this.poi});

  @override
  Widget build(BuildContext context) {
    final bool isEvent = context.read<MapService>().isEventPoi(poi);
    final bool isCustom = poi.id == MapService.customDestinationId;
    final bool insideEventArea = currentEvent.contains(
      LatLng(poi.latitude, poi.longitude),
    );
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
                backgroundColor: PoiCategory.color(isEvent: isEvent),
                radius: 24,
                child: Icon(
                  PoiCategory.icon(poi.category),
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
                      isEvent ? 'Etkinlik · ${poi.category}' : poi.category,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    if (insideEventArea)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: PoiCategory.eventColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Etkinlik alanı içinde',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  final mapService = Provider.of<MapService>(
                    context,
                    listen: false,
                  );
                  mapService.stopNavigation();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // POI açıklaması
          Text(poi.description, style: const TextStyle(fontSize: 16)),

          // Haritada seçilen serbest noktada koordinatı göster/kopyala:
          // etkinlik noktalarını (sahne, stant...) toplamak için kullanılır.
          if (isCustom) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _coordinateText(poi),
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _coordinateText(poi)),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Koordinat kopyalandı'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Koordinatı kopyala'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Aksiyon butonları
          Row(
            children: [
              // Navigasyonu başlat butonu
              Expanded(
                child: Consumer2<MapService, LocationService>(
                  builder: (context, mapService, locationService, child) {
                    return ElevatedButton.icon(
                      onPressed: () => _startNavigation(
                        context,
                        mapService,
                        locationService,
                      ),
                      icon: Icon(
                        locationService.currentPosition != null
                            ? Icons.directions_walk
                            : Icons.location_searching,
                      ),
                      label: Text(
                        locationService.currentPosition != null
                            ? 'Yürüyerek Git'
                            : 'Konum Al & Git',
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
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
                      Icon(
                        Icons.location_on,
                        color: Colors.blue[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Konumunuzdan ${distance.toInt()} metre uzaklıkta',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
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
                    Icon(
                      Icons.location_off,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mesafe bilgisi için konum iznini verin',
                      style: TextStyle(color: Colors.orange[700], fontSize: 14),
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

  void _startNavigation(
    BuildContext context,
    MapService mapService,
    LocationService locationService,
  ) async {
    print('Navigasyon başlatma talebi alındı...');

    // Eğer konum yoksa önce konum al
    if (locationService.currentPosition == null) {
      await locationService.getCurrentLocation();
    }

    // Konum var mı kontrol et
    if (locationService.currentPosition != null) {
      final userLocation = LatLng(
        locationService.currentPosition!.latitude,
        locationService.currentPosition!.longitude,
      );

      print(
        'Kullanıcı konumu: ${userLocation.latitude}, ${userLocation.longitude}',
      );
      print('Hedef: ${poi.latitude}, ${poi.longitude}');

      // Navigasyonu başlat
      await mapService.startNavigation(poi, userLocation);

      // Konum takibini başlat
      await locationService.startLocationTracking();
    } else {
      // Konum alınamadı, Millet Bahçesi merkezinden başlat
      const defaultLocation = LatLng(
        38.704200,
        35.509500,
      ); // Millet Bahçesi merkezi

      print(
        'Konum alınamadı, varsayılan konumdan başlatılıyor: ${defaultLocation.latitude}, ${defaultLocation.longitude}',
      );
      print('Hedef: ${poi.latitude}, ${poi.longitude}');

      await mapService.startNavigation(poi, defaultLocation);
    }
  }

  void _sharePOI(BuildContext context) {
    final shareText =
        '''
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

  static String _coordinateText(PointOfInterest poi) =>
      '${poi.latitude.toStringAsFixed(6)}, ${poi.longitude.toStringAsFixed(6)}';
}
