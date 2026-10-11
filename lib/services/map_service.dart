import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/point_of_interest.dart';
import '../models/poi_category.dart';
import '../models/route_step.dart';
import '../config/api_keys.dart';
import '../config/event_config.dart';

class MapService extends ChangeNotifier {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<PointOfInterest> _pois = [];
  List<PointOfInterest> _filteredPois = [];
  bool _isNavigating = false;
  PointOfInterest? _selectedPoi;

  /// Haritada dokunularak seçilen serbest hedef (ör. Google'ın gösterdiği bir
  /// tuvalet). Kendi POI listemizde olmayan noktalara rota için kullanılır.
  static const String customDestinationId = 'custom-destination';
  Marker? _customDestinationMarker;
  Marker? _userLocationMarker;
  // Mavi noktanın "kalp ritmi" kareleri ve animasyon durumu.
  List<BitmapDescriptor>? _userPulseFrames;
  Timer? _userPulseTimer;
  int _userPulseFrame = 0;
  LatLng? _userLocation;

  // Aktif rota: yön oklarını ve "gidilen / kalan" ayrımını hesaplamak için
  // decode edilmiş rota noktaları saklanır.
  List<LatLng> _currentRoutePoints = [];
  Set<Marker> _routeArrowMarkers = {};

  // Navigasyon ilerlemesi: rota toplam uzunluğu, kalan mesafe ve (varsa)
  // Directions API'nin verdiği toplam süre.
  double _routeTotalMeters = 0;
  double _routeRemainingMeters = 0;
  int? _routeDurationSeconds;

  // Adım adım tarif (OSRM / Google / kuş uçuşu) ve sıradaki adım takibi.
  List<RouteStep> _routeSteps = [];
  List<int> _stepRouteIndices = []; // her adımın rota üzerindeki nokta indeksi
  int _nextStepIndex = 0;
  double _distanceToNextStep = 0;

  List<RouteStep> get routeSteps => List.unmodifiable(_routeSteps);

  /// Kullanıcının önündeki ilk manevra (yoksa null).
  RouteStep? get nextStep =>
      _nextStepIndex < _routeSteps.length ? _routeSteps[_nextStepIndex] : null;

  /// Sıradaki manevraya kalan yürüme mesafesi.
  double get distanceToNextStepMeters => _distanceToNextStep;

  /// Yürüme hızı tahmini (m/sn) - API süre vermediğinde kalan süre için.
  static const double _walkingSpeedMps = 1.3;

  /// Hedefe bu mesafeden yakınsa "ulaştınız" sayılır.
  static const double arrivalThresholdMeters = 20;

  double get routeTotalMeters => _routeTotalMeters;
  bool get isFallbackRoute => _isFallbackRoute;

  /// Etkinlik alanının rengi. Bilerek kırmızı: mavi wayfinding (rota) ve
  /// turuncu (kuş uçuşu yedek rota) çizgileriyle karışmasın.
  static const Color eventAreaColor = Color(0xFFE53935);

  /// Etkinlik alanı: hafif kırmızı dolgu + kırmızı sınır çizgisi.
  /// Sınır [currentEvent]'ten gelir; tanımlı değilse boş küme döner.
  late final Set<Polygon> polygons = currentEvent.hasBoundary
      ? {
          Polygon(
            polygonId: const PolygonId('event_area'),
            points: currentEvent.boundary,
            fillColor: eventAreaColor.withValues(alpha: 0.12),
            // Kenar bilerek silik: alanı belirtsin ama rotanın önüne geçmesin.
            strokeColor: eventAreaColor.withValues(alpha: 0.45),
            strokeWidth: 2,
            consumeTapEvents: false,
            zIndex: 1,
          ),
        }
      : const <Polygon>{};

  /// Alanın içini tarayan ince çapraz çizgiler (hatch). Google Maps poligonları
  /// desenli dolgu desteklemediği için çizgiler poligona kırpılarak üretilir.
  late final Set<Polyline> _eventHatchPolylines = _buildHatchPolylines(
    currentEvent.boundary,
  );

  static Set<Polyline> _buildHatchPolylines(
    List<LatLng> boundary, {
    double spacingMeters = 14,
  }) {
    if (boundary.length < 3) return const <Polyline>{};

    // Yerel düzlemsel (metre) koordinatlara çevir.
    final double lat0 = boundary.first.latitude;
    final double lng0 = boundary.first.longitude;
    const double mPerDegLat = 111320;
    final double mPerDegLng = 111320 * math.cos(lat0 * math.pi / 180);
    final pts = [
      for (final p in boundary)
        (
          x: (p.longitude - lng0) * mPerDegLng,
          y: (p.latitude - lat0) * mPerDegLat,
        ),
    ];
    LatLng toLatLng(double x, double y) =>
        LatLng(lat0 + y / mPerDegLat, lng0 + x / mPerDegLng);

    // 45° çizgiler: x - y = c. c aralığını kapsayacak şekilde tara.
    double minC = double.infinity, maxC = -double.infinity;
    for (final p in pts) {
      minC = math.min(minC, p.x - p.y);
      maxC = math.max(maxC, p.x - p.y);
    }
    final double step = spacingMeters * math.sqrt2;

    final lines = <Polyline>{};
    int id = 0;
    for (double c = minC + step / 2; c < maxC; c += step) {
      // Çizginin poligon kenarlarıyla kesişimlerini topla.
      final hits = <({double x, double y})>[];
      for (int i = 0; i < pts.length; i++) {
        final a = pts[i];
        final b = pts[(i + 1) % pts.length];
        final double fa = a.x - a.y - c;
        final double fb = b.x - b.y - c;
        // Yarı-açık aralık: köşe noktasından geçen çizgi iki kez sayılmasın.
        if ((fa < 0) != (fb < 0)) {
          final double t = fa / (fa - fb);
          hits.add((x: a.x + t * (b.x - a.x), y: a.y + t * (b.y - a.y)));
        }
      }
      hits.sort((p, q) => p.x.compareTo(q.x));
      // Kesişimler çift çift alanın içinde kalan parçaları verir.
      for (int k = 0; k + 1 < hits.length; k += 2) {
        lines.add(
          Polyline(
            polylineId: PolylineId('event_area_hatch_${id++}'),
            points: [
              toLatLng(hits[k].x, hits[k].y),
              toLatLng(hits[k + 1].x, hits[k + 1].y),
            ],
            color: eventAreaColor.withValues(alpha: 0.35),
            width: 1,
            consumeTapEvents: false,
            zIndex: 1,
          ),
        );
      }
    }
    return lines;
  }

