import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/map_service.dart';
import '../services/location_service.dart';
import '../widgets/search_widget.dart';
import '../widgets/poi_bottom_sheet.dart';
import '../widgets/navigation_controls.dart';
import '../widgets/web_info_panel.dart';

class WebMapScreen extends StatefulWidget {
  const WebMapScreen({super.key});

  @override
  State<WebMapScreen> createState() => _WebMapScreenState();
}

class _WebMapScreenState extends State<WebMapScreen> {
  late GoogleMapController _mapController;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _setupLocationListener();
    });
  }

  void _setupLocationListener() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final mapService = Provider.of<MapService>(context, listen: false);
    
    locationService.addListener(() {
      if (locationService.isTracking && 
          locationService.currentPosition != null && 
          mapService.isNavigating) {
        
        final newLocation = LatLng(
          locationService.currentPosition!.latitude,
          locationService.currentPosition!.longitude,
        );
        
        mapService.updateUserLocation(newLocation);
      }
    });
  }

  Future<void> _initializeServices() async {
    final mapService = Provider.of<MapService>(context, listen: false);
    final locationService = Provider.of<LocationService>(context, listen: false);

    try {
      await mapService.initializePOIs();
      await locationService.getCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harita yüklenirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sol panel - Bilgi kısmı (%30)
        const Expanded(
          flex: 30,
          child: WebInfoPanel(),
        ),
        
        // Sağ panel - Harita kısmı (%70)
        Expanded(
          flex: 70,
          child: _buildMapSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Üst panel - Yazı kısmı (7/10 = %70)
        Expanded(
          flex: 7,
          child: const WebInfoPanel(),
        ),
        
        // Alt panel - Harita kısmı (3/10 = %30)
        Expanded(
          flex: 3,
          child: _buildMapSection(),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Consumer2<MapService, LocationService>(
      builder: (context, mapService, locationService, child) {
        return Stack(
          children: [
            // Google Maps
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(38.704200, 35.509500), // Millet Bahçesi merkezi
                zoom: 16.0,
              ),
              markers: mapService.markers,
              polylines: mapService.polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                mapService.setController(controller);
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              onTap: (LatLng position) {
                if (_showSearch) {
                  setState(() {
                    _showSearch = false;
                  });
                }
              },
            ),

            // Arama butonu
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                  });
                },
                backgroundColor: Colors.white,
                child: Icon(_showSearch ? Icons.close : Icons.search),
              ),
            ),

            // Konum butonu
            Positioned(
              top: 70,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => mapService.centerOnMilletBahcesi(),
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location),
              ),
            ),

            // Arama widget'ı
            if (_showSearch)
              Positioned(
                top: 16,
                left: 16,
                right: 80,
                child: SearchWidget(
                  onClose: () {
                    setState(() {
                      _showSearch = false;
                    });
                  },
                ),
              ),

            // Navigasyon kontrolleri
            if (mapService.isNavigating)
              const Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: NavigationControls(),
              ),

            // POI Bottom Sheet
            if (mapService.selectedPoi != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: POIBottomSheet(poi: mapService.selectedPoi!),
              ),
          ],
        );
      },
    );
  }
}