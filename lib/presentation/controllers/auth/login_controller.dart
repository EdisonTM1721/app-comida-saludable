import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger('LoginController');

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? errorMessage;
  bool isLoading = false;
  bool obscurePassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty || !value.trim().contains('@')) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  Future<bool> signInWithEmail() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    _setError(null);
    _setLoading(true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      logger.info('Inicio de sesión con correo exitoso.');
      return true;
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No se encontró una cuenta con este correo.';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta. Por favor, intente de nuevo.';
          break;
        case 'invalid-credential':
          message = 'Credenciales inválidas. Verifica tu correo y contraseña.';
          break;
        default:
          message =
              e.message ??
                  'Error de inicio de sesión. Por favor, inténtelo de nuevo.';
      }

      _setError(message);
      logger.severe(
        'Error de autenticación con email: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      _setError('Ocurrió un error inesperado al iniciar sesión.');
      logger.severe('Error inesperado en login con email: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setError(null);
    _setLoading(true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      logger.info('Inicio de sesión con Google exitoso.');
      return true;
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
          'Ya existe una cuenta con este correo. Inicia sesión con otro método.';
          break;
        case 'invalid-credential':
          message = 'Credenciales de Google inválidas.';
          break;
        default:
          message =
              e.message ??
                  'Error con Google Sign-In. Por favor, inténtelo de nuevo.';
      }

      _setError(message);
      logger.severe(
        'Error de autenticación con Google: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      _setError('Ocurrió un error inesperado.');
      logger.severe('Error inesperado en Google Sign In: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      return 'Ingresa un correo válido para restablecer.';
    }

    _setLoading(true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      logger.info('Correo de restablecimiento enviado.');
      return null;
    } on FirebaseAuthException catch (e) {
      logger.severe(
        'Error al enviar correo de restablecimiento: ${e.code} - ${e.message}',
      );
      return e.message ?? 'Intente de nuevo';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}