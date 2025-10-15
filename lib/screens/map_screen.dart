import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    final mapService = Provider.of<MapService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    await mapService.initializePOIs();
    locationService.getCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
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
              final locationService = Provider.of<LocationService>(context, listen: false);
              locationService.getCurrentLocation();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ana harita
          Consumer<MapService>(
            builder: (context, mapService, child) {
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: MapService.kayseriMilletBahcesi,
                  zoom: 16.0,
                ),
                markers: mapService.markers,
                polylines: mapService.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                buildingsEnabled: true,
                trafficEnabled: false,
                mapType: MapType.hybrid, // Satellite + roads view
                onTap: (LatLng position) {
                  // Haritaya tıklandığında search'ü kapat
                  if (_showSearch) {
                    setState(() {
                      _showSearch = false;
                    });
                  }
                },
              );
            },
          ),

          // Arama widget'ı
          if (_showSearch)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SearchWidget(
                onClose: () {
                  setState(() {
                    _showSearch = false;
                  });
                },
              ),
            ),

          // Navigasyon kontrolleri
          const Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: NavigationControls(),
          ),

          // Loading indicator
          Consumer<LocationService>(
            builder: (context, locationService, child) {
              if (locationService.isLoading) {
                return Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3252a8)),
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
          if (mapService.selectedPoi != null) {
            return POIBottomSheet(poi: mapService.selectedPoi!);
          }
          return const SizedBox.shrink();
        },
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Millet Bahçesi'ne git butonu
          FloatingActionButton(
            heroTag: "center_fab",
            onPressed: () {
              final mapService = Provider.of<MapService>(context, listen: false);
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
                onPressed: locationService.isLoading ? null : () async {
                  await locationService.getCurrentLocation();
                  
                  if (locationService.currentPosition != null) {
                    _mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          locationService.currentPosition!.latitude,
                          locationService.currentPosition!.longitude,
                        ),
                        18.0,
                      ),
                    );
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.gps_fixed, color: Colors.white),
              );
            },
          ),
        ],
      ),
    );
  }
}