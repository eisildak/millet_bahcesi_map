import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/point_of_interest.dart';

class MapService extends ChangeNotifier {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<PointOfInterest> _pois = [];
  List<PointOfInterest> _filteredPois = [];
  bool _isNavigating = false;
  PointOfInterest? _selectedPoi;

  // Google API Key - Directions API için
  static const String _apiKey = 'AIzaSyDWVBfYxASYj1aTqcS8pvHa67IDic4wthk';

  // Kayseri Millet Bahçesi merkez koordinatları (WC'lerin ortası)
  static const LatLng kayseriMilletBahcesi = LatLng(38.704200, 35.509500);

  // Getters
  GoogleMapController? get controller => _controller;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  List<PointOfInterest> get pois => _pois;
  List<PointOfInterest> get filteredPois => _filteredPois;
  bool get isNavigating => _isNavigating;
  PointOfInterest? get selectedPoi => _selectedPoi;

  void setController(GoogleMapController controller) {
    _controller = controller;
    notifyListeners();
  }

  Future<void> initializePOIs() async {
    _pois = POIData.kayseriMilletBahcesi;
    _filteredPois = List.from(_pois);
    // Cache'i temizle ki yeni boyuttaki marker'lar oluşturulsun
    _markerCache.clear();
    await _createMarkers();
    notifyListeners();
  }

  Future<void> _createMarkers() async {
    _markers.clear();
    
    for (PointOfInterest poi in _pois) {
      final icon = await _getMarkerIcon(poi.category);
      _markers.add(
        Marker(
          markerId: MarkerId(poi.id),
          position: LatLng(poi.latitude, poi.longitude),
          infoWindow: InfoWindow(
            title: poi.name,
            snippet: poi.description,
            onTap: () => selectPOI(poi),
          ),
          icon: icon,
          onTap: () => selectPOI(poi),
        ),
      );
    }
  }

  // Custom marker cache
  final Map<String, BitmapDescriptor> _markerCache = {};

  Future<BitmapDescriptor> _getMarkerIcon(String category) async {
    // Cache'den kontrol et
    if (_markerCache.containsKey(category)) {
      return _markerCache[category]!;
    }

    BitmapDescriptor icon;
    
    switch (category.toLowerCase()) {
      case 'kapı':
        icon = await _createCustomMarker(Icons.login, const Color(0xFF3252a8));
        break;
      case 'wc':
        icon = await _createCustomMarker(Icons.wc, const Color(0xFF3252a8));
        break;
      case 'üniversite':
        icon = await _createCustomMarker(Icons.school, const Color(0xFF3252a8));
        break;
      default:
        icon = await _createCustomMarker(Icons.location_on, const Color(0xFF3252a8));
        break;
    }
    
    // Cache'e kaydet
    _markerCache[category] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _createCustomMarker(IconData iconData, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(30, 30);

    // Beyaz daire arka plan
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 1.2,
      backgroundPaint,
    );

    // Mavi çerçeve
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 1.2,
      borderPaint,
    );

    // Icon çiz
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 12,
        fontFamily: iconData.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  void selectPOI(PointOfInterest poi) {
    _selectedPoi = poi;
    
    // Haritayı seçili POI'ye odakla
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(poi.latitude, poi.longitude),
        18.0,
      ),
    );
    
    notifyListeners();
  }

  Future<void> startNavigation(PointOfInterest destination, LatLng userLocation) async {
    _isNavigating = true;
    _selectedPoi = destination;
    
    try {
      await _getDirections(userLocation, LatLng(destination.latitude, destination.longitude));
    } catch (e) {
      debugPrint('Navigasyon hatası: $e');
    }
    
    notifyListeners();
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    if (_apiKey == 'YOUR_GOOGLE_MAPS_API_KEY_HERE') {
      debugPrint('Google Maps API Key ayarlanmamış!');
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}&'
      'destination=${destination.latitude},${destination.longitude}&'
      'mode=walking&'
      'key=$_apiKey'
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          
          _createPolyline(polylinePoints);
        }
      }
    } catch (e) {
      debugPrint('Directions API hatası: $e');
    }
  }

  void _createPolyline(String encodedPolyline) {
    List<LatLng> polylineCoordinates = _decodePolyline(encodedPolyline);
    
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('navigation_route'),
        points: polylineCoordinates,
        color: Colors.blue,
        width: 5,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polylineCoordinates;
  }

  void searchPOIs(String query) {
    if (query.isEmpty) {
      _filteredPois = List.from(_pois);
    } else {
      _filteredPois = _pois
          .where((poi) =>
              poi.name.toLowerCase().contains(query.toLowerCase()) ||
              poi.category.toLowerCase().contains(query.toLowerCase()) ||
              poi.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _polylines.clear();
    _selectedPoi = null;
    notifyListeners();
  }

  void centerOnMilletBahcesi() {
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(kayseriMilletBahcesi, 16.0),
    );
  }
}