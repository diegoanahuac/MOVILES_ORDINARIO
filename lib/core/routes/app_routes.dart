import 'package:flutter/material.dart';

import '../../presentation/screens/acerca_screen.dart';
import '../../presentation/screens/ajustes_screen.dart';
import '../../presentation/screens/bloqueo_screen.dart';
import '../../presentation/screens/detalle_entrada_screen.dart';
import '../../presentation/screens/lista_entradas_screen.dart';
import '../../presentation/screens/nueva_entrada_screen.dart';
import '../../presentation/screens/mapa_entradas_screen.dart';

/// Rutas con nombre de la aplicación y su fábrica de pantallas.
abstract final class AppRoutes {
  static const bloqueo = '/';
  static const lista = '/entradas';
  static const detalle = '/entradas/detalle';
  static const nueva = '/entradas/nueva';
  static const mapa = '/mapa';
  static const ajustes = '/ajustes';
  static const acerca = '/acerca';

  /// Pantallas de primer nivel que se abren desde el Drawer.
  static const delDrawer = {lista, mapa, ajustes, acerca};

  static Route<dynamic> generar(RouteSettings settings) {
    switch (settings.name) {
      case bloqueo:
        return _fade(settings, const BloqueoScreen());
      case lista:
        return _fade(settings, const ListaEntradasScreen());
      case detalle:
        final id = settings.arguments;
        if (id is! int) return _error(settings, 'Falta el id de la entrada');
        return MaterialPageRoute(
            settings: settings, builder: (_) => DetalleEntradaScreen(id: id));
      case nueva:
        // Se abre desde abajo, como un formulario modal de iOS.
        return MaterialPageRoute(
            settings: settings,
            fullscreenDialog: true,
            builder: (_) => const NuevaEntradaScreen());
      case mapa:
        return _fade(settings, const MapaEntradasScreen());
      case ajustes:
        return _fade(settings, const AjustesScreen());
      case acerca:
        return _fade(settings, const AcercaScreen());
      default:
        return _error(settings, 'Ruta no encontrada: ${settings.name}');
    }
  }

  /// Transición de desvanecimiento para pantallas de primer nivel.
  static PageRouteBuilder<dynamic> _fade(RouteSettings s, Widget w) =>
      PageRouteBuilder(
        settings: s,
        pageBuilder: (_, _, _) => w,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  static Route<dynamic> _error(RouteSettings s, String mensaje) =>
      MaterialPageRoute(
        settings: s,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text(mensaje)),
        ),
      );

  /// Navega a una pantalla del Drawer sin apilar pantallas repetidas: la pila
  /// queda siempre como [lista] o [lista, otra].
  static void irDesdeDrawer(BuildContext context, String ruta) {
    final actual = ModalRoute.of(context)?.settings.name;
    Navigator.pop(context); // Cierra el Drawer.
    if (ruta == actual) return;
    if (ruta == lista) {
      Navigator.popUntil(context, (r) => r.settings.name == lista);
    } else if (actual == lista) {
      Navigator.pushNamed(context, ruta);
    } else {
      Navigator.pushReplacementNamed(context, ruta);
    }
  }
}
