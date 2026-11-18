import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Guarda cada captura de la prueba de integración en docs/capturas.
Future<void> main() => integrationDriver(
      onScreenshot: (nombre, bytes, [args]) async {
        final f = File('docs/capturas/$nombre.png');
        await f.parent.create(recursive: true);
        await f.writeAsBytes(bytes);
        return true;
      },
    );
