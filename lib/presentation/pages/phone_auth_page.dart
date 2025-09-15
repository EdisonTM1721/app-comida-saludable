import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/data/models/business_profile_model.dart';
import 'package:emprendedor/data/repositories/business_profile_repository.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';
import 'package:emprendedor/presentation/pages/auth_wrapper.dart';

// Nueva página para autenticación por teléfono
class PhoneAuthPage extends StatefulWidget {
  final bool isLogin;

  // Método para crear una nueva instancia de la página
  const PhoneAuthPage({super.key, required this.isLogin});

  // Estado de la nueva página
  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

// Estado de la nueva página
class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _auth = FirebaseAuth.instance;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _verificationId = '';
  String? _errorMessage;
  bool _otpSent = false;
  bool _isLoading = false;

  // Lista de códigos de país
  final List<Map<String, String>> _countryCodes = [
    {'name': 'Argentina', 'code': '+54'},
    {'name': 'Bolivia', 'code': '+591'},
    {'name': 'Chile', 'code': '+56'},
    {'name': 'Colombia', 'code': '+57'},
    {'name': 'Costa Rica', 'code': '+506'},
    {'name': 'Cuba', 'code': '+53'},
    {'name': 'Ecuador', 'code': '+593'},
    {'name': 'El Salvador', 'code': '+503'},
    {'name': 'Guatemala', 'code': '+502'},
    {'name': 'Honduras', 'code': '+504'},
    {'name': 'México', 'code': '+52'},
    {'name': 'Nicaragua', 'code': '+505'},
    {'name': 'Panamá', 'code': '+507'},
    {'name': 'Paraguay', 'code': '+595'},
    {'name': 'Perú', 'code': '+51'},
    {'name': 'Puerto Rico', 'code': '+1'},
    {'name': 'República Dominicana', 'code': '+1'},
    {'name': 'Uruguay', 'code': '+598'},
    {'name': 'Venezuela', 'code': '+58'},
    {'name': 'España', 'code': '+34'},
    {'name': 'Estados Unidos', 'code': '+1'},
  ];
  String _selectedCountryCode = '+593';
  String _selectedCountryName = 'Ecuador';

  // Método para crear una nueva instancia de la página
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

  // Método para seleccionar un país
  Future<void> _selectCountry() async {
    final selectedCountry = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        List<Map<String, String>> filteredCountries = _countryCodes;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Seleccionar País'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar país...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (query) {
                        setState(() {
                          filteredCountries = _countryCodes
                              .where((country) =>
                              country['name']!.toLowerCase().contains(query.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          return ListTile(
                            title: Text(country['name']!),
                            trailing: Text(country['code']!),
                            onTap: () {
                              Navigator.of(context).pop(country);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Actualiza el estado con el país seleccionado
    if (selectedCountry != null) {
      setState(() {
        _selectedCountryCode = selectedCountry['code']!;
        _selectedCountryName = selectedCountry['name']!;
      });
    }
  }

  Future<void> _verifyPhoneNumber() async {
    final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';

    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Por favor, introduce un número de teléfono válido.', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String message = 'Error de verificación: ${e.message}';
          if (e.code == 'invalid-phone-number') {
            message = 'El número de teléfono proporcionado no es válido.';
          } else if (e.code == 'too-many-requests') {
            message = 'Se han enviado demasiadas solicitudes. Inténtelo más tarde.';
          }
          setState(() {
            _errorMessage = message;
          });
          _showSnackBar(message, isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          _showSnackBar('Código enviado al número de teléfono.');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado. Inténtelo de nuevo.';
      });
      _showSnackBar(_errorMessage!, isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para iniciar sesión con credenciales
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final newProfile = BusinessProfileModel(
          userId: userCredential.user!.uid,
          name: 'Nuevo Emprendedor',
        );
        // La llamada a Firestore ahora está dentro de un try-catch general
        await BusinessProfileRepository().createBusinessProfile(newProfile);

        _showSnackBar('¡Registro exitoso! Por favor, inicia sesión con tu número.');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        _showSnackBar('¡Inicio de sesión exitoso! Redirigiendo...');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      String message = 'Error: No se pudo completar la operación. Por favor, inténtalo de nuevo.';
      if (e is FirebaseAuthException) {
        // Maneja errores específicos de Firebase Auth si es necesario
        message = 'Error de autenticación: Código inválido o expirado.';
      } else {
        // Muestra un mensaje de error más específico para problemas de permisos
        message = 'Error en la base de datos: Falta de permisos. Asegúrate de que tus reglas de seguridad de Firestore sean correctas.';
      }

      setState(() {
        _errorMessage = message;
      });
      _showSnackBar(message, isError: true);

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método para verificar el código de verificación
  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showSnackBar('Por favor, introduce el código de verificación.', isError: true);
      return;
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text.trim(),
    );
    await _signInWithCredential(credential);
  }

  // Construir la página
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación por Teléfono'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLogin ? 'Inicia Sesión con tu Teléfono' : 'Regístrate con tu Teléfono',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        readOnly: true,
                        onTap: _selectCountry,
                        decoration: InputDecoration(
                            labelText: 'País',
                            prefixIcon: const Icon(Icons.location_on),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: '$_selectedCountryName ($_selectedCountryCode)',
                            hintStyle: const TextStyle(color: Colors.black87)
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Número de Teléfono',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPhoneNumber,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Enviar Código de Verificación', style: TextStyle(fontSize: 16)),
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Código de Verificación',
                            prefixIcon: const Icon(Icons.sms),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Verificar y Continuar', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ],
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
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Volver a la página de inicio de sesión', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