  double get routeRemainingMeters => _routeRemainingMeters;

  /// 0.0 (başlangıç) - 1.0 (hedef) arası ilerleme.
  double get routeProgress {
    if (_routeTotalMeters <= 0) return 0;
    return (1 - _routeRemainingMeters / _routeTotalMeters).clamp(0.0, 1.0);
  }

  bool get hasArrived =>
      _isNavigating &&
      _routeTotalMeters > 0 &&
      _routeRemainingMeters <= arrivalThresholdMeters;

  /// Kalan tahmini süre (dakika, yukarı yuvarlanmış).
  int get routeRemainingMinutes {
    final double seconds =
        (_routeDurationSeconds != null && _routeTotalMeters > 0)
        ? _routeDurationSeconds! * (_routeRemainingMeters / _routeTotalMeters)
        : _routeRemainingMeters / _walkingSpeedMps;
    return (seconds / 60).ceil();
  }

  final Map<int, BitmapDescriptor> _arrowIconCache = {};

  // Google API Key - Directions API için
  static const String _apiKey = ApiKeys.googleMapsApiKey;

  // Kayseri Millet Bahçesi merkez koordinatları (WC'lerin ortası)
  static const LatLng kayseriMilletBahcesi = LatLng(38.704200, 35.509500);

  // Getters
  GoogleMapController? get controller => _controller;
  Set<Marker> get markers => _getAllMarkers();

  /// Etkinlik alanı tarama çizgileri + rota çizgileri (rota üstte, zIndex ile).
  Set<Polyline> get polylines => {..._eventHatchPolylines, ..._polylines};
  List<PointOfInterest> get pois => _pois;
  List<PointOfInterest> get filteredPois => _filteredPois;
  bool get isNavigating => _isNavigating;
  PointOfInterest? get selectedPoi => _selectedPoi;

  // Tüm marker'ları (POI + kullanıcı konumu + rota yön okları) döndür
  Set<Marker> _getAllMarkers() {
    Set<Marker> allMarkers = Set.from(_markers);
    if (_userLocationMarker != null) {
      allMarkers.add(_userLocationMarker!);
    }
    if (_customDestinationMarker != null) {
      allMarkers.add(_customDestinationMarker!);
    }
    allMarkers.addAll(_routeArrowMarkers);
    return allMarkers;
  }

  void setController(GoogleMapController controller) {
    _controller = controller;
    notifyListeners();
  }

  /// Etkinliğe özel noktaların id'leri (kırmızı marker / etkinlik rozeti).
  late final Set<String> _eventPoiIds = {
    for (final p in currentEvent.pois) p.id,
  };

  bool isEventPoi(PointOfInterest poi) => _eventPoiIds.contains(poi.id);

  Future<void> initializePOIs() async {
    // Parkın genel noktaları + etkinliğe özel noktalar birlikte gösterilir.
    _pois = [...POIData.kayseriMilletBahcesi, ...currentEvent.pois];
    _filteredPois = List.from(_pois);
    // Cache'i temizle ki yeni boyuttaki marker'lar oluşturulsun
    _markerCache.clear();
    await _createMarkers();
    notifyListeners();
  }

  Future<void> _createMarkers() async {
    _markers.clear();

    for (PointOfInterest poi in _pois) {
      final bool isEvent = isEventPoi(poi);
      final icon = await _getMarkerIcon(poi.category, isEvent: isEvent);
      _markers.add(
        Marker(
          markerId: MarkerId(poi.id),
          // Etkinlik noktaları genel noktaların üstünde görünsün.
          zIndexInt: isEvent ? 600 : 500,
          position: LatLng(poi.latitude, poi.longitude),
          // InfoWindow yok: dokununca alttaki nokta kartı açılıyor; balon aynı
          // bilgiyi tekrar ediyor ve navigasyonda rotanın üstünü kapatıyordu.
          icon: icon,
          onTap: () => selectPOI(poi),
        ),
      );
    }
  }

  // Custom marker cache
  final Map<String, BitmapDescriptor> _markerCache = {};

