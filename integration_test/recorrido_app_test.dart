import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellas/core/dependencias.dart';
import 'package:huellas/data/datasources/diario_database.dart';
import 'package:huellas/data/repositories/diario_repository_sqlite.dart';
import 'package:huellas/domain/models/entrada_diario.dart';
import 'package:huellas/main.dart';
import 'package:huellas/services/auth_service.dart';
import 'package:huellas/services/location_service.dart';
import 'package:huellas/services/media_service.dart';
import 'package:huellas/services/speech_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'demo_fotos.dart';

/// Prueba de integración que recorre la app real en el simulador de iOS y
/// toma capturas para el reporte.
///
/// Se usan la base SQLite real, el GPS real del simulador y la navegación
/// real. Sólo la cámara/galería y el dictado se simulan, porque el simulador
/// no tiene cámara ni puede dictar sin intervención humana; el bloqueo con
/// Face ID se omite (se probó aparte).

/// Galería simulada: escribe una foto de demostración en Documentos/fotos.
class MediaDemo extends MediaServiceImagePicker {
  MediaDemo(this.fotos);
  final List<String> fotos;
  int _i = 0;

  @override
  Future<String?> tomarFoto(OrigenFoto origen) async {
    final docs = await getApplicationDocumentsDirectory();
    final nombre = 'demo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final f = File(p.join(docs.path, 'fotos', nombre));
    await f.parent.create(recursive: true);
    await f.writeAsBytes(base64Decode(fotos[_i++ % fotos.length]));
    return nombre;
  }
}

/// Dictado simulado: entrega la frase por partes, como el reconocimiento real.
class VozDemo implements SpeechService {
  bool _escuchando = false;
  void Function()? _fin;

  @override
  bool get escuchando => _escuchando;

  @override
  Future<void> iniciar({
    required void Function(String texto, bool esFinal) alTexto,
    required void Function() alTerminar,
    void Function(double nivel)? alNivel,
  }) async {
    _escuchando = true;
    _fin = alTerminar;
    const frase = 'Hoy fuimos a la playa de Progreso con mis amigos. '
        'El agua estaba tibia y comimos marquesitas en el malecón.';
    final palabras = frase.split(' ');
    for (var i = 1; i <= palabras.length; i++) {
      alTexto(palabras.take(i).join(' '), i == palabras.length);
    }
    alNivel?.call(8);
  }

  @override
  Future<void> detener() async {
    _escuchando = false;
    _fin?.call();
  }
}

class AuthDemo implements AuthService {
  @override
  Future<bool> autenticar() async => true;
  @override
  Future<bool> bloqueoActivado() async => true;
  @override
  Future<void> cambiarBloqueo(bool activado) async {}
  @override
  Future<bool> disponible() async => true;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> esperar(WidgetTester t, [int segundos = 2]) async {
    for (var i = 0; i < segundos * 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> captura(WidgetTester t, String nombre, [int espera = 2]) async {
    await esperar(t, espera);
    await binding.takeScreenshot(nombre);
  }

  testWidgets('recorrido completo de Huellas', (t) async {
    await initializeDateFormatting('es_MX');
    final media = MediaDemo([fotoPlayaB64, fotoAtardecerB64, fotoCarreteraB64]);
    final repo = DiarioRepositorySqlite(DiarioDatabase(), media);
    for (final e in await repo.obtenerTodas()) {
      await repo.eliminar(e);
    }
    final deps = Dependencias(
      diario: repo,
      media: media,
      voz: VozDemo(),
      ubicacion: LocationServiceGeolocator(), // GPS real del simulador
      auth: AuthDemo(),
    );

    await t.pumpWidget(HuellasApp(dependencias: deps));
    await captura(t, '02_lista_vacia', 3);

    // Formulario de nueva entrada.
    await t.tap(find.text('Nueva entrada'));
    await captura(t, '03_formulario_nueva_entrada');

    await t.tap(find.text('Agregar foto (cámara o galería)'));
    await captura(t, '04_menu_camara_o_galeria');
    await t.tap(find.text('Elegir de la galería'));
    await esperar(t);

    await t.enterText(find.byType(TextFormField).first, 'Día de playa en Progreso');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await esperar(t, 1);
    await t.tap(find.byTooltip('Dictar con el micrófono'));
    await captura(t, '05_dictado_por_voz');
    await t.tap(find.byTooltip('Detener dictado'));
    await esperar(t, 1);

    await t.ensureVisible(find.text('😄 Feliz'));
    await t.tap(find.text('😄 Feliz'));
    await captura(t, '06_formulario_completo');

    await t.tap(find.text('Guardar'));
    await t.pump(const Duration(milliseconds: 300));
    await binding.takeScreenshot('07_obteniendo_ubicacion_gps');
    await esperar(t, 6);

    // Dos entradas más en otros lugares de Yucatán para el mapa.
    final ahora = DateTime.now();
    await repo.guardar(EntradaDiario(
      titulo: 'Atardecer en Izamal',
      contenido: 'Caminamos por el convento amarillo y vimos el atardecer desde la pirámide.',
      fecha: ahora.subtract(const Duration(days: 2)),
      foto: await media.tomarFoto(OrigenFoto.galeria),
      latitud: 20.9314, longitud: -89.0179, precision: 8,
      animo: EstadoAnimo.tranquilo,
    ));
    await repo.guardar(EntradaDiario(
      titulo: 'Rumbo a Valladolid',
      contenido: 'Salimos temprano por la carretera. Mucho tráfico, pero valió la pena.',
      fecha: ahora.subtract(const Duration(days: 5)),
      foto: await media.tomarFoto(OrigenFoto.galeria),
      latitud: 20.6896, longitud: -88.2017, precision: 15,
      animo: EstadoAnimo.cansado, dictado: true,
    ));
    await t.drag(find.byType(ListView), const Offset(0, 400));
    await captura(t, '08_lista_de_entradas', 3);

    // Detalle con animación Hero, mapa y botón de Google Maps.
    await t.tap(find.text('Día de playa en Progreso'));
    await t.pump(const Duration(milliseconds: 150));
    await binding.takeScreenshot('09_animacion_hero_en_curso');
    await captura(t, '10_detalle_de_entrada', 3);
    await t.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await captura(t, '11_detalle_mapa_y_google_maps', 6);
    await t.pageBack();
    await esperar(t);

    // Drawer, mapa general y ajustes.
    await t.tap(find.byTooltip('Open navigation menu'));
    await captura(t, '12_menu_drawer');
    await t.tap(find.text('Mapa de recuerdos'));
    await captura(t, '13_mapa_de_recuerdos', 8);
    await t.tap(find.byTooltip('Open navigation menu'));
    await esperar(t, 1);
    await t.tap(find.text('Ajustes'));
    await captura(t, '14_ajustes_face_id');
  });
}
