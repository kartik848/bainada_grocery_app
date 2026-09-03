import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LocationDataResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;

  const LocationDataResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.pinCode,
  });

  String get coordinatesString =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String get navigationUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Determine the current position of the device.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '[LocationService] Location permissions are permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] Error fetching GPS position: $e');
      try {
        // Fallback with low accuracy if high accuracy timed out
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Reverse geocode coordinates into a human-readable Indian street address
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'BainadaBrothersGroceryApp/1.0 (support@bainada.com)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['address'] != null) {
          final addr = data['address'] as Map;
          final parts = <String>[];

          final road = addr['road'] ?? addr['street'] ?? addr['pedestrian'];
          if (road != null) parts.add(road.toString());

          final subLocality = addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'];
          if (subLocality != null) parts.add(subLocality.toString());

          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'];
          if (city != null) parts.add(city.toString());

          final state = addr['state'];
          if (state != null) parts.add(state.toString());

          final postcode = addr['postcode'];
          if (postcode != null) parts.add(postcode.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
          if (data['display_name'] != null) {
            return data['display_name'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode error: $e');
    }
    return null;
  }

  /// Get comprehensive live location data (Coordinates + Human readable address)
  Future<LocationDataResult?> getLiveLocationDetails() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final address = await getAddressFromCoordinates(position.latitude, position.longitude);

    return LocationDataResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  /// Direct launch of Turn-by-Turn Navigation on Google Maps using exact coordinates
  static Future<bool> openGoogleMapsNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationTitle,
  }) async {
    final lat = destinationLat;
    final lng = destinationLng;
    final title = destinationTitle ?? 'Merchant Delivery Location';
    debugPrint('[LocationService] Opening Google Maps for coordinates: $lat, $lng ($title)');

    // 1. Android geo: URI with pin & label (Most reliable on Android devices)
    try {
      final geoUri = Uri.parse(
        'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(title)})',
      );
      if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('[LocationService] geo intent error: $e');
    }

    // 2. Google Maps Native Navigation intent
    try {
      final navIntentUri = Uri.parse(
        'google.navigation:q=$lat,$lng&mode=d',
      );
      if (await launchUrl(navIntentUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('[LocationService] google.navigation error: $e');
    }

    // 3. Web Driving Directions Mode
    try {
      final navUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );
      if (await launchUrl(navUrl, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('[LocationService] maps.google.com/dir error: $e');
    }

    // 4. Fallback search coordinate URL
    try {
      final searchUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      if (await launchUrl(searchUrl, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('[LocationService] maps search error: $e');
    }

    return false;
  }

  /// Launch Google Maps for textual address / shop name when coordinates are not available
  static Future<bool> openGoogleMapsForAddress(String address, {String? title}) async {
    final queryText = title != null && title.isNotEmpty ? '$title, $address' : address;
    final encoded = Uri.encodeComponent(queryText);
    debugPrint('[LocationService] Opening Google Maps for address: $queryText');

    try {
      final geoUri = Uri.parse('geo:0,0?q=$encoded');
      if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}

    try {
      final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
      if (await launchUrl(webUrl, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (_) {}

    return false;
  }
}
