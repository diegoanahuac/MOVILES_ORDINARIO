import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/entrada_diario.dart';
import 'foto_entrada.dart';

/// Tarjeta de una entrada en la lista. La miniatura lleva un Hero que se
/// anima hacia la foto grande de la pantalla de detalle.
class EntradaCard extends StatelessWidget {
  const EntradaCard({super.key, required this.entrada, required this.alTocar});

  final EntradaDiario entrada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat("EEE d 'de' MMMM · HH:mm", 'es_MX').format(entrada.fecha);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Hero(
                tag: entrada.heroTag,
                child: FotoEntrada(nombre: entrada.foto),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(entrada.animo.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entrada.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      entrada.contenido,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(fecha,
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const Spacer(),
                      if (entrada.dictado)
                        const Icon(Icons.mic, size: 16, color: Colors.black45),
                      if (entrada.tieneUbicacion)
                        const Icon(Icons.place, size: 16, color: Colors.black45),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
