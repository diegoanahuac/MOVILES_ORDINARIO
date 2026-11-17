import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Fuente de datos local: abre (una sola vez) la base SQLite de la app.
///
/// Responsabilidad única: crear/migrar el esquema y entregar la conexión.
class DiarioDatabase {
  static const _nombreArchivo = 'huellas.db';
  static const _version = 1;
  static const tablaEntradas = 'entradas';

  Database? _db;

  Future<Database> get database async => _db ??= await _abrir();

  Future<Database> _abrir() async {
    final ruta = p.join(await getDatabasesPath(), _nombreArchivo);
    return openDatabase(
      ruta,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tablaEntradas (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo     TEXT    NOT NULL,
            contenido  TEXT    NOT NULL,
            fecha      TEXT    NOT NULL,
            foto       TEXT,
            latitud    REAL,
            longitud   REAL,
            precision  REAL,
            animo      TEXT    NOT NULL DEFAULT 'neutral',
            dictado    INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_entradas_fecha ON $tablaEntradas (fecha DESC)');
      },
    );
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }
}
