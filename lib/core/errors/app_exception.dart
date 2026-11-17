/// Error controlado de la aplicación, con un mensaje apto para mostrarse al
/// usuario. Las capas inferiores atrapan excepciones de plugins o de SQLite y
/// las convierten en [AppException] para que la UI no dependa de ellas.
class AppException implements Exception {
  final String mensaje;
  final Object? causa;

  const AppException(this.mensaje, [this.causa]);

  @override
  String toString() =>
      causa == null ? 'AppException: $mensaje' : 'AppException: $mensaje ($causa)';
}

/// El usuario negó un permiso de hardware (cámara, micrófono, ubicación…).
class PermisoDenegadoException extends AppException {
  const PermisoDenegadoException(super.mensaje, [super.causa]);
}
