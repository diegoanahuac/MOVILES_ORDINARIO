import 'package:flutter_test/flutter_test.dart';
import 'package:huellas/domain/models/entrada_diario.dart';

void main() {
  group('EntradaDiario', () {
    test('se serializa y deserializa sin perder datos', () {
      final original = EntradaDiario(
        id: 7,
        titulo: 'Cenote',
        contenido: 'Fuimos a nadar.',
        fecha: DateTime(2026, 11, 17, 10, 30),
        foto: 'foto_1.jpg',
        latitud: 21.0446,
        longitud: -89.6427,
        precision: 12.5,
        animo: EstadoAnimo.feliz,
        dictado: true,
      );
      final copia = EntradaDiario.fromMap(original.toMap());
      expect(copia.toMap(), original.toMap());
      expect(copia.tieneUbicacion, isTrue);
      expect(copia.heroTag, 'foto-entrada-7');
    });

    test('usa ánimo neutral si el valor guardado no existe', () {
      final e = EntradaDiario.fromMap({
        'titulo': 'x',
        'contenido': 'y',
        'fecha': '2026-11-17T10:00:00.000',
        'animo': 'desconocido',
      });
      expect(e.animo, EstadoAnimo.neutral);
      expect(e.tieneUbicacion, isFalse);
    });

    test('lanza FormatException si falta la fecha', () {
      expect(() => EntradaDiario.fromMap({'titulo': 'x'}),
          throwsA(isA<FormatException>()));
    });
  });
}
