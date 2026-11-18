import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/dependencias.dart';
import '../../core/routes/app_routes.dart';
import '../../domain/models/entrada_diario.dart';
import '../widgets/app_drawer.dart';
import '../widgets/mapa_ubicacion.dart';
import '../widgets/vistas_estado.dart';

/// Todas las entradas con ubicación en un solo mapa.
class MapaEntradasScreen extends StatefulWidget {
  const MapaEntradasScreen({super.key});

  @override
  State<MapaEntradasScreen> createState() => _MapaEntradasScreenState();
}

class _MapaEntradasScreenState extends State<MapaEntradasScreen> {
  Future<List<EntradaDiario>>? _carga;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carga ??= AppScope.of(context).diario.obtenerTodas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de recuerdos')),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<EntradaDiario>>(
        future: _carga,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return VistaError(
              mensaje: 'No se pudieron cargar tus entradas.',
              reintentar: () => setState(() {
                _carga = AppScope.of(context).diario.obtenerTodas();
              }),
            );
          }
          final conLugar = (snap.data ?? []).where((e) => e.tieneUbicacion).toList();
          if (conLugar.isEmpty) {
            return const VistaVacia(
              icono: Icons.map_outlined,
              titulo: 'Aún no hay lugares en tu mapa',
              detalle: 'Cada entrada que guardes con GPS aparecerá aquí.',
            );
          }
          return MapaUbicacion(
            puntos: [
              for (final e in conLugar)
                PuntoMapa(
                  LatLng(e.latitud!, e.longitud!),
                  alTocar: () => Navigator.pushNamed(context, AppRoutes.detalle,
                      arguments: e.id),
                ),
            ],
          );
        },
      ),
    );
  }
}
