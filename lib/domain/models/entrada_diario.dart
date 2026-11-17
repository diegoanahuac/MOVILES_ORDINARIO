/// Modelo de dominio: una entrada del diario.
///
/// Es inmutable y no depende de Flutter ni de SQLite. La capa de datos lo
/// convierte a/desde un mapa (JSON) con [toMap] y [EntradaDiario.fromMap].
class EntradaDiario {
  final int? id;
  final String titulo;
  final String contenido;
  final DateTime fecha;

  /// Nombre del archivo de la foto dentro de la carpeta de documentos de la app.
  /// Se guarda sólo el nombre (no la ruta completa) porque en iOS la ruta del
  /// contenedor cambia entre instalaciones y actualizaciones.
  final String? foto;

  final double? latitud;
  final double? longitud;

  /// Precisión del GPS en metros al momento de guardar.
  final double? precision;

  final EstadoAnimo animo;

  /// Indica si el texto se dictó (total o parcialmente) con el micrófono.
  final bool dictado;

  const EntradaDiario({
    this.id,
    required this.titulo,
    required this.contenido,
    required this.fecha,
    this.foto,
    this.latitud,
    this.longitud,
    this.precision,
    this.animo = EstadoAnimo.neutral,
    this.dictado = false,
  });

  bool get tieneUbicacion => latitud != null && longitud != null;
  bool get tieneFoto => foto != null && foto!.isNotEmpty;

  /// Etiqueta única para la animación Hero entre lista y detalle.
  String get heroTag => 'foto-entrada-$id';

  EntradaDiario copyWith({int? id}) => EntradaDiario(
        id: id ?? this.id,
        titulo: titulo,
        contenido: contenido,
        fecha: fecha,
        foto: foto,
        latitud: latitud,
        longitud: longitud,
        precision: precision,
        animo: animo,
        dictado: dictado,
      );

  /// Serialización a mapa (columnas de SQLite / JSON).
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'titulo': titulo,
        'contenido': contenido,
        'fecha': fecha.toIso8601String(),
        'foto': foto,
        'latitud': latitud,
        'longitud': longitud,
        'precision': precision,
        'animo': animo.name,
        'dictado': dictado ? 1 : 0,
      };

  /// Deserialización desde un mapa. Lanza [FormatException] si los datos
  /// obligatorios no tienen el formato esperado.
  factory EntradaDiario.fromMap(Map<String, Object?> map) {
    final fechaTexto = map['fecha'];
    if (fechaTexto is! String) {
      throw const FormatException('La entrada no tiene una fecha válida');
    }
    return EntradaDiario(
      id: map['id'] as int?,
      titulo: (map['titulo'] as String?) ?? '',
      contenido: (map['contenido'] as String?) ?? '',
      fecha: DateTime.parse(fechaTexto),
      foto: map['foto'] as String?,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      precision: (map['precision'] as num?)?.toDouble(),
      animo: EstadoAnimo.desdeNombre(map['animo'] as String?),
      dictado: (map['dictado'] as int? ?? 0) == 1,
    );
  }
}

/// Cómo se sintió el usuario ese día. Sirve para filtrar y dar color a la lista.
enum EstadoAnimo {
  feliz('Feliz', '😄'),
  tranquilo('Tranquilo', '😌'),
  neutral('Normal', '😐'),
  cansado('Cansado', '😴'),
  triste('Triste', '😔');

  const EstadoAnimo(this.etiqueta, this.emoji);
  final String etiqueta;
  final String emoji;

  static EstadoAnimo desdeNombre(String? nombre) => EstadoAnimo.values
      .firstWhere((e) => e.name == nombre, orElse: () => EstadoAnimo.neutral);
}
