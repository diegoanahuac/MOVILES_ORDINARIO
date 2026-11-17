import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

/// Menú lateral común a las pantallas de primer nivel.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final actual = ModalRoute.of(context)?.settings.name;
    Widget opcion(IconData icono, String texto, String ruta) => ListTile(
          leading: Icon(icono),
          title: Text(texto),
          selected: actual == ruta,
          selectedColor: AppTheme.terracota,
          onTap: () => AppRoutes.irDesdeDrawer(context, ruta),
        );

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(children: [
                Icon(Icons.auto_stories, color: AppTheme.terracota, size: 36),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Huellas',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Tu diario con foto, voz y lugar'),
                ]),
              ]),
            ),
            const Divider(height: 24),
            opcion(Icons.book_outlined, 'Mis entradas', AppRoutes.lista),
            opcion(Icons.map_outlined, 'Mapa de recuerdos', AppRoutes.mapa),
            opcion(Icons.settings_outlined, 'Ajustes', AppRoutes.ajustes),
            opcion(Icons.info_outline, 'Acerca de', AppRoutes.acerca),
          ],
        ),
      ),
    );
  }
}
