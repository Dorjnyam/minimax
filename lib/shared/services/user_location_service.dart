import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

typedef LocationOverride = Future<({double lat, double lng})?> Function();

/// Channel implemented in [MainActivity] — avoids relying on `geolocator_android`
/// registration (fixes [MissingPluginException] after hot reload / some engines).
const _androidLocationChannel = MethodChannel('baigalaa/location');

/// Resolves the device position for WebSocket payloads (`location: { lat, lng }`).
class UserLocationService {
  UserLocationService({LocationOverride? override}) : _override = override;

  final LocationOverride? _override;

  /// Returns `null` if services are off, permission denied, lookup fails, or unsupported.
  Future<({double lat, double lng})?> getCurrent() async {
    final override = _override;
    if (override != null) {
      return override();
    }

    if (!kIsWeb && Platform.isAndroid) {
      return _getCurrentAndroidEmbedded();
    }

    return _getCurrentGeolocator();
  }

  Future<({double lat, double lng})?> _getCurrentAndroidEmbedded() async {
    try {
      final raw = await _androidLocationChannel.invokeMethod<dynamic>('getCurrent');
      if (raw is Map) {
        final lat = (raw['lat'] as num?)?.toDouble();
        final lng = (raw['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          if (kDebugMode) {
            debugPrint('[Baigalaa GPS] Android (Play Services) lat=$lat lng=$lng');
          }
          return (lat: lat, lng: lng);
        }
      }
      if (kDebugMode) {
        debugPrint('[Baigalaa GPS] Android channel returned null (denied, GPS off, or no fix)');
      }
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[Baigalaa GPS] Android channel PlatformException: $e — trying Geolocator');
      }
      return _getCurrentGeolocator();
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        debugPrint('[Baigalaa GPS] Android channel MissingPluginException: $e — trying Geolocator');
      }
      return _getCurrentGeolocator();
    }
  }

  Future<({double lat, double lng})?> _getCurrentGeolocator() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (kDebugMode) {
        debugPrint('[Baigalaa GPS] Geolocator permission → $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final servicesOn = await Geolocator.isLocationServiceEnabled();
      if (kDebugMode) {
        debugPrint('[Baigalaa GPS] system location services on: $servicesOn');
      }
      if (!servicesOn) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 20));
      if (kDebugMode) {
        debugPrint(
          '[Baigalaa GPS] Geolocator OK lat=${position.latitude} lng=${position.longitude}',
        );
      }
      return (lat: position.latitude, lng: position.longitude);
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('[Baigalaa GPS] getCurrentPosition timed out (20s): $e');
      }
      return null;
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Baigalaa GPS] Geolocator MissingPluginException: $e — '
          'do a full restart (stop app, `flutter run`), not hot reload.',
        );
      }
      return null;
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Baigalaa GPS] error: $e');
        debugPrint('$st');
      }
      return null;
    }
  }
}
