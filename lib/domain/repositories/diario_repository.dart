import '../models/entrada_diario.dart';

/// Contrato del repositorio de entradas (principio de inversión de dependencias).
///
/// La interfaz de usuario sólo conoce esta abstracción; la implementación
/// concreta (SQLite) vive en la capa de datos y puede cambiarse sin tocar
/// las pantallas.
abstract interface class DiarioRepository {
  Future<List<EntradaDiario>> obtenerTodas();
  Future<EntradaDiario?> obtenerPorId(int id);
  Future<EntradaDiario> guardar(EntradaDiario entrada);
  Future<void> eliminar(EntradaDiario entrada);
}
