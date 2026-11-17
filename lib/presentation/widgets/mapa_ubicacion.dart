import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';

/// Marcador para el mapa.
class PuntoMapa {
  final LatLng posicion;
  final VoidCallback? alTocar;
  const PuntoMapa(this.posicion, {this.alTocar});
}

/// Mapa interactivo (OpenStreetMap) con uno o varios marcadores.
/// No requiere clave de API, a diferencia del SDK de Google Maps.
class MapaUbicacion extends StatelessWidget {
  const MapaUbicacion({
    super.key,
    required this.puntos,
    this.zoom = 15,
    this.interactivo = true,
  });

  final List<PuntoMapa> puntos;
  final double zoom;
  final bool interactivo;

  @override
  Widget build(BuildContext context) {
    final interaccion = InteractionOptions(
      flags: interactivo
          ? InteractiveFlag.all & ~InteractiveFlag.rotate
          : InteractiveFlag.none,
    );
    // Con varios puntos la cámara se ajusta para que todos queden visibles.
    final opciones = puntos.length > 1
        ? MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: puntos.map((p) => p.posicion).toList(),
              padding: const EdgeInsets.all(48),
              maxZoom: 16,
            ),
            interactionOptions: interaccion,
          )
        : MapOptions(
            initialCenter: puntos.isEmpty
                ? const LatLng(21.0446, -89.6427) // Mérida, Yucatán
                : puntos.first.posicion,
            initialZoom: puntos.isEmpty ? 11 : zoom,
            interactionOptions: interaccion,
          );

    return FlutterMap(
      options: opciones,
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'mx.anahuac.diegoolea.huellas',
        ),
        MarkerLayer(
          markers: [
            for (final p in puntos)
              Marker(
                point: p.posicion,
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: p.alTocar,
                  child: const Icon(Icons.location_on,
                      size: 44, color: AppTheme.terracota),
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(source: Text('OpenStreetMap')),
      ],
    );
  }
}
