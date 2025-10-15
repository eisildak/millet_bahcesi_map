import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

class LocationService extends ChangeNotifier {
  geolocator.Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  bool _isTracking = false;
  StreamSubscription<geolocator.Position>? _positionStream;
  
  geolocator.Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTracking => _isTracking;

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
      print('Konum hatası detayı: $e');
      
      if (kIsWeb) {
        // Web'de hata durumunda varsayılan konum kullan
        _currentPosition = geolocator.Position(
          latitude: 38.704200, // Kayseri Millet Bahçesi doğru koordinat
          longitude: 35.509500,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        _error = 'Web tarayıcısında konum alınamadı, varsayılan konum gösteriliyor';
        print('Web için varsayılan konum kullanıldı');
      } else {
        // Mobil'de son bilinen konumu dene
        _error = 'Konum alınamadı: $e';
        try {
          _currentPosition = await geolocator.Geolocator.getLastKnownPosition();
          if (_currentPosition != null) {
            _error = 'GPS bulunamadı, son bilinen konum kullanılıyor';
            print('Son bilinen konum kullanıldı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
          }
        } catch (lastPositionError) {
          print('Son konum da alınamadı: $lastPositionError');
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getLocationForWeb() async {
    print('Web platformu için konum alınıyor...');
    
    // Web'de direkt konum almayı dene, izin sorunu varsa handle et
    try {
      // Web'de daha basit approach - sadece getCurrentPosition
      _currentPosition = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );
      print('Web konum başarıyla alındı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      _error = null; // Başarılı olursa hata temizle
      
    } catch (e) {
      print('Web konum alma hatası: $e');
      
      // Varsayılan konumu kullan ve kullanıcıya bildirme
      _currentPosition = geolocator.Position(
        latitude: 38.704200, // Kayseri Millet Bahçesi doğru koordinat
        longitude: 35.509500,
        timestamp: DateTime.now(),
        accuracy: 1000.0, // Düşük accuracy belirt
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      
      // Hatayı kullanıcı dostu yap
      if (e.toString().contains('denied')) {
        _error = null; // Hata gösterme, varsayılan konum kullan
        print('Konum izni reddedildi, varsayılan konum kullanılıyor');
      } else if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        _error = null; // Hata gösterme, varsayılan konum kullan
        print('Konum alma zaman aşımı, varsayılan konum kullanılıyor');
      } else {
        _error = null; // Hata gösterme, varsayılan konum kullan
        print('Web için varsayılan konum kullanıldı: ${e.runtimeType}');
      }
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

  // Konum takibini başlat
  Future<void> startLocationTracking() async {
    if (_isTracking) return;
    
    print('Konum takibi başlatılıyor...');
    _isTracking = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        await _startWebLocationTracking();
      } else {
        await _startMobileLocationTracking();
      }
    } catch (e) {
      print('Konum takibi başlatma hatası: $e');
      _error = 'Konum takibi başlatılamadı: $e';
      _isTracking = false;
      notifyListeners();
    }
  }

  // Konum takibini durdur
  void stopLocationTracking() {
    if (!_isTracking) return;
    
    print('Konum takibi durduruluyor...');
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _startWebLocationTracking() async {
    // Web'de periyodik konum güncellemesi
    print('Web için konum takibi başlatılıyor...');
    
    // İlk konum al
    await getCurrentLocation();
    
    // Her 5 saniyede bir konum güncelle
    _startPeriodicLocationUpdate();
  }

  Future<void> _startMobileLocationTracking() async {
    // Mobil'de gerçek zamanlı konum takibi
    print('Mobil için konum takibi başlatılıyor...');
    
    // İzin kontrol et
    await _requestLocationPermission();
    
    const locationSettings = geolocator.LocationSettings(
      accuracy: geolocator.LocationAccuracy.high,
      distanceFilter: 5, // 5 metre değişiklikte güncelle
    );

    _positionStream = geolocator.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (geolocator.Position position) {
        print('Yeni konum: ${position.latitude}, ${position.longitude}');
        _currentPosition = position;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        print('Konum takibi hatası: $error');
        _error = 'Konum takibi hatası: $error';
        notifyListeners();
      },
    );
  }

  void _startPeriodicLocationUpdate() {
    if (!kIsWeb || !_isTracking) return;
    
    Future.delayed(const Duration(seconds: 5), () async {
      if (!_isTracking) return;
      
      try {
        await getCurrentLocation();
        _startPeriodicLocationUpdate(); // Recursive call for continuous tracking
      } catch (e) {
        print('Periyodik konum güncelleme hatası: $e');
      }
    });
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

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}