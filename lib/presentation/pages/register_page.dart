import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/presentation/pages/phone_auth_page.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';
import 'package:url_launcher/url_launcher.dart'; // ASEGÚRATE DE TENER ESTE PAQUETE EN PUBSPEC.YAML

final Logger logger = Logger('RegisterPage');

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showSnackBar('No se pudo abrir el enlace: $urlString', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _registerWithEmail() async {
    if (!mounted) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _errorMessage = null;
        _isLoading = true;
      });
      try {

        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // TODO: Crear perfil en Firestore (usar userCredential.user.uid)

        if (!mounted) return;
        _showSnackBar('¡Registro exitoso! Redirigiendo a inicio de sesión...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String message;
        if (e.code == 'weak-password') {
          message = 'La contraseña es demasiado débil.';
        } else if (e.code == 'email-already-in-use') {
          message = 'Ya existe una cuenta con este correo electrónico.';
        } else {
          message = e.message ?? 'Error de registro. Por favor, inténtelo de nuevo.';
        }
        setState(() {
          _errorMessage = message;
        });
        _showSnackBar(message, isError: true);
        logger.severe('Error de autenticación al registrar: ${e.code} - ${e.message}');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (!mounted) return;

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // TODO: Crear perfil en Firestore (usar userCredential.user.uid, googleUser.displayName, googleUser.email)
        _showSnackBar('¡Registro exitoso con Google! Redirigiendo...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Ya existe una cuenta con este correo electrónico de Google.';
        });
        _showSnackBar('¡Ya tienes una cuenta con Google! Por favor, inicia sesión.', isError: true);
        await GoogleSignIn().signOut();
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      if (e.code == 'account-exists-with-different-credential') {
        message = 'Ya existe una cuenta con este correo. Inicia sesión con tu método original.';
      } else if (e.code == 'invalid-credential') {
        message = 'Credenciales de Google inválidas.';
      } else {
        message = e.message ?? 'Error inesperado al registrar con Google.';
      }
      setState(() {
        _errorMessage = message;
      });
      _showSnackBar(message, isError: true);
      logger.severe('Error de autenticación con Google: ${e.code} - ${e.message}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;
    final User? user = _auth.currentUser;

    if (user == null) {
      _showSnackBar('No hay usuario activo para eliminar. Por favor, inicia sesión primero.', isError: true);
      return;
    }

    // Guardar el contexto antes de mostrar el diálogo
    final currentContext = context;

    final bool? shouldDelete = await showDialog<bool>(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación de Cuenta'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('¿Estás absolutamente seguro de que quieres eliminar tu cuenta?'),
              SizedBox(height: 10),
              Text(
                'Esta acción es irreversible y todos tus datos asociados serán eliminados permanentemente.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              SizedBox(height: 10),
              Text(
                'IMPORTANTE: Para completar la eliminación, es posible que se te pida volver a iniciar sesión por seguridad.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí, Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });
      try {

        await user.delete();
        // TODO: Eliminar datos del usuario de Firestore y cualquier otro backend.

        if (!mounted) return;
        _showSnackBar('Cuenta eliminada con éxito. Serás redirigido.');
        await GoogleSignIn().signOut();

        // Usar el contexto guardado para la navegación
        Navigator.of(currentContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String message;
        if (e.code == 'requires-recent-login') {
          message = 'Esta operación requiere un inicio de sesión reciente. Por favor, cierra sesión y vuelve a iniciarla, luego intenta eliminar la cuenta de nuevo.';
        } else {
          message = e.message ?? 'Error al eliminar la cuenta.';
        }
        setState(() {
          _errorMessage = message;
        });
        _showSnackBar(message, isError: true);
        logger.severe('Error al eliminar cuenta: ${e.code} - ${e.message}');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Crea una nueva cuenta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 8,
                    color: Colors.white.withAlpha((0.95 * 255).round()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Correo Electrónico',
                                prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).primaryColorDark),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty || !value.trim().contains('@')) {
                                  return 'Ingresa un correo válido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColorDark),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa una contraseña.';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Confirmar Contraseña',
                                prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColorDark),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirma tu contraseña.';
                                }
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _registerWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: (_isLoading && _emailController.text.isNotEmpty)
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                  : const Text('Crear Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.4),
                                  children: <TextSpan>[
                                    const TextSpan(text: 'Al crear una cuenta, aceptas nuestros '),
                                    TextSpan(
                                      text: 'Términos de Servicio',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColorDark,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _launchURL('https://gist.githubusercontent.com/Crearcos/aa6427fa1e5669e28f59d2af6210f02f/raw/8a51b809943d80337dd0912581cbb94621daccef/terms_of_service_miapp.html');
                                        },
                                    ),
                                    const TextSpan(text: ' y '),
                                    TextSpan(
                                      text: 'Política de Privacidad',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColorDark,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _launchURL('https://gist.githubusercontent.com/Crearcos/363fe8dd01e6176d00fa50316e14b8e9/raw/9959ff87320f9563637fb986e2f34e32d0cdfe2a/privacy_policy_miapp.html');
                                        },
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha((0.8 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'o regístrate con',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _registerWithGoogle,
                      icon: Image.asset(
                        'assets/icons/google_logo.png',
                        height: 22,
                        width: 22,
                      ),
                      label: const Text('Continuar con Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[800],
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () async {
                        if (!mounted) return;
                        final success = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PhoneAuthPage(isLogin: false),
                          ),
                        );
                        if (!mounted) return;
                        if (success != null && success == true) {
                          // 1. Mostrar el Snackbar de éxito.
                          _showSnackBar('¡Registro exitoso! Redirigiendo a inicio de sesión...');

                          // 2. Esperar 2 segundos antes de navegar.
                          await Future.delayed(const Duration(seconds: 2));

                          // 3. Redirigir a la LoginPage.
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        }
                      },
                      icon: const Icon(Icons.phone_iphone_outlined, color: Colors.white),
                      label: const Text('Continuar con Teléfono'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      '¿Ya tienes una cuenta? Inicia Sesión',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  // Botón de eliminar cuenta (considerar mover a una página de ajustes post-login)
                  if (_auth.currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextButton.icon(
                        icon: Icon(Icons.delete_forever_outlined, color: Colors.red.shade300),
                        label: Text(
                          'Eliminar Mi Cuenta',
                          style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading ? null : _deleteAccount,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}