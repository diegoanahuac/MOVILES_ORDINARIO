import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bloqueo biométrico (Face ID / Touch ID) y la preferencia para activarlo.
///
/// La preferencia se guarda con SharedPreferences: es un ajuste simple,
/// mientras que los registros del diario van en SQLite.
abstract interface class AuthService {
  Future<bool> disponible();
  Future<bool> bloqueoActivado();
  Future<void> cambiarBloqueo(bool activado);
  Future<bool> autenticar();
}

class AuthServiceLocal implements AuthService {
  static const _clave = 'bloqueo_biometrico';
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> disponible() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> bloqueoActivado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clave) ?? true;
  }

  @override
  Future<void> cambiarBloqueo(bool activado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clave, activado);
  }

  @override
  Future<bool> autenticar() async {
    try {
      // biometricOnly: false permite usar el código del iPhone como respaldo.
      return await _auth.authenticate(
        localizedReason: 'Desbloquea tu diario',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
