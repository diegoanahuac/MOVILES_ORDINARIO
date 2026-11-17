import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/dependencias.dart';

/// Muestra la foto guardada de una entrada. Resuelve la ruta del archivo de
/// forma asíncrona con un FutureBuilder.
class FotoEntrada extends StatelessWidget {
  const FotoEntrada({super.key, required this.nombre, this.fit = BoxFit.cover});

  final String? nombre;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (nombre == null) return const _SinFoto();
    final media = AppScope.of(context).media;
    return FutureBuilder<File>(
      future: media.archivoDe(nombre!),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const ColoredBox(color: Color(0xFFE9DFD3));
        }
        return Image.file(
          snap.data!,
          fit: fit,
          errorBuilder: (_, _, _) => const _SinFoto(),
        );
      },
    );
  }
}

class _SinFoto extends StatelessWidget {
  const _SinFoto();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFE9DFD3),
        child: Center(child: Icon(Icons.photo_outlined, color: Colors.black38)),
      );
}
