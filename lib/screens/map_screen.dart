import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import '../config/event_config.dart';
import '../services/map_service.dart';
import '../services/location_service.dart';
import '../widgets/search_widget.dart';
import '../widgets/poi_bottom_sheet.dart';
import '../widgets/navigation_controls.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // GoogleMap widget'ı (mobil ve web'de aynı) hazır olduğunda onMapCreated
    // zaten tetiklenir; servisleri burada beklemeden başlatmak yeterli.
    // (Web'de haritanın 0x0 görünmez kalma sorunu artık web/index.html'deki
    // google.maps.Map resize-fix patch'i ile çözülüyor, bkz. oradaki not.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _setupLocationListener();
    });
  }

  void _setupLocationListener() {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final mapService = Provider.of<MapService>(context, listen: false);

    // LocationService'i dinle ve konum değişikliklerini MapService'e ilet
    locationService.addListener(() {
      if (locationService.isTracking &&
          locationService.currentPosition != null &&
          mapService.isNavigating) {
        final newLocation = LatLng(
          locationService.currentPosition!.latitude,
          locationService.currentPosition!.longitude,
        );

        // MapService'de kullanıcı konumunu güncelle
        mapService.updateUserLocation(newLocation);
      }
    });
  }

  Future<void> _initializeServices() async {
    final mapService = Provider.of<MapService>(context, listen: false);
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    // POI'ları initialize et
    await mapService.initializePOIs();

    // Konum servisini başlat ama bekleme - arkaplanda çalışsın
    _requestLocationWithDialog(locationService);
  }

  Future<void> _requestLocationWithDialog(
    LocationService locationService,
  ) async {
    try {
      await locationService.getCurrentLocation();

      if (locationService.currentPosition != null) {
        // Konum başarıyla alındı
        print('Konum başarıyla alındı: ${locationService.currentPosition}');
        return;
      }
    } catch (e) {
      print('Konum alma hatası: $e');
    }

    // Konum alınamadıysa kullanıcıya seçenek sun
    if (mounted && locationService.currentPosition == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Konum İzni'),
            content: const Text(
              'Navigasyon ve yakındaki noktaları gösterebilmek için konum izni gerekli.\n\n'
              'İzin vermek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // İzin verilmezse varsayılan konuma git
                  _mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      currentEvent.center,
                      currentEvent.initialZoom,
                    ),
                  );
                },
                child: const Text('Hayır'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await locationService.getCurrentLocation();

                  if (locationService.currentPosition != null) {
                    // Konum alındı, haritayı güncelle
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          locationService.currentPosition!.latitude,
                          locationService.currentPosition!.longitude,
                        ),
                        17.0,
                      ),
                    );
                  } else {
                    // Hala konum alınamadı, kullanıcıya bilgi ver
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            locationService.error ??
                                'Konum alınamadı. Lütfen cihaz ayarlarından konum servisini açın.',
                          ),
                          duration: const Duration(seconds: 4),
                          action: SnackBarAction(
                            label: 'Ayarlar',
                            onPressed: () {
                              // Kullanıcıyı ayarlara yönlendir
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Evet'),
              ),
            ],
          );
        },
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    print('🗺️ Google Maps onMapCreated called!');
    print('🌐 Platform: ${kIsWeb ? 'WEB' : 'MOBILE'}');
    _mapController = controller;
    final mapService = Provider.of<MapService>(context, listen: false);
    mapService.setController(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayseri Millet Bahçesi'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              final locationService = Provider.of<LocationService>(
                context,
                listen: false,
              );
              locationService.getCurrentLocation();
            },
          ),
        ],
      ),
      // StackFit.expand: Stack'in boyutu konumlandırılmamış çocuklara göre
      // belirlenir. Yükleme overlay'i yükleme yokken SizedBox.shrink() (0x0)
      // döndüğü için, expand olmadan Stack 0x0'a çöküp haritayı da 0x0 yapıyor
      // ve harita (özellikle web'de) tamamen kayboluyordu.
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ana harita - mobil ve web'de aynı GoogleMap widget'ı.
          // (google_maps_flutter_web web'de haritayı döndürme/tilt ve native
          // "konumum" butonunu desteklemez; bunun dışında aynı API.)
          Positioned.fill(
            child: Consumer<MapService>(
              builder: (context, mapService, child) {
                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  // Harita etkinlik alanına odaklı açılır (bkz. config/event_config.dart).
                  initialCameraPosition: CameraPosition(
                    target: currentEvent.center,
                    zoom: currentEvent.initialZoom,
                  ),
                  markers: mapService.markers,
                  polylines: mapService.polylines,
                  polygons: mapService.polygons,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                  mapType: MapType.hybrid, // Satellite + roads view
                  onTap: (LatLng position) {
                    // Arama açıksa önce onu kapat
                    if (_showSearch) {
                      setState(() {
                        _showSearch = false;
                      });
                      return;
                    }
                    // Haritada dokunulan noktayı (ör. Google'ın gösterdiği bir
                    // tuvalet) yürüme hedefi olarak seç.
                    mapService.selectCustomDestination(position);
                  },
                  onLongPress: mapService.selectCustomDestination,
                );
              },
            ),
          ),

          // Arama widget'ı
          if (_showSearch)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              // PointerInterceptor: web'de harita (platform view) üstündeki
              // Flutter widget'larına gelen tıklamaların haritaya kaçmasını önler.
              child: PointerInterceptor(
                child: SearchWidget(
                  onClose: () {
                    setState(() {
                      _showSearch = false;
                    });
                  },
                ),
              ),
            ),

          // Navigasyon kontrolleri. right: 88 = sağdaki FAB kolonu (56) +
          // kenar boşlukları; aksi halde FAB'lar panelin sağını kapatıyor.
          Positioned(
            bottom: 16,
            left: 16,
            right: 88,
            child: PointerInterceptor(child: const NavigationControls()),
          ),

          // Loading indicator
          Consumer<LocationService>(
            builder: (context, locationService, child) {
              if (locationService.isLoading) {
                return Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3252a8),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),

      // Alt panel POI detayları için
      bottomSheet: Consumer<MapService>(
        builder: (context, mapService, child) {
          // Navigasyon sırasında POI kartını gizle; yoksa alttaki navigasyon
          // panelini (ilerleme çubuğu) kapatıyor.
          if (mapService.selectedPoi != null && !mapService.isNavigating) {
            return PointerInterceptor(
              child: POIBottomSheet(poi: mapService.selectedPoi!),
            );
          }
          return const SizedBox.shrink();
        },
      ),

      // Bir nokta kartı açıkken FAB'ları gizle: Material FAB'ı alt kartın üst
      // kenarına oturtuyor ve kartın kapatma (X) butonunu kapatıyordu.
      // mainAxisSize.min: aksi halde Column tüm yüksekliği kaplar ve
      // PointerInterceptor sağ kenarda haritanın sürüklenmesini engeller.
      floatingActionButton: Consumer<MapService>(
        builder: (context, mapService, fabs) =>
            mapService.selectedPoi != null && !mapService.isNavigating
            ? const SizedBox.shrink()
            : fabs!,
        child: PointerInterceptor(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Millet Bahçesi'ne git butonu
              FloatingActionButton(
                heroTag: "center_fab",
                onPressed: () {
                  final mapService = Provider.of<MapService>(
                    context,
                    listen: false,
                  );
                  mapService.centerOnMilletBahcesi();
                },
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.park, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Konum butonu
              Consumer<LocationService>(
                builder: (context, locationService, child) {
                  return FloatingActionButton(
                    heroTag: "location_fab",
                    onPressed: locationService.isLoading
                        ? null
                        : () async {
                            await locationService.getCurrentLocation();

                            if (locationService.currentPosition != null) {
                              print(
                                'Konuma gidiliyor: ${locationService.currentPosition!.latitude}, ${locationService.currentPosition!.longitude}',
                              );
                              _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(
                                    locationService.currentPosition!.latitude,
                                    locationService.currentPosition!.longitude,
                                  ),
                                  17.0,
                                ),
                              );

                              // Başarılı mesaj göster
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      locationService.error != null
                                          ? 'Varsayılan konum gösteriliyor'
                                          : 'Mevcut konumunuz gösteriliyor',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              // Hata durumunda Millet Bahçesi'ne git
                              _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  currentEvent.center,
                                  currentEvent.initialZoom,
                                ),
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Konum alınamadı, Millet Bahçesi gösteriliyor',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                    backgroundColor: locationService.currentPosition != null
                        ? const Color(0xFF3252a8)
                        : Colors.grey[400],
                    child: locationService.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.gps_fixed, color: Colors.white),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
