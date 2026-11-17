import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/models/entrada_diario.dart';
import '../../services/location_service.dart';
import '../../services/media_service.dart';
import '../../services/speech_service.dart';
import '../widgets/foto_entrada.dart';
import '../widgets/vistas_estado.dart';

/// Formulario de nueva entrada: foto (cámara/galería), dictado por voz,
/// estado de ánimo y captura del GPS al guardar.
class NuevaEntradaScreen extends StatefulWidget {
  const NuevaEntradaScreen({super.key});

  @override
  State<NuevaEntradaScreen> createState() => _NuevaEntradaScreenState();
}

enum _Paso { editando, ubicando, guardando }

class _NuevaEntradaScreenState extends State<NuevaEntradaScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _contenido = TextEditingController();

  String? _foto;
  EstadoAnimo _animo = EstadoAnimo.neutral;
  bool _escuchando = false;
  bool _usoDictado = false;
  double _nivelVoz = 0;
  _Paso _paso = _Paso.editando;

  /// Texto que había antes de empezar a dictar; el dictado se agrega al final.
  String _textoPrevio = '';

  /// Referencia guardada para poder detener el micrófono en dispose(), donde
  /// ya no se puede consultar el InheritedWidget.
  late SpeechService _voz;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voz = AppScope.of(context).voz;
  }

  @override
  void dispose() {
    if (_voz.escuchando) _voz.detener();
    _titulo.dispose();
    _contenido.dispose();
    super.dispose();
  }

  // ---------- Cámara y galería ----------
  Future<void> _elegirFoto(OrigenFoto origen) async {
    final media = AppScope.of(context).media;
    try {
      final nombre = await media.tomarFoto(origen);
      if (nombre == null) return;
      if (_foto != null) await media.borrarFoto(_foto!); // Reemplaza la anterior.
      setState(() => _foto = nombre);
    } on AppException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  void _menuFoto() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Tomar foto'),
            onTap: () {
              Navigator.pop(ctx);
              _elegirFoto(OrigenFoto.camara);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () {
              Navigator.pop(ctx);
              _elegirFoto(OrigenFoto.galeria);
            },
          ),
          if (_foto != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Quitar foto'),
              onTap: () {
                Navigator.pop(ctx);
                AppScope.of(context).media.borrarFoto(_foto!);
                setState(() => _foto = null);
              },
            ),
        ]),
      ),
    );
  }

  // ---------- Micrófono y dictado ----------
  Future<void> _alternarDictado() async {
    final voz = AppScope.of(context).voz;
    if (_escuchando) {
      await voz.detener();
      setState(() => _escuchando = false);
      return;
    }
    _textoPrevio = _contenido.text.trimRight();
    try {
      await voz.iniciar(
        alTexto: (texto, _) {
          final separador = _textoPrevio.isEmpty ? '' : ' ';
          _contenido.text = '$_textoPrevio$separador$texto';
          _contenido.selection =
              TextSelection.collapsed(offset: _contenido.text.length);
          _usoDictado = true;
        },
        alTerminar: () {
          if (mounted) setState(() => _escuchando = false);
        },
        alNivel: (n) {
          if (mounted) setState(() => _nivelVoz = n);
        },
      );
      setState(() => _escuchando = true);
    } on AppException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  // ---------- Guardar (con GPS) ----------
  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final deps = AppScope.of(context);
    if (_escuchando) await deps.voz.detener();

    setState(() => _paso = _Paso.ubicando);
    Ubicacion? ubicacion;
    try {
      ubicacion = await deps.ubicacion.obtenerActual();
    } on AppException catch (e) {
      // Sin GPS se puede guardar igual, pero se le avisa al usuario.
      if (!mounted) return;
      final seguir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sin ubicación'),
          content: Text('${e.mensaje}\n\n¿Guardar la entrada sin ubicación?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar así')),
          ],
        ),
      );
      if (seguir != true) {
        if (mounted) setState(() => _paso = _Paso.editando);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _paso = _Paso.guardando);
    try {
      await deps.diario.guardar(EntradaDiario(
        titulo: _titulo.text.trim(),
        contenido: _contenido.text.trim(),
        fecha: DateTime.now(),
        foto: _foto,
        latitud: ubicacion?.latitud,
        longitud: ubicacion?.longitud,
        precision: ubicacion?.precision,
        animo: _animo,
        dictado: _usoDictado,
      ));
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _paso = _Paso.editando);
      mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = _paso != _Paso.editando;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva entrada'),
        actions: [
          TextButton(
            onPressed: ocupado ? null : _guardar,
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Stack(children: [
        Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _selectorFoto(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Título del día'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ponle un título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contenido,
                minLines: 6,
                maxLines: 14,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: '¿Qué pasó hoy?',
                  alignLabelWithHint: true,
                  helperText: _escuchando
                      ? 'Escuchando… habla con naturalidad'
                      : 'Escribe o toca el micrófono para dictar',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Escribe o dicta algo' : null,
              ),
              const SizedBox(height: 12),
              _botonMicrofono(),
              const SizedBox(height: 20),
              Text('¿Cómo te sentiste?', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in EstadoAnimo.values)
                  ChoiceChip(
                    label: Text('${a.emoji} ${a.etiqueta}'),
                    selected: _animo == a,
                    onSelected: (_) => setState(() => _animo = a),
                  ),
              ]),
              const SizedBox(height: 20),
              const Row(children: [
                Icon(Icons.place_outlined, size: 18, color: Colors.black54),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Tu ubicación GPS se guarda automáticamente al tocar Guardar.',
                      style: TextStyle(color: Colors.black54)),
                ),
              ]),
            ],
          ),
        ),
        if (ocupado) _capaProgreso(),
      ]),
    );
  }

  Widget _selectorFoto() => GestureDetector(
        onTap: _menuFoto,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _foto == null
                ? const ColoredBox(
                    color: Color(0xFFE9DFD3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.black45),
                      SizedBox(height: 8),
                      Text('Agregar foto (cámara o galería)',
                          style: TextStyle(color: Colors.black54)),
                    ]),
                  )
                : FotoEntrada(nombre: _foto),
          ),
        ),
      );

  Widget _botonMicrofono() {
    // El halo crece con el volumen de la voz (retroalimentación visual).
    final halo = _escuchando ? (8 + _nivelVoz.clamp(0, 12) * 2).toDouble() : 0.0;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (_escuchando)
              BoxShadow(color: Colors.red.withValues(alpha: 0.35), blurRadius: halo, spreadRadius: halo / 2),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'mic',
          backgroundColor: _escuchando ? Colors.red : null,
          onPressed: _paso == _Paso.editando ? _alternarDictado : null,
          tooltip: _escuchando ? 'Detener dictado' : 'Dictar con el micrófono',
          child: Icon(_escuchando ? Icons.stop : Icons.mic),
        ),
      ),
    );
  }

  Widget _capaProgreso() => ColoredBox(
        color: Colors.black26,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(_paso == _Paso.ubicando
                    ? 'Obteniendo tu ubicación GPS…'
                    : 'Guardando entrada…'),
              ]),
            ),
          ),
        ),
      );
}
