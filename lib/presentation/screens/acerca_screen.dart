import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Icon(Icons.auto_stories, size: 72, color: AppTheme.terracota),
          SizedBox(height: 12),
          Text('Huellas 1.0',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          SizedBox(height: 16),
          Text(
            'Huellas es un diario personal que reduce el esfuerzo de escribir: '
            'dictas tu día con la voz, agregas una foto y la app guarda '
            'automáticamente dónde estabas. Todo se queda en tu teléfono y se '
            'protege con Face ID.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text('Programación de Dispositivos Móviles · Parcial 2\n'
              'Diego Kamil Olea Ruiz · Universidad Anáhuac Mayab',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
