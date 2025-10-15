import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:location/location.dart';

class LocationService extends ChangeNotifier {
  geolocator.Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  
  final Location _location = Location();

  geolocator.Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Önce konum iznini kontrol et ve iste
      await _requestLocationPermission();
      
      // Konum servislerinin aktif olup olmadığını kontrol et
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _error = 'Konum servisleri devre dışı - Lütfen ayarlardan konum servisini açın';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Mevcut konumu al (daha hızlı için medium accuracy)
      _currentPosition = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('Konum alındı: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      
    } catch (e) {
      _error = 'Konum alınamadı: $e';
      print('Konum hatası: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _requestLocationPermission() async {
    // İlk olarak geolocator ile kontrol et
    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
    }
    
    if (permission == geolocator.LocationPermission.deniedForever) {
      _error = 'Konum izni kalıcı olarak reddedildi - Lütfen ayarlardan izin verin';
      return;
    }

    if (permission == geolocator.LocationPermission.denied) {
      _error = 'Konum izni gerekli - Lütfen izin verin';
      return;
    }

    // İkinci olarak location paketi ile de kontrol et
    PermissionStatus locationPermission = await _location.hasPermission();
    if (locationPermission == PermissionStatus.denied) {
      locationPermission = await _location.requestPermission();
      if (locationPermission != PermissionStatus.granted) {
        _error = 'Konum izni reddedildi - Navigasyon için konum izni gerekli';
        return;
      }
    }
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
}