import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

class LocationService extends ChangeNotifier {
  geolocator.Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  
  geolocator.Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Platform kontrolü
      if (kIsWeb) {
        await _getLocationForWeb();
      } else {
        await _getLocationForMobile();
      }
      
    } catch (e) {
      _error = 'Konum alınamadı: $e';
      print('Konum hatası detayı: $e');
      
      // Son bilinen konumu deneyerek hatayı azaltmaya çalışalım
      try {
        _currentPosition = await geolocator.Geolocator.getLastKnownPosition();
        if (_currentPosition != null) {
          _error = null; // Hata temizle
          print('Son bilinen konum kullanıldı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
        }
      } catch (lastPositionError) {
        print('Son konum da alınamadı: $lastPositionError');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getLocationForWeb() async {
    print('Web platformu için konum alınıyor...');
    
    // Web'de önce izin kontrol et
    await _requestLocationPermission();
    
    // Web'de konum servisi kontrolü farklı
    try {
      _currentPosition = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      print('Web konum alındı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    } catch (e) {
      print('Web konum hatası: $e');
      // Web'de son konum bilgisi genelde çalışmaz
      rethrow;
    }
  }

  Future<void> _getLocationForMobile() async {
    print('Mobil platform için konum alınıyor...');
    
    // Önce konum iznini kontrol et ve iste
    await _requestLocationPermission();
    
    // Konum servislerinin aktif olup olmadığını kontrol et
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Konum servisleri kapalı - Lütfen cihaz ayarlarından konum servisini açın';
      throw Exception(_error);
    }

    // Daha uzun timeout ve farklı accuracy ile deneyelim
    try {
      _currentPosition = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );
      print('Konum alındı (best): ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    } catch (timeoutError) {
      // Eğer best accuracy ile timeout olursa, low accuracy ile tekrar deneyelim
      print('Best accuracy timeout, trying low accuracy...');
      _currentPosition = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.low,
        timeLimit: const Duration(seconds: 15),
      );
      print('Konum alındı (low): ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
    }
  }

  Future<void> _requestLocationPermission() async {
    // Geolocator ile konum izni kontrolü
    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    print('Mevcut konum izni: $permission');
    
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      print('İzin istendi, sonuç: $permission');
    }
    
    if (permission == geolocator.LocationPermission.deniedForever) {
      _error = 'Konum izni kalıcı olarak reddedildi - Lütfen cihaz ayarlarından uygulamaya konum izni verin';
      print('Konum izni kalıcı olarak reddedildi');
      throw Exception(_error);
    }

    if (permission == geolocator.LocationPermission.denied) {
      _error = 'Konum izni reddedildi - Uygulama çalışması için konum izni gerekli';
      print('Konum izni reddedildi');
      throw Exception(_error);
    }

    print('Konum izni onaylandı: $permission');
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return geolocator.Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<bool> checkLocationPermission() async {
    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == geolocator.LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Test için varsayılan konum set etme
  void setTestLocation(double latitude, double longitude) {
    _currentPosition = geolocator.Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    _error = null;
    notifyListeners();
  }
}