import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _emailKey         = 'nesta_biometric_email';
  static const _passwordKey      = 'nesta_biometric_password';
  static const _refreshTokenKey  = 'nesta_biometric_refresh_token';

  /// Returns true if the device supports biometric authentication.
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Triggers the biometric prompt. Returns true on success.
  static Future<bool> authenticate(String localizedReason) async {
    try {
      final result = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,   // fingerprint / Face ID only — no PIN fallback
          stickyAuth: true,
        ),
      );
      return result;
    } on PlatformException catch (e) {
      // e.g. NotEnrolled, NotAvailable, LockedOut
      // Returning false lets callers show a user-friendly message.
      debugPrint('[BiometricService] authenticate error: ${e.code} – ${e.message}');
      return false;
    }
  }

  // ── Email / password credentials (set from login screen) ──────────────────

  /// Securely stores the user's credentials for future biometric logins.
  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  /// Retrieves stored credentials, or null if none are saved.
  static Future<Map<String, String>?> getCredentials() async {
    final email    = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  // ── Refresh token (set from home screen when user is already logged in) ───

  /// Securely stores a Supabase refresh token for session restoration.
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieves the stored refresh token, or null if none is saved.
  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  /// Returns true if any biometric login data has been saved.
  static Future<bool> hasCredentials() async {
    final email        = await _storage.read(key: _emailKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    return email != null || refreshToken != null;
  }

  /// Removes all stored biometric login data (disables biometric login).
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
