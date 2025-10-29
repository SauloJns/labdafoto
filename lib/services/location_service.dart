import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService instance = LocationService._init();
  LocationService._init();

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Serviço de localização desabilitado');
      return false;
    }

    PermissionStatus status = await Permission.location.request();
    
    if (status.isDenied) {
      print('⚠️ Permissão de localização negada');
      return false;
    }
    
    if (status.isPermanentlyDenied) {
      print('⚠️ Permissão de localização negada permanentemente');
      await openAppSettings();
      return false;
    }

    print('✅ Permissão de localização concedida');
    return status.isGranted;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      return null;
    }
  }

  double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String formatCoordinates(double lat, double lon) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final List<String?> parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((p) => p != null && p!.isNotEmpty).take(3).toList();
        
        return parts.join(', ');
      }
    } catch (e) {
      print('❌ Erro ao obter endereço: $e');
    }
    return null;
  }

  Future<Location?> getLocationFromAddress(String address) async {
    try {
      final List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
    } catch (e) {
      print('❌ Erro ao buscar endereço: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    try {
      final Position? position = await getCurrentLocation();
      if (position == null) return null;

      final String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return {
        'position': position,
        'address': address ?? 'Endereço não disponível',
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('❌ Erro: $e');
      return null;
    }
  }
}