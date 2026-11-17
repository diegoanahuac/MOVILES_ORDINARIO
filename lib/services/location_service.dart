import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/errors/app_exception.dart';

/// Coordenadas capturadas al guardar una entrada.
class Ubicacion {
  final double latitud;
  final double longitud;
  final double precision;
  const Ubicacion(this.latitud, this.longitud, this.precision);
}

/// Gadget de geolocalización: GPS actual y apertura en Google Maps.
abstract interface class LocationService {
  Future<Ubicacion> obtenerActual();
  Future<void> abrirEnGoogleMaps(double latitud, double longitud);
}

class LocationServiceGeolocator implements LocationService {
  @override
  Future<Ubicacion> obtenerActual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppException(
            'Activa los Servicios de localización del iPhone para guardar la ubicación.');
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw const PermisoDenegadoException(
            'Permite la ubicación en Ajustes > Huellas para guardar dónde estabas.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Ubicacion(pos.latitude, pos.longitude, pos.accuracy);
    } on AppException {
      rethrow;
    } catch (e) {
      // Si el GPS tarda demasiado se usa la última posición conocida.
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) {
        return Ubicacion(ultima.latitude, ultima.longitude, ultima.accuracy);
      }
      throw AppException('No se pudo obtener tu ubicación.', e);
    }
  }

  @override
  Future<void> abrirEnGoogleMaps(double latitud, double longitud) async {
    // Si la app de Google Maps está instalada se abre ahí; si no, en Safari.
    final app = Uri.parse('comgooglemaps://?q=$latitud,$longitud&zoom=16');
    final web = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud');
    try {
      if (await canLaunchUrl(app)) {
        await launchUrl(app);
      } else if (!await launchUrl(web, mode: LaunchMode.externalApplication)) {
        throw const AppException('No se pudo abrir Google Maps.');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo abrir Google Maps.', e);
    }
  }
}
