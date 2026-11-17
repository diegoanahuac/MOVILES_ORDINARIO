import 'package:flutter/material.dart';

/// Vista reutilizable para listas vacías.
class VistaVacia extends StatelessWidget {
  const VistaVacia({super.key, required this.icono, required this.titulo, this.detalle});

  final IconData icono;
  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icono, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text(titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (detalle != null) ...[
              const SizedBox(height: 8),
              Text(detalle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
            ],
          ]),
        ),
      );
}

/// Vista reutilizable de error con botón para reintentar.
class VistaError extends StatelessWidget {
  const VistaError({super.key, required this.mensaje, required this.reintentar});

  final String mensaje;
  final VoidCallback reintentar;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: reintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ]),
        ),
      );
}

/// Muestra un mensaje breve al usuario.
void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ));
}
