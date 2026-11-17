import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/errors/app_exception.dart';

enum OrigenFoto { camara, galeria }

/// Gadget multimedia: cámara y galería.
abstract interface class MediaService {
  /// Abre la cámara o la galería y copia la imagen a la carpeta de la app.
  /// Devuelve el nombre del archivo guardado, o null si el usuario canceló.
  Future<String?> tomarFoto(OrigenFoto origen);

  /// Convierte el nombre guardado en un [File] utilizable por la UI.
  Future<File> archivoDe(String nombre);

  Future<void> borrarFoto(String nombre);
}

class MediaServiceImagePicker implements MediaService {
  MediaServiceImagePicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<Directory> _carpetaFotos() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'fotos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<String?> tomarFoto(OrigenFoto origen) async {
    try {
      final xfile = await _picker.pickImage(
        source: origen == OrigenFoto.camara ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (xfile == null) return null; // El usuario canceló.

      // La imagen de image_picker vive en una carpeta temporal: se copia a
      // Documentos para que siga existiendo cuando se reabra la app.
      final destino = await _carpetaFotos();
      final nombre =
          'foto_${DateTime.now().millisecondsSinceEpoch}${p.extension(xfile.path)}';
      await File(xfile.path).copy(p.join(destino.path, nombre));
      return nombre;
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied')) {
        throw PermisoDenegadoException(
            origen == OrigenFoto.camara
                ? 'Permite el acceso a la cámara en Ajustes > Huellas.'
                : 'Permite el acceso a tus fotos en Ajustes > Huellas.',
            e);
      }
      throw AppException(
          origen == OrigenFoto.camara
              ? 'No se pudo usar la cámara en este dispositivo.'
              : 'No se pudo abrir la galería.',
          e);
    } on FileSystemException catch (e) {
      throw AppException('No se pudo guardar la foto.', e);
    }
  }

  @override
  Future<File> archivoDe(String nombre) async =>
      File(p.join((await _carpetaFotos()).path, nombre));

  @override
  Future<void> borrarFoto(String nombre) async {
    try {
      final f = await archivoDe(nombre);
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Si la foto ya no existe no es un error para el usuario.
    }
  }
}