  Future<BitmapDescriptor> _getMarkerIcon(
    String category, {
    bool isEvent = false,
  }) async {
    final String cacheKey = '${category.toLowerCase()}|$isEvent';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    // Üniversite standı kendi logosuyla; diğerleri kategori ikonu + renk
    // (genel: mavi, etkinlik: kırmızı) ile çizilir.
    final BitmapDescriptor icon = category.toLowerCase() == 'üniversite'
        ? await _createUniversityMarker()
        : await _createCustomMarker(
            PoiCategory.icon(category),
            PoiCategory.color(isEvent: isEvent),
          );

    // Cache'e kaydet
    _markerCache[cacheKey] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _createCustomMarker(
    IconData iconData,
    Color color,
  ) async {
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
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  Future<BitmapDescriptor> _createUniversityMarker() async {
    try {
      // NNY logosunu asset'ten yükle
      return await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/nny_university_logo.png',
      );
    } catch (e) {
      // Logo yüklenemezse alternatif logoyu dene
      try {
        return await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/icons/nny_logo.png',
        );
      } catch (e2) {
        // Her ikisi de yüklenemezse custom marker oluştur
        return await _createCustomUniversityMarker();
      }
    }
  }

  Future<BitmapDescriptor> _createCustomUniversityMarker() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(48, 48);

