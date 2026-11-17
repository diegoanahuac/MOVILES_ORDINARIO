import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/dependencias.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Punto de entrada: arma las dependencias y arranca la app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  runApp(HuellasApp(dependencias: Dependencias.produccion()));
}

class HuellasApp extends StatelessWidget {
  const HuellasApp({super.key, required this.dependencias});

  final Dependencias dependencias;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencias: dependencias,
      child: MaterialApp(
        title: 'Huellas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro(),
        initialRoute: AppRoutes.bloqueo,
        onGenerateRoute: AppRoutes.generar,
      ),
    );
  }
}
