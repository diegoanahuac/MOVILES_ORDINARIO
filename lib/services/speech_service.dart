import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/errors/app_exception.dart';

/// Gadget de audio: captura el micrófono y convierte voz a texto.
abstract interface class SpeechService {
  bool get escuchando;

  /// Comienza a escuchar. [alTexto] recibe la transcripción parcial y final;
  /// [alTerminar] se llama cuando el reconocimiento se detiene.
  Future<void> iniciar({
    required void Function(String texto, bool esFinal) alTexto,
    required void Function() alTerminar,
    void Function(double nivel)? alNivel,
  });

  Future<void> detener();
}

class SpeechServiceNativo implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _inicializado = false;
  void Function()? _alTerminar;

  @override
  bool get escuchando => _stt.isListening;

  Future<void> _inicializar() async {
    if (_inicializado) return;
    try {
      _inicializado = await _stt.initialize(
        onStatus: (estado) {
          if (estado == SpeechToText.doneStatus ||
              estado == SpeechToText.notListeningStatus) {
            _alTerminar?.call();
          }
        },
        onError: (SpeechRecognitionError e) => _alTerminar?.call(),
      );
    } catch (e) {
      throw AppException('El reconocimiento de voz no está disponible.', e);
    }
    if (!_inicializado) {
      throw const PermisoDenegadoException(
          'Permite el micrófono y el reconocimiento de voz en Ajustes > Huellas.');
    }
  }

  /// Prefiere español de México; si no existe, cualquier español; si no, el
  /// idioma del sistema.
  Future<String?> _localeEspanol() async {
    final locales = await _stt.locales();
    for (final id in ['es_MX', 'es-MX']) {
      if (locales.any((l) => l.localeId == id)) return id;
    }
    final es = locales.where((l) => l.localeId.startsWith('es'));
    return es.isEmpty ? null : es.first.localeId;
  }

  @override
  Future<void> iniciar({
    required void Function(String texto, bool esFinal) alTexto,
    required void Function() alTerminar,
    void Function(double nivel)? alNivel,
  }) async {
    await _inicializar();
    _alTerminar = alTerminar;
    try {
      await _stt.listen(
        onResult: (r) => alTexto(r.recognizedWords, r.finalResult),
        onSoundLevelChange: alNivel,
        listenOptions: SpeechListenOptions(
          localeId: await _localeEspanol(),
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      throw AppException('No se pudo iniciar el dictado.', e);
    }
  }

  @override
  Future<void> detener() => _stt.stop();
}
