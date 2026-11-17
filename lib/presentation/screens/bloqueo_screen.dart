import 'package:flutter/material.dart';

import '../../core/dependencias.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla inicial: pide Face ID / Touch ID (o el código del iPhone) antes de
/// mostrar el diario, si el bloqueo está activado en Ajustes.
class BloqueoScreen extends StatefulWidget {
  const BloqueoScreen({super.key});

  @override
  State<BloqueoScreen> createState() => _BloqueoScreenState();
}

class _BloqueoScreenState extends State<BloqueoScreen> {
  bool _verificando = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _desbloquear());
  }

  Future<void> _desbloquear() async {
    final auth = AppScope.of(context).auth;
    setState(() {
      _verificando = true;
      _mensaje = null;
    });
    try {
      final requiere = await auth.bloqueoActivado() && await auth.disponible();
      final ok = !requiere || await auth.autenticar();
      if (!mounted) return;
      if (ok) {
        // Reemplaza la pantalla de bloqueo: "atrás" no regresa aquí.
        Navigator.pushReplacementNamed(context, AppRoutes.lista);
        return;
      }
      setState(() => _mensaje = 'No se pudo verificar tu identidad.');
    } catch (e) {
      if (mounted) setState(() => _mensaje = 'Error al desbloquear: $e');
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_stories, size: 88, color: AppTheme.terracota),
              const SizedBox(height: 16),
              Text('Huellas', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Tu diario es privado.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),
              if (_verificando)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _desbloquear,
                  icon: const Icon(Icons.face),
                  label: const Text('Desbloquear con Face ID'),
                ),
              if (_mensaje != null) ...[
                const SizedBox(height: 16),
                Text(_mensaje!, style: const TextStyle(color: Colors.redAccent)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
