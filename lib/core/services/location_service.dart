import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/api_constants.dart';

class GeofenceResult {
  final bool isInside;
  final double distanceMeters;
  final double allowedRadiusMeters;
  final double latitude;
  final double longitude;
  final bool isMocked;
  final String? errorMessage;

  GeofenceResult({
    required this.isInside,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    required this.latitude,
    required this.longitude,
    this.isMocked = false,
    this.errorMessage,
  });
}

class LocationService {
  // Haversine Formülü ile Dünya üzerindeki iki koordinat arasındaki metre cinsinden mesafe
  static double calculateDistanceInMeters(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * (pi / 180.0);

  // Cihaz konumunu al ve ofis Geofence sınırını doğrula
  static Future<GeofenceResult> verifyOfficeGeofence({
    double officeLat = ApiConstants.defaultOfficeLat,
    double officeLng = ApiConstants.defaultOfficeLng,
    double allowedRadius = ApiConstants.defaultAllowedRadiusMeters,
  }) async {
    try {
      if (kIsWeb) {
        // Web ortamında geolocator tarayıcı konum API'sini kullanır
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return GeofenceResult(
            isInside: false,
            distanceMeters: 99999,
            allowedRadiusMeters: allowedRadius,
            latitude: 0,
            longitude: 0,
            errorMessage: 'Konum servisi tarayıcıda kapalı.',
          );
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeofenceResult(
            isInside: false,
            distanceMeters: 99999,
            allowedRadiusMeters: allowedRadius,
            latitude: 0,
            longitude: 0,
            errorMessage: 'Konum izni reddedildi. PDKS için konum izni zorunludur.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeofenceResult(
          isInside: false,
          distanceMeters: 99999,
          allowedRadiusMeters: allowedRadius,
          latitude: 0,
          longitude: 0,
          errorMessage: 'Konum izni kalıcı olarak engellenmiş. Lütfen ayarlardan izin verin.',
        );
      }

      // Yüksek doğrulukla anlık GPS konumunu al
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Anti-Cheat: Sahte Konum (Fake GPS) Kontrolü
      if (position.isMocked) {
        return GeofenceResult(
          isInside: false,
          distanceMeters: 99999,
          allowedRadiusMeters: allowedRadius,
          latitude: position.latitude,
          longitude: position.longitude,
          isMocked: true,
          errorMessage: 'UYARI: Sahte GPS (Mock Location) tespit edildi! İşlem engellendi.',
        );
      }

      final distance = calculateDistanceInMeters(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );

      final isInside = distance <= allowedRadius;

      return GeofenceResult(
        isInside: isInside,
        distanceMeters: distance,
        allowedRadiusMeters: allowedRadius,
        latitude: position.latitude,
        longitude: position.longitude,
        isMocked: false,
        errorMessage: isInside
            ? null
            : 'Ofis sınırları dışındasınız (${distance.toStringAsFixed(0)} metre uzaklıkta, izin verilen: ${allowedRadius.toStringAsFixed(0)} m).',
      );
    } catch (e) {
      // Hata durumunda güvenli fallback
      return GeofenceResult(
        isInside: false,
        distanceMeters: 99999,
        allowedRadiusMeters: allowedRadius,
        latitude: 0,
        longitude: 0,
        errorMessage: 'Konum alınamadı: $e',
      );
    }
  }
}
