import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/models/entrada_diario.dart';
import '../../domain/repositories/diario_repository.dart';
import '../../services/media_service.dart';
import '../datasources/diario_database.dart';

/// Implementación del repositorio usando SQLite (paquete sqflite).
///
/// Todas las operaciones van envueltas en try-catch: los errores de la base de
/// datos se traducen a [AppException] con un mensaje entendible.
class DiarioRepositorySqlite implements DiarioRepository {
  DiarioRepositorySqlite(this._fuente, this._media);

  final DiarioDatabase _fuente;
  final MediaService _media;

  @override
  Future<List<EntradaDiario>> obtenerTodas() async {
    try {
      final db = await _fuente.database;
      final filas = await db.query(DiarioDatabase.tablaEntradas,
          orderBy: 'fecha DESC');
      return filas.map(EntradaDiario.fromMap).toList();
    } on DatabaseException catch (e) {
      throw AppException('No se pudieron leer tus entradas.', e);
    } on FormatException catch (e) {
      throw AppException('Una entrada guardada está dañada.', e);
    }
  }

  @override
  Future<EntradaDiario?> obtenerPorId(int id) async {
    try {
      final db = await _fuente.database;
      final filas = await db.query(DiarioDatabase.tablaEntradas,
          where: 'id = ?', whereArgs: [id], limit: 1);
      return filas.isEmpty ? null : EntradaDiario.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw AppException('No se pudo abrir la entrada.', e);
    }
  }

  @override
  Future<EntradaDiario> guardar(EntradaDiario entrada) async {
    try {
      final db = await _fuente.database;
      if (entrada.id == null) {
        final id = await db.insert(DiarioDatabase.tablaEntradas, entrada.toMap());
        return entrada.copyWith(id: id);
      }
      await db.update(DiarioDatabase.tablaEntradas, entrada.toMap(),
          where: 'id = ?', whereArgs: [entrada.id]);
      return entrada;
    } on DatabaseException catch (e) {
      throw AppException('No se pudo guardar la entrada.', e);
    }
  }

  @override
  Future<void> eliminar(EntradaDiario entrada) async {
    try {
      final db = await _fuente.database;
      await db.delete(DiarioDatabase.tablaEntradas,
          where: 'id = ?', whereArgs: [entrada.id]);
      // La foto vive fuera de la base; se borra después de eliminar el registro.
      if (entrada.tieneFoto) await _media.borrarFoto(entrada.foto!);
    } on DatabaseException catch (e) {
      throw AppException('No se pudo eliminar la entrada.', e);
    }
  }
}
