import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  String? _currentAddress;
  String _currentLocality = 'Jaipur, Rajasthan';
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String get currentLocality => _currentLocality;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;

  LocationProvider() {
    // Auto initialize location detection on app start
    initLocation();
  }

  Future<void> initLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loc = await _locationService.getLiveLocationDetails();
      if (loc != null) {
        _currentPosition = Position(
          longitude: loc.longitude,
          latitude: loc.latitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _currentAddress = loc.address;
        if (loc.address != null && loc.address!.isNotEmpty) {
          // Extract short locality name e.g. "Malviya Nagar, Jaipur"
          final parts = loc.address!.split(',').map((s) => s.trim()).toList();
          if (parts.length >= 2) {
            _currentLocality = '${parts[0]}, ${parts[1]}';
          } else {
            _currentLocality = parts.first;
          }
        }
        _hasPermission = true;
      } else {
        _hasPermission = false;
        _errorMessage = 'GPS / Location is off or permission denied';
      }
    } catch (e) {
      debugPrint('[LocationProvider] Error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    await initLocation();
  }
}
