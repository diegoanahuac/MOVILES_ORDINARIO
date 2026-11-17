import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../widgets/app_drawer.dart';

/// Ajustes guardados con SharedPreferences (bloqueo con Face ID).
class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  Future<(bool, bool)>? _carga;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AppScope.of(context).auth;
    _carga ??= Future.wait([auth.disponible(), auth.bloqueoActivado()])
        .then((r) => (r[0], r[1]));
  }

  Future<void> _cambiar(bool valor) async {
    final auth = AppScope.of(context).auth;
    // Para desactivar el bloqueo se pide verificar la identidad primero.
    if (!valor && !await auth.autenticar()) return;
    await auth.cambiarBloqueo(valor);
    setState(() => _carga = Future.value((true, valor)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      drawer: const AppDrawer(),
      body: FutureBuilder<(bool, bool)>(
        future: _carga,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final (disponible, activo) = snap.data!;
          return ListView(children: [
            SwitchListTile(
              secondary: const Icon(Icons.face),
              title: const Text('Bloquear con Face ID'),
              subtitle: Text(disponible
                  ? 'Pide Face ID o el código del iPhone al abrir la app'
                  : 'Este dispositivo no tiene un método de bloqueo configurado'),
              value: disponible && activo,
              onChanged: disponible ? _cambiar : null,
            ),
          ]);
        },
      ),
    );
  }
}
