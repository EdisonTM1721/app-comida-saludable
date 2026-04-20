import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:emprendedor/presentation/pages/auth/phone_auth_page.dart';
import 'package:emprendedor/presentation/pages/auth/login_page.dart';
import 'package:emprendedor/presentation/pages/auth/auth_wrapper.dart';

import 'package:emprendedor/data/models/entrepreneur/business_profile_model.dart';
import 'package:emprendedor/data/models/client/client_profile_model.dart';
import 'package:emprendedor/data/models/nutritionist/nutritionist_profile_model.dart';

import 'package:emprendedor/data/repositories/entrepreneur/business_profile_repository.dart';
import 'package:emprendedor/data/repositories/client/client_profile_repository.dart';
import 'package:emprendedor/data/repositories/nutritionist/nutritionist_profile_repository.dart';

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

  final _businessRepo = BusinessProfileRepository();
  final _clientRepo = ClientProfileRepository();
  final _nutritionistRepo = NutritionistProfileRepository();

  String? _errorMessage;
  bool _isLoading = false;
  String _selectedRole = 'emprendedor';

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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _defaultNameByRole(String role) {
    switch (role) {
      case 'cliente':
        return 'Nuevo Cliente';
      case 'nutricionista':
        return 'Nuevo Nutricionista';
      default:
        return 'Nuevo Emprendedor';
    }
  }

  Future<void> _saveProfileByRole({
    required String userId,
    String? name,
  }) async {
    final defaultName = name ?? _defaultNameByRole(_selectedRole);

    switch (_selectedRole) {
      case 'cliente':
        final profile = ClientProfileModel(
          userId: userId,
          name: defaultName,
          role: 'cliente',
        );
        await _clientRepo.createClientProfile(profile);
        break;

      case 'nutricionista':
        final profile = NutritionistProfileModel(
          userId: userId,
          name: defaultName,
          role: 'nutricionista',
        );
        await _nutritionistRepo.createNutritionistProfile(profile);
        break;

      case 'emprendedor':
      default:
        final profile = BusinessProfileModel(
          userId: userId,
          name: defaultName,
          role: 'emprendedor',
        );
        await _businessRepo.createBusinessProfile(profile);
        break;
    }
  }

  Future<void> _goToAuthWrapper() async {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
    );
  }

  Future<void> _registerWithEmail() async {
    if (!mounted) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'No se pudo crear el usuario.',
        );
      }

      await _saveProfileByRole(userId: user.uid);

      _showSnackBar('¡Registro exitoso!');
      await _goToAuthWrapper();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Esta cuenta ya está registrada. Por favor, inicia sesión.';
      } else {
        message =
            e.message ?? 'Error de registro. Por favor, inténtelo de nuevo.';
      }

      setState(() {
        _errorMessage = message;
      });

      _showSnackBar(message, isError: true);
      logger.severe(
        'Error de autenticación al registrar: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      const message = 'Ocurrió un error al registrar la cuenta.';
      setState(() {
        _errorMessage = message;
      });
      _showSnackBar(message, isError: true);
      logger.severe('Error general al registrar con email: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      if (!mounted) return;

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _saveProfileByRole(
          userId: userCredential.user!.uid,
          name: googleUser.displayName ?? _defaultNameByRole(_selectedRole),
        );

        _showSnackBar('¡Registro exitoso con Google!');
      } else {
        _showSnackBar('¡Inicio de sesión con Google exitoso!');
      }

      await _goToAuthWrapper();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      if (e.code == 'account-exists-with-different-credential') {
        message =
        'Ya existe una cuenta con este correo. Inicia sesión con tu método original.';
      } else if (e.code == 'invalid-credential') {
        message = 'Credenciales de Google inválidas.';
      } else {
        message = e.message ?? 'Error inesperado al registrar con Google.';
      }

      setState(() {
        _errorMessage = message;
      });

      _showSnackBar(message, isError: true);
      logger.severe(
        'Error de autenticación con Google: ${e.code} - ${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Ocurrió un error al continuar con Google.';
      });

      _showSnackBar('Ocurrió un error al continuar con Google.', isError: true);
      logger.severe('Error general en Google Sign-In: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPhoneRegister() {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhoneAuthPage(
          isLogin: false,
          selectedRole: _selectedRole,
        ),
      ),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.trim().contains('@')) {
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
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Tipo de cuenta',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Theme.of(context).primaryColorDark,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'emprendedor',
                                  child: Text('Emprendedor'),
                                ),
                                DropdownMenuItem(
                                  value: 'cliente',
                                  child: Text('Cliente'),
                                ),
                                DropdownMenuItem(
                                  value: 'nutricionista',
                                  child: Text('Nutricionista'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _registerWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                                  : const Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha((0.8 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
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
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
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
                      onPressed: _isLoading ? null : _navigateToPhoneRegister,
                      icon: const Icon(
                        Icons.phone_iphone_outlined,
                        color: Colors.white,
                      ),
                      label: const Text('Continuar con Teléfono'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: _isLoading ? null : _navigateToLogin,
                    child: const Text(
                      '¿Ya tienes una cuenta? Inicia Sesión',
                      style: TextStyle(color: Colors.white, fontSize: 15),
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