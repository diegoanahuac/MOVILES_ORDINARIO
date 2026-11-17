import 'package:flutter/widgets.dart';

import '../data/datasources/diario_database.dart';
import '../data/repositories/diario_repository_sqlite.dart';
import '../domain/repositories/diario_repository.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/speech_service.dart';

/// Contenedor de dependencias (composición en un solo lugar).
///
/// Las pantallas reciben abstracciones (interfaces), no clases concretas, así
/// se respetan los principios de responsabilidad única e inversión de
/// dependencias y es fácil sustituirlas por versiones falsas en pruebas.
class Dependencias {
  final DiarioRepository diario;
  final MediaService media;
  final SpeechService voz;
  final LocationService ubicacion;
  final AuthService auth;

  const Dependencias({
    required this.diario,
    required this.media,
    required this.voz,
    required this.ubicacion,
    required this.auth,
  });

  factory Dependencias.produccion() {
    final media = MediaServiceImagePicker();
    return Dependencias(
      diario: DiarioRepositorySqlite(DiarioDatabase(), media),
      media: media,
      voz: SpeechServiceNativo(),
      ubicacion: LocationServiceGeolocator(),
      auth: AuthServiceLocal(),
    );
  }
}

/// Expone [Dependencias] a todo el árbol de widgets.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencias, required super.child});

  final Dependencias dependencias;

  static Dependencias of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol de widgets');
    return scope!.dependencias;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencias != oldWidget.dependencias;
}
