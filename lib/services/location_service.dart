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
      // Konum servislerinin aktif olup olmadığını kontrol et
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _error = 'Konum servisleri devre dışı';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Konum izni kontrol et
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _error = 'Konum izni reddedildi';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Mevcut konumu al
      _currentPosition = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      
    } catch (e) {
      _error = 'Konum alınamadı: $e';
    }

    _isLoading = false;
    notifyListeners();
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