    // Beyaz daire arka plan
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 2,
      backgroundPaint,
    );

    // NNY Logo çerçevesi (mavi gradient)
    final gradientPaint = Paint()
      ..shader =
          const LinearGradient(
            colors: [Color(0xFF1e3a5f), Color(0xFF3252a8)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width / 2 - 2,
            ),
          );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 2,
      gradientPaint,
    );

    // NNY yazısı - büyütülmüş
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'NNY',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1,
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
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(uint8List);
  }

  void selectPOI(PointOfInterest poi) {
    _selectedPoi = poi;
    if (poi.id != customDestinationId) _customDestinationMarker = null;

    // Haritayı seçili POI'ye odakla
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(poi.latitude, poi.longitude), 18.0),
    );

    notifyListeners();
  }

  /// Haritada dokunulan noktayı yürüme hedefi olarak seçer. google_maps_flutter
  /// Google'ın kendi POI'lerine (placeId) tıklamayı dışarı vermediği için,
  /// kullanıcı ör. bir tuvalet ikonuna dokunduğunda o konumu hedef alırız.
  Future<void> selectCustomDestination(LatLng position) async {
    // Navigasyon sürerken dokunuş hedefi değiştirmesin.
    if (_isNavigating) return;
    final int token = ++_customSelectionToken;
    await _setCustomDestination(
      position: position,
      name: 'Seçilen nokta',
      description:
          'Haritada seçtiğiniz noktaya yürüme rotası oluşturabilirsiniz.',
      category: 'Hedef',
    );
    // Dokunulan yerde Google'da kayıtlı bir yer (WC, kafe...) varsa adını
    // canlı sorgula; bulunursa kartı ve işareti o yere göre güncelle.
    unawaited(_resolveGooglePlaceAt(position, token));
  }

  int _customSelectionToken = 0;

  Future<void> _setCustomDestination({
    required LatLng position,
    required String name,
    required String description,
    required String category,
  }) async {
    final icon = await _getMarkerIcon(category);
    _customDestinationMarker = Marker(
      markerId: const MarkerId(customDestinationId),
      position: position,
      icon: icon,
      zIndexInt: 900,
    );
    _selectedPoi = PointOfInterest(
      id: customDestinationId,
      name: name,
      description: description,
      latitude: position.latitude,
      longitude: position.longitude,
      category: category,
    );
    notifyListeners();
  }

  // Google Places API (New) - Nearby Search: dokunulan noktaya 30 m içindeki en
  // yakın yer. Google koşulları gereği sonuç saklanmaz, sadece bu seçimde
  // kullanılır. Dokunuş başına tek istek (ayda ilk 5000 ücretsiz).
  Future<void> _resolveGooglePlaceAt(LatLng position, int token) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask':
                  'places.displayName,places.location,places.primaryType,'
                  'places.primaryTypeDisplayName',
            },
            body: json.encode({
              'maxResultCount': 1,
              'languageCode': 'tr',
              'rankPreference': 'DISTANCE',
              'locationRestriction': {
                'circle': {
                  'center': {
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                  },
                  'radius': 30.0,
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('Places HTTP ${response.statusCode}: ${response.body}');
        return;
      }
      final places =
          (json.decode(response.body) as Map<String, dynamic>)['places']
              as List?;
      if (places == null || places.isEmpty) {
        debugPrint('Places: 30 m içinde yer bulunamadı');
        return;
      }
      // Bu arada kullanıcı başka yere dokunduysa ya da navigasyon başladıysa
      // eski sonucu uygulama.
      if (token != _customSelectionToken || _isNavigating) {
        debugPrint('Places: sonuç eski seçime ait, atlandı');
        return;
      }

      final place = places.first as Map<String, dynamic>;
      final String? name = (place['displayName'] as Map?)?['text'] as String?;
      if (name == null || name.isEmpty) return;
      final String type = (place['primaryType'] as String?) ?? '';
      final String typeLabel =
          ((place['primaryTypeDisplayName'] as Map?)?['text'] as String?) ??
          'Yer';
      final loc = place['location'] as Map<String, dynamic>;
      await _setCustomDestination(
        position: LatLng(
          (loc['latitude'] as num).toDouble(),
          (loc['longitude'] as num).toDouble(),
        ),
        name: name,
        description: '$typeLabel · Google Haritalar',
        category: _categoryForGoogleType(type, typeLabel),
      );
    } catch (e) {
      debugPrint('Google yer adı alınamadı: $e');
    }
  }

  // Google yer türünü kendi kategorilerimize eşler (ikon için).
  static String _categoryForGoogleType(String type, String typeLabel) {
    if (type == 'public_bathroom') return 'WC';
    const food = {
      'cafe',
      'cafeteria',
      'coffee_shop',
      'bakery',
      'food',
      'food_store',
      'ice_cream_shop',
      'chocolate_shop',
      'dessert_shop',
    };
    if (food.contains(type) || type.contains('restaurant')) return 'Yemek';
    if (type == 'store' || type.endsWith('_store')) return 'Stant';
    return typeLabel;
  }

  Future<void> startNavigation(
    PointOfInterest destination,
    LatLng userLocation,
  ) async {
    _isNavigating = true;
    _routeDurationSeconds = null;
    _routeSteps = [];
    _stepRouteIndices = [];
    _selectedPoi = destination;

    print(
      'Navigasyon başlatılıyor: ${userLocation.latitude}, ${userLocation.longitude} -> ${destination.latitude}, ${destination.longitude}',
    );

    // Kullanıcı konum marker'ını oluştur
    await _createUserLocationMarker(userLocation);

    final target = LatLng(destination.latitude, destination.longitude);
    try {
      await _getDirections(userLocation, target);
    } catch (e) {
      debugPrint('Navigasyon hatası: $e');

      // Hata durumunda basit düz çizgi çiz
      _createStraightLine(userLocation, target);
    }

    notifyListeners();

    // Rotanın tamamı görünsün (eskiden kullanıcıya 17 zoom + 45° eğimle
    // odaklanıyordu; rotanın çoğu ekran dışında / panelin altında kalıyordu).
    await _fitCameraToRoute(userLocation, target);
  }

  /// Kamerayı rotaya sığdırır. Alttaki navigasyon paneli rotayı kapatmasın
  /// diye sınır güneye doğru genişletilir (rota ekranın üst kısmında kalır).
  Future<void> _fitCameraToRoute(LatLng origin, LatLng destination) async {
    final controller = _controller;
    if (controller == null) return;
    final points = <LatLng>[origin, destination, ..._currentRoutePoints];
    double minLat = points.first.latitude, maxLat = minLat;
    double minLng = points.first.longitude, maxLng = minLng;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final double latSpan = math.max(maxLat - minLat, 0.0008);
    final double lngSpan = math.max(maxLng - minLng, 0.0008);
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latSpan * 0.7, minLng - lngSpan * 0.1),
            northeast: LatLng(maxLat + latSpan * 0.15, maxLng + lngSpan * 0.1),
          ),
          48,
        ),
      );
    } catch (e) {
      debugPrint('Kamera rotaya sığdırılamadı: $e');
    }
  }

  // Yürüme rotası sırası:
  //  1) Google Routes API (WALK) - tüm platformlar (CORS destekli), parkın iç
  //     yollarını en iyi bilen kaynak; Türkçe adım adım talimat verir.
  //  2) OSRM "foot" (OpenStreetMap) - Google'a ulaşılamazsa. Not: OSM'de park
  //     içi yollar eksik olduğundan dolambaçlı rota verebilir.
  //  3) Son çare: kuş uçuşu çizgi.
  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    if (await _tryGoogleRoutes(origin, destination)) return;
    if (await _tryOsrmFootRoute(origin, destination)) return;
    _createStraightLine(origin, destination);
  }

  Future<bool> _tryGoogleRoutes(LatLng origin, LatLng destination) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              'https://routes.googleapis.com/directions/v2:computeRoutes',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask':
                  'routes.duration,routes.polyline.encodedPolyline,'
                  'routes.legs.endLocation,'
                  'routes.legs.steps.navigationInstruction,'
                  'routes.legs.steps.distanceMeters,'
                  'routes.legs.steps.startLocation',
            },
            body: json.encode({
              'origin': {
                'location': {
                  'latLng': {
                    'latitude': origin.latitude,
                    'longitude': origin.longitude,
                  },
                },
              },
              'destination': {
                'location': {
                  'latLng': {
                    'latitude': destination.latitude,
                    'longitude': destination.longitude,
                  },
                },
              },
              'travelMode': 'WALK',
              'languageCode': 'tr',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('Routes HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
      final routes =
          (json.decode(response.body) as Map<String, dynamic>)['routes']
              as List?;
      if (routes == null || routes.isEmpty) return false;
      final route = routes.first as Map<String, dynamic>;
      final String? encoded =
          (route['polyline'] as Map?)?['encodedPolyline'] as String?;
      if (encoded == null) return false;
      // Süre "818s" biçiminde gelir.
      _routeDurationSeconds = int.tryParse(
        ((route['duration'] as String?) ?? '').replaceAll('s', ''),
      );
      if (!_createPolyline(encoded)) return false;
      _setRouteSteps(_parseGoogleRoutesSteps(route));
      return true;
    } catch (e) {
      debugPrint('Google Routes rotası alınamadı: $e');
      return false;
    }
  }

  static IconData _iconForGoogleManeuver(String? maneuver) {
    switch (maneuver) {
      case 'DEPART':
        return Icons.directions_walk;
      case 'TURN_LEFT':
        return Icons.turn_left;
      case 'TURN_RIGHT':
        return Icons.turn_right;
      case 'TURN_SLIGHT_LEFT':
        return Icons.turn_slight_left;
      case 'TURN_SLIGHT_RIGHT':
        return Icons.turn_slight_right;
      case 'TURN_SHARP_LEFT':
        return Icons.turn_sharp_left;
      case 'TURN_SHARP_RIGHT':
        return Icons.turn_sharp_right;
      case 'UTURN_LEFT':
        return Icons.u_turn_left;
      case 'UTURN_RIGHT':
        return Icons.u_turn_right;
      case 'FORK_LEFT':
        return Icons.fork_left;
      case 'FORK_RIGHT':
        return Icons.fork_right;
      case 'ROUNDABOUT_LEFT':
      case 'ROUNDABOUT_RIGHT':
        return Icons.roundabout_left;
      default:
        return Icons.straight;
    }
  }

  // Google Routes adımları: talimat metni zaten Türkçe gelir.
  List<RouteStep> _parseGoogleRoutesSteps(Map<String, dynamic> route) {
    final legs = route['legs'] as List?;
    if (legs == null || legs.isEmpty) return const [];
    final leg = legs.first as Map<String, dynamic>;
    LatLng? latLngOf(Map? loc) {
      final ll = loc?['latLng'] as Map?;
      if (ll == null) return null;
      return LatLng(
        (ll['latitude'] as num).toDouble(),
        (ll['longitude'] as num).toDouble(),
      );
    }

    final steps = <RouteStep>[];
    for (final s
        in ((leg['steps'] as List?) ?? []).cast<Map<String, dynamic>>()) {
      final nav = s['navigationInstruction'] as Map<String, dynamic>?;
      final LatLng? start = latLngOf(s['startLocation'] as Map?);
      if (start == null) continue;
      // Talimat bazen "Sola dönün\nAradığınız yeri solda göreceksiniz" gibi
      // iki satır olur; tek satırda birleştiriyoruz.
      final String text = ((nav?['instructions'] as String?) ?? 'Devam edin')
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .join(' · ');
      steps.add(
        RouteStep(
          instruction: text,
          distanceMeters: ((s['distanceMeters'] as num?) ?? 0).toDouble(),
          icon: _iconForGoogleManeuver(nav?['maneuver'] as String?),
          location: start,
        ),
      );
    }
    final LatLng? end = latLngOf(leg['endLocation'] as Map?);
    if (end != null) {
      steps.add(
        RouteStep(
          instruction: 'Hedefinize ulaştınız',
          distanceMeters: 0,
          icon: Icons.flag,
          location: end,
          isArrival: true,
        ),
      );
    }
    return steps;
  }

  // FOSSGIS'in herkese açık OSRM yaya yönlendirme sunucusu (anahtar gerekmez,
  // hafif/ticari olmayan kullanım içindir).
  static const String _osrmFootBaseUrl =
      'https://routing.openstreetmap.de/routed-foot/route/v1/foot';

  Future<bool> _tryOsrmFootRoute(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      '$_osrmFootBaseUrl/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=polyline&steps=true',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('OSRM HTTP ${response.statusCode}');
        return false;
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (data['code'] != 'Ok' || routes == null || routes.isEmpty) {
        debugPrint('OSRM rota bulunamadı: ${data['code']}');
        return false;
      }
      final route = routes.first as Map<String, dynamic>;
      _routeDurationSeconds = (route['duration'] as num?)?.round();
      // OSRM'in "polyline" geometrisi Google ile aynı (precision 5) kodlamayı
      // kullanır; mevcut çözücü doğrudan çalışır.
      if (!_createPolyline(route['geometry'] as String)) return false;
      _setRouteSteps(_parseOsrmSteps(route));
      return true;
    } catch (e) {
      debugPrint('OSRM yaya rotası alınamadı: $e');
      return false;
    }
  }

  void _createStraightLine(LatLng origin, LatLng destination) {
    print(
      '⚠️ Google Maps rotası alınamadı, düz çizgi çiziliyor: $origin -> $destination',
    );

    _currentRoutePoints = [origin, destination];
    _isFallbackRoute = true;
    _routeDurationSeconds = null;
    _resetRouteProgress();
    _setRoutePolylines(traveled: const [], remaining: _currentRoutePoints);
    _setRouteSteps([
      RouteStep(
        instruction: 'Hedefe doğru ilerleyin (kuş uçuşu)',
        distanceMeters: _routeTotalMeters,
        icon: Icons.near_me,
        location: origin,
      ),
      RouteStep(
        instruction: 'Hedefinize ulaştınız',
        distanceMeters: 0,
        icon: Icons.flag,
        location: destination,
        isArrival: true,
      ),
    ]);

    _buildArrowMarkers(_currentRoutePoints);

    print('🟠 Fallback düz rota çizildi (turuncu kesikli çizgi)');
    notifyListeners();
  }

  /// Rotayı çizer; geçerli (en az 2 noktalı) bir polyline değilse `false`.
  bool _createPolyline(String encodedPolyline) {
    List<LatLng> polylineCoordinates = _decodePolyline(encodedPolyline);
    print(
      '🛤️ Polyline decode edildi: ${polylineCoordinates.length} koordinat noktası',
    );

    if (polylineCoordinates.length < 2) {
      print('⚠️ Polyline boş/yetersiz');
      return false;
    }

    // İlk ve son noktaları log'la
    if (polylineCoordinates.isNotEmpty) {
      print(
        '🚩 İlk nokta: ${polylineCoordinates.first.latitude}, ${polylineCoordinates.first.longitude}',
      );
      print(
        '🏁 Son nokta: ${polylineCoordinates.last.latitude}, ${polylineCoordinates.last.longitude}',
      );
    }

    _currentRoutePoints = polylineCoordinates;
    _isFallbackRoute = false;
    _resetRouteProgress();
    // Henüz yürünmedi: tamamı "kalan rota" olarak canlı renkte çizilir.
    // Kullanıcı hareket ettikçe updateUserLocation -> _updateRouteProgress
    // bu ikiliyi (gidilen/kalan) günceller.
    _setRoutePolylines(traveled: const [], remaining: _currentRoutePoints);
    _buildArrowMarkers(_currentRoutePoints);

    print('✅ Yürüme rotası çizildi!');
    notifyListeners();
    return true;
  }

  // Rotayı "gidilen" (soluk) ve "kalan" (canlı mavi) iki parça olarak çizer -
  // AllTrails/Komoot tarzı breadcrumb görünümü.
  void _setRoutePolylines({
    required List<LatLng> traveled,
    required List<LatLng> remaining,
  }) {
    _polylines.clear();
    if (traveled.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('walking_route_traveled'),
          zIndex: 2,
          points: traveled,
          color: const Color(0xFF3252a8).withValues(alpha: 0.35),
          width: 6,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
    if (remaining.length >= 2) {
      _polylines.add(
        _isFallbackRoute
            // Yürüme rotası alınamadı: kuş uçuşu çizgi, turuncu kesikli
            // gösterilir ki gerçek bir yol tarifi olmadığı belli olsun.
            ? Polyline(
                polylineId: const PolylineId('walking_route_remaining'),
                zIndex: 3,
                points: remaining,
                color: Colors.orange,
                width: 4,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                geodesic: true,
              )
            : Polyline(
                polylineId: const PolylineId('walking_route_remaining'),
                zIndex: 3,
                points: remaining,
                color: const Color(0xFF3252a8),
                width: 6,
                geodesic: true,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
      );
    }
  }

  bool _isFallbackRoute = false;

  void _resetRouteProgress() {
    _routeTotalMeters = _pathLength(_currentRoutePoints);
    _routeRemainingMeters = _routeTotalMeters;
  }

  double _pathLength(List<LatLng> points) {
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _distanceMeters(points[i], points[i + 1]);
    }
    return total;
  }

  // Kullanıcı konumunu rotanın en yakın segmentine izdüşürür. Sadece en yakın
  // köşe noktasına bakmak, az noktalı rotalarda (ör. kuş uçuşu yedek rota)
  // ilerlemeyi hiç ölçemiyordu.
  ({int segment, LatLng point}) _projectOntoRoute(LatLng p) {
    final pts = _currentRoutePoints;
    final double cosLat = math.cos(p.latitude * math.pi / 180);
    int bestSegment = 0;
    LatLng bestPoint = pts.first;
    double bestDistance = double.infinity;
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      // Kısa mesafelerde yeterli düzlemsel yaklaşım (boylam cos(enlem) ile ölçeklenir).
      final double dx = (b.longitude - a.longitude) * cosLat;
      final double dy = b.latitude - a.latitude;
      final double len2 = dx * dx + dy * dy;
      double t = len2 == 0
          ? 0
          : (((p.longitude - a.longitude) * cosLat) * dx +
                    (p.latitude - a.latitude) * dy) /
                len2;
      t = t.clamp(0.0, 1.0);
      final projected = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final double d = _distanceMeters(p, projected);
      if (d < bestDistance) {
        bestDistance = d;
        bestSegment = i;
        bestPoint = projected;
      }
    }
    return (segment: bestSegment, point: bestPoint);
  }

  // Kullanıcının rota üzerindeki konumunu bulup rotayı gidilen/kalan olarak
  // yeniden böler ve kalan mesafeyi günceller. updateUserLocation çağırır.
  void _updateRouteProgress(LatLng currentLocation) {
    if (_currentRoutePoints.length < 2) return;

    final projection = _projectOntoRoute(currentLocation);
    final traveled = [
      ..._currentRoutePoints.sublist(0, projection.segment + 1),
      projection.point,
    ];
    final remaining = [
      projection.point,
      ..._currentRoutePoints.sublist(projection.segment + 1),
    ];
    _routeRemainingMeters = _pathLength(remaining);
    _setRoutePolylines(traveled: traveled, remaining: remaining);
    _updateNextStep(projection.segment, projection.point);
  }

  void _setRouteSteps(List<RouteStep> steps) {
    _routeSteps = steps;
    // Her adımı rota üzerindeki en yakın noktaya eşle (sıradaki adımı bulmak için).
    _stepRouteIndices = [
      for (final step in steps) _nearestRouteIndex(step.location),
    ];
    _nextStepIndex = steps.length > 1 ? 1 : 0;
    _distanceToNextStep = steps.isNotEmpty ? steps.first.distanceMeters : 0;
    notifyListeners();
  }

  int _nearestRouteIndex(LatLng p) {
    int best = 0;
    double bestD = double.infinity;
    for (int i = 0; i < _currentRoutePoints.length; i++) {
      final double d = _distanceMeters(p, _currentRoutePoints[i]);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  // Kullanıcının izdüşümünden sonra gelen ilk manevrayı ve ona kalan mesafeyi bulur.
  void _updateNextStep(int segment, LatLng projectedPoint) {
    if (_routeSteps.isEmpty) return;
    int next = _routeSteps.length - 1; // bulunamazsa varış adımı
    for (int i = 1; i < _routeSteps.length; i++) {
      if (_stepRouteIndices[i] > segment) {
        next = i;
        break;
      }
    }
    _nextStepIndex = next;
    final int target = _stepRouteIndices[next];
    _distanceToNextStep = target <= segment
        ? 0
        : _distanceMeters(projectedPoint, _currentRoutePoints[segment + 1]) +
              _pathLength(_currentRoutePoints.sublist(segment + 1, target + 1));
  }

  // OSRM adımlarını Türkçe talimatlara çevirir. Patikalarda sık görülen
  // "isim değişti / düz devam" adımları bir önceki adıma eklenir (gürültü olmasın).
  List<RouteStep> _parseOsrmSteps(Map<String, dynamic> route) {
    final legs = route['legs'] as List?;
    if (legs == null || legs.isEmpty) return const [];
    final raw = ((legs.first as Map<String, dynamic>)['steps'] as List?) ?? [];
    final steps = <RouteStep>[];
    for (final s in raw.cast<Map<String, dynamic>>()) {
      final m = s['maneuver'] as Map<String, dynamic>;
      final String type = m['type'] as String? ?? 'turn';
      final String? modifier = m['modifier'] as String?;
      final double distance = (s['distance'] as num?)?.toDouble() ?? 0;
      final bool minor =
          (type == 'new name' ||
              type == 'continue' ||
              type == 'notification') &&
          (modifier == null || modifier == 'straight');
      if (minor && steps.isNotEmpty) {
        final prev = steps.removeLast();
        steps.add(
          RouteStep(
            instruction: prev.instruction,
            distanceMeters: prev.distanceMeters + distance,
            icon: prev.icon,
            location: prev.location,
            isArrival: prev.isArrival,
          ),
        );
        continue;
      }
      final loc = (m['location'] as List).cast<num>(); // [lng, lat]
      final d = OsrmInstructions.describe(
        type: type,
        modifier: modifier,
        name: s['name'] as String?,
        exit: (m['exit'] as num?)?.toInt(),
      );
      steps.add(
        RouteStep(
          instruction: d.text,
          distanceMeters: distance,
          icon: d.icon,
          location: LatLng(loc[1].toDouble(), loc[0].toDouble()),
          isArrival: d.isArrival,
        ),
      );
    }
    return steps;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  // İki nokta arasındaki pusula yönünü (0-360, Kuzey=0) hesaplar.
  double _bearingBetween(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLng = (end.longitude - start.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  // Rota boyunca belirli aralıklarla yön oku marker'ları yerleştirir.
  Future<void> _buildArrowMarkers(List<LatLng> routePoints) async {
    _routeArrowMarkers = {};
    if (routePoints.length < 2) {
      notifyListeners();
      return;
    }

    // Çok sık ok koymamak için rotayı ~8 eşit parçaya böl (en fazla 7 ok).
    const maxArrows = 7;
    final step = (routePoints.length / (maxArrows + 1)).ceil().clamp(
      1,
      routePoints.length - 1,
    );

    final newArrows = <Marker>{};
    for (int i = step; i < routePoints.length - 1; i += step) {
      final from = routePoints[i - 1];
      final to = routePoints[i + 1 < routePoints.length ? i + 1 : i];
      final bearing = _bearingBetween(from, to);
      final icon = await _getArrowIcon(bearing);
      newArrows.add(
        Marker(
          markerId: MarkerId('route_arrow_$i'),
          position: routePoints[i],
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 500,
        ),
      );
    }

    _routeArrowMarkers = newArrows;
    notifyListeners();
  }

  // Aynı yöne yakın oklar için bitmap'i yeniden üretmemek üzere 15°'lik
  // kovalara yuvarlayıp cache'ler.
  Future<BitmapDescriptor> _getArrowIcon(double bearingDegrees) async {
    final bucket = (bearingDegrees / 15).round() % 24;
    if (_arrowIconCache.containsKey(bucket)) {
      return _arrowIconCache[bucket]!;
    }
    final icon = await _createDirectionArrowIcon(bucket * 15.0);
    _arrowIconCache[bucket] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _createDirectionArrowIcon(
    double bearingDegrees,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 22.0;
    const center = size / 2;

    canvas.translate(center, center);
    canvas.rotate(bearingDegrees * math.pi / 180);
    canvas.translate(-center, -center);

    final fillPaint = Paint()..color = const Color(0xFF3252a8);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Kuzeye (yukarı) bakan bir ok ucu - canvas zaten bearing kadar döndürüldü.
    final path = Path()
      ..moveTo(center, 2)
      ..lineTo(size - 4, size - 4)
      ..lineTo(center, size - 9)
      ..lineTo(4, size - 4)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
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
      // NOT: `~x` yerine `-x - 1` (eşdeğer). Web'de (dart2js) bit işlemleri
      // işaretsiz 32-bit sonuç verdiği için `~` negatif delta yerine ~4 milyar
      // döndürüyor ve rota noktaları kutuplara kaçıyordu.
      int dlat = (result & 1) != 0 ? -(result >> 1) - 1 : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? -(result >> 1) - 1 : (result >> 1);
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
          .where(
            (poi) =>
                poi.name.toLowerCase().contains(query.toLowerCase()) ||
                poi.category.toLowerCase().contains(query.toLowerCase()) ||
                poi.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _polylines.clear();
    _currentRoutePoints = [];
    _routeArrowMarkers = {};
    _routeTotalMeters = 0;
    _routeRemainingMeters = 0;
    _routeDurationSeconds = null;
    _isFallbackRoute = false;
    _routeSteps = [];
    _stepRouteIndices = [];
    _nextStepIndex = 0;
    _distanceToNextStep = 0;
    _selectedPoi = null;
    _customDestinationMarker = null;
    // Kullanıcı konum noktası (mavi nokta) navigasyon bitince de kalır.
    notifyListeners();
  }

  // Kullanıcı konum marker'ı oluştur
  Future<void> _createUserLocationMarker(LatLng userLocation) async {
    // Kareler bir kez çizilir; her konum güncellemesinde yeniden üretilmez.
    _userPulseFrames ??= await _createUserPulseFrames();
    _userLocation = userLocation;
    _buildUserMarker();
    _startUserPulse();
  }

  void _buildUserMarker() {
    final frames = _userPulseFrames;
    final location = _userLocation;
    if (frames == null || location == null) return;
    _userLocationMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: location,
      icon: frames[_userPulseFrame % frames.length],
      // Nokta, konumun tam üstünde ortalansın (varsayılan alt-orta).
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 1000, // En üstte görünsün
    );
  }

  /// Hafif "kalp ritmi": noktanın etrafında soluk bir halka büyüyüp kaybolur,
  /// ardından kısa bir duraklama (~1,7 sn'lik döngü).
  void _startUserPulse() {
    if (_userPulseTimer != null) return;
    _userPulseTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (_userLocation == null) return;
      _userPulseFrame = (_userPulseFrame + 1) % _userPulseFrames!.length;
      _buildUserMarker();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userPulseTimer?.cancel();
    super.dispose();
  }

  static const int _pulseGrowFrames = 10;
  static const int _pulsePauseFrames = 4;

  Future<List<BitmapDescriptor>> _createUserPulseFrames() async {
    final frames = <BitmapDescriptor>[];
    for (int i = 0; i < _pulseGrowFrames + _pulsePauseFrames; i++) {
      // Duraklama karelerinde halka yok (t = null).
      final double? t = i < _pulseGrowFrames ? i / (_pulseGrowFrames - 1) : null;
      frames.add(await _createUserLocationIcon(t));
    }
    return frames;
  }

  // Kullanıcı konum icon'u oluştur. [pulse]: 0..1 halka ilerlemesi
  // (null = halka yok).
  Future<BitmapDescriptor> _createUserLocationIcon(double? pulse) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // 3x çözünürlükte çizilip 44x44 mantıksal piksel olarak gösterilir:
    // fromBytes ölçeklemediği için Android'de nokta çok küçük çıkıyordu.
    const double logicalSize = 44.0;
    const double scale = 3.0;
    const double size = logicalSize * scale;
    const double center = size / 2;
    const Color brand = Color(0xFF3252a8);

    // Sabit, soluk zemin halesi
    canvas.drawCircle(
      const Offset(center, center),
      14 * scale,
      Paint()..color = brand.withValues(alpha: 0.18),
    );

    // Kalp ritmi halkası: 12 -> 21 px büyür, opaklık 0.5 -> 0 söner.
    if (pulse != null) {
      final double eased = 1 - math.pow(1 - pulse, 2).toDouble();
      canvas.drawCircle(
        const Offset(center, center),
        (12 + 9 * eased) * scale,
        Paint()
          ..color = brand.withValues(alpha: 0.5 * (1 - pulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * scale,
      );
    }

    // Beyaz kenar + mavi nokta
    canvas.drawCircle(
      const Offset(center, center),
      10 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      const Offset(center, center),
      7 * scale,
      Paint()..color = brand,
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: logicalSize,
      height: logicalSize,
    );
  }

  /// Kullanıcının gerçek konumunu haritada mavi nokta olarak gösterir
  /// (Android, iOS ve web'de aynı). Navigasyon sırasında rota ilerlemesini de
  /// günceller. Haritanın kendi "my location" katmanı kullanılmıyor: web'de
  /// desteklenmiyor, Android'de izin harita açıldıktan sonra verilirse
  /// görünmüyordu.
  void updateUserLocation(LatLng newLocation) {
    if (_isNavigating) _updateRouteProgress(newLocation);
    _createUserLocationMarker(newLocation).then((_) {
      notifyListeners();
      if (_isNavigating) _keepUserInView(newLocation);
    });
  }

  /// Kullanıcı görünen alanın dışına çıktıysa kamerayı ona getirir. Eskiden
  /// her güncellemede kamera kullanıcıya kilitleniyordu; navigasyon sırasında
  /// harita kaydırılamıyor / yakınlaştırılamıyordu.
  Future<void> _keepUserInView(LatLng location) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final LatLngBounds visible = await controller.getVisibleRegion();
      if (!visible.contains(location)) {
        await controller.animateCamera(CameraUpdate.newLatLng(location));
      }
    } catch (_) {
      // Harita henüz hazır değil; bir sonraki güncellemede tekrar denenir.
    }
  }

  /// Kamerayı etkinlik alanına odaklar (sınır yoksa Millet Bahçesi geneli).
  void centerOnMilletBahcesi() {
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(currentEvent.center, currentEvent.initialZoom),
    );
  }
}
