import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
          'Layanan lokasi belum aktif. Aktifkan GPS/lokasi terlebih dahulu.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi dari pengaturan aplikasi.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  double distanceInKm({
    required double userLatitude,
    required double userLongitude,
    required double venueLatitude,
    required double venueLongitude,
  }) {
    final distanceInMeters = Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      venueLatitude,
      venueLongitude,
    );

    return distanceInMeters / 1000;
  }

  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m dari kamu';
    }

    return '${distanceKm.toStringAsFixed(1)} km dari kamu';
  }
}
