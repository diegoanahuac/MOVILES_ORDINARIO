import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/dependencias.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/models/entrada_diario.dart';
import '../widgets/foto_entrada.dart';
import '../widgets/mapa_ubicacion.dart';
import '../widgets/vistas_estado.dart';

/// Detalle de una entrada: foto (Hero), texto, mapa y botón a Google Maps.
class DetalleEntradaScreen extends StatefulWidget {
  const DetalleEntradaScreen({super.key, required this.id});

  final int id;

  @override
  State<DetalleEntradaScreen> createState() => _DetalleEntradaScreenState();
}

class _DetalleEntradaScreenState extends State<DetalleEntradaScreen> {
  Future<EntradaDiario?>? _carga;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carga ??= AppScope.of(context).diario.obtenerPorId(widget.id);
  }

  Future<void> _abrirMaps(EntradaDiario e) async {
    try {
      await AppScope.of(context).ubicacion.abrirEnGoogleMaps(e.latitud!, e.longitud!);
    } on AppException catch (err) {
      if (mounted) mostrarMensaje(context, err.mensaje, error: true);
    }
  }

  Future<void> _eliminar(EntradaDiario e) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta entrada?'),
        content: const Text('Se borrarán el texto, la foto y la ubicación. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await AppScope.of(context).diario.eliminar(e);
      if (mounted) Navigator.pop(context, true); // Avisa a la lista que cambió.
    } on AppException catch (err) {
      if (mounted) mostrarMensaje(context, err.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EntradaDiario?>(
      future: _carga,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        final e = snap.data;
        if (snap.hasError || e == null) {
          return Scaffold(
            appBar: AppBar(),
            body: VistaError(
              mensaje: snap.error is AppException
                  ? (snap.error as AppException).mensaje
                  : 'No se encontró la entrada.',
              reintentar: () => setState(
                  () => _carga = AppScope.of(context).diario.obtenerPorId(widget.id)),
            ),
          );
        }
        return _contenido(e);
      },
    );
  }

  Widget _contenido(EntradaDiario e) {
    final fecha = DateFormat("EEEE d 'de' MMMM 'de' y, HH:mm", 'es_MX').format(e.fecha);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: e.tieneFoto ? 320 : 0,
            title: Text(e.titulo),
            actions: [
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _eliminar(e),
              ),
            ],
            flexibleSpace: e.tieneFoto
                ? FlexibleSpaceBar(
                    background: Hero(
                      tag: e.heroTag,
                      child: FotoEntrada(nombre: e.foto),
                    ),
                  )
                : null,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(children: [
              Row(children: [
                Chip(label: Text('${e.animo.emoji}  ${e.animo.etiqueta}')),
                const SizedBox(width: 8),
                if (e.dictado)
                  const Chip(avatar: Icon(Icons.mic, size: 18), label: Text('Dictada')),
              ]),
              const SizedBox(height: 8),
              Text(fecha, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              Text(e.contenido, style: const TextStyle(fontSize: 17, height: 1.5)),
              const SizedBox(height: 24),
              if (e.tieneUbicacion) ...[
                Text('Dónde estabas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: MapaUbicacion(
                      puntos: [PuntoMapa(LatLng(e.latitud!, e.longitud!))],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${e.latitud!.toStringAsFixed(5)}, ${e.longitud!.toStringAsFixed(5)}'
                  '${e.precision != null ? '  ·  ±${e.precision!.round()} m' : ''}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _abrirMaps(e),
                  icon: const Icon(Icons.map),
                  label: const Text('Abrir en Google Maps'),
                ),
              ] else
                const Text('Esta entrada no tiene ubicación guardada.',
                    style: TextStyle(color: Colors.black54)),
            ]),
          ),
        ],
      ),
    );
  }
}
