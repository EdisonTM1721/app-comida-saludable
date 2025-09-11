import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:emprendedor/presentation/pages/auth_wrapper.dart';
import 'package:flutter/foundation.dart'; // Importa foundation para kIsWeb

// Configuración de logging
final Logger logger = Logger('PhoneAuthPage');

// Página de autenticación con teléfono
class PhoneAuthPage extends StatefulWidget {
  final bool isLogin;
  const PhoneAuthPage({super.key, required this.isLogin});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _auth = FirebaseAuth.instance;
  final _smsCodeController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  String? _errorMessage;
  bool _isCodeSent = false;
  bool _isLoading = false;
  String? _phoneNumber;

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  // Método para enviar el código de verificación
  Future<void> _sendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingrese un número de teléfono válido.';
        _isLoading = false;
      });
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumber!,
        forceResendingToken: _isCodeSent ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          logger.info('Verificación completada automáticamente. No se usará para forzar la verificación manual.');
        },
        verificationFailed: (FirebaseAuthException e) {
          logger.severe('Error de verificación para $_phoneNumber: ${e.code} - ${e.message}');
          String message;
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'El número de teléfono es inválido.';
              break;
            case 'missing-phone-number':
              message = 'Por favor, ingrese el número de teléfono.';
              break;
            case 'too-many-requests':
              message = 'Has enviado demasiados códigos. Por favor, inténtelo más tarde.';
              break;
            default:
              message = e.message ?? 'Ocurrió un error durante la verificación.';
          }
          if (mounted) {
            setState(() {
              _errorMessage = message;
              _isLoading = false;
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          logger.info('Código enviado a $_phoneNumber. Verification ID: $verificationId, Resend Token: $resendToken');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isCodeSent = true;
              _isLoading = false;
              _errorMessage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código de verificación enviado. Revise su SMS.')),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          logger.info('Timeout de auto-recuperación de código para $_phoneNumber. Verification ID: $verificationId');
        },
      );
    } catch (e, stackTrace) {
      logger.severe('Excepción al llamar a verifyPhoneNumber para $_phoneNumber: $e', e, stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocurrió un error inesperado al enviar el código. Verifique su conexión.';
          _isLoading = false;
        });
      }
    }
  }

  // Método para verificar el código y autenticar al usuario
  Future<void> _verifyCode() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final smsCode = _smsCodeController.text.trim();
    if (smsCode.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Por favor, ingrese el código de 6 dígitos.';
          _isLoading = false;
        });
      }
      return;
    }

    if (_verificationId == null) {
      logger.warning('Intento de verificar código sin _verificationId.');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error interno: ID de verificación no encontrado. Intente reenviar el código.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      logger.info('Intentando iniciar sesión con credencial de teléfono.');
      await _auth.signInWithCredential(credential);
      logger.info('Inicio de sesión exitoso con teléfono.');

      if (mounted) {
        // Redirige al AuthWrapper para que este maneje la lógica de navegación
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      logger.severe('Error de FirebaseAuthException al verificar el código: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'El código de verificación es incorrecto. Por favor, revíselo.';
          break;
        case 'invalid-verification-id':
          message = 'El ID de verificación es inválido. Intente reenviar el código.';
          break;
        case 'credential-already-in-use':
          message = 'Esta credencial ya ha sido usada. Por favor, inicie sesión de nuevo.';
          break;
        default:
          message = e.message ?? 'Ocurrió un error inesperado al verificar el código.';
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.severe('Error inesperado al verificar el código: $e', e, stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocurrió un error inesperado al verificar el código.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Iniciar Sesión con Teléfono' : 'Registro con Teléfono'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isCodeSent ? 'Ingrese el código de verificación' : 'Ingrese su número de teléfono',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_isCodeSent) ...[
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Número de Teléfono',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(),
                    ),
                  ),
                  initialCountryCode: 'EC',
                  onChanged: (phone) {
                    _phoneNumber = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enviar Código'),
                ),
              ] else ...[
                TextFormField(
                  controller: _smsCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código SMS',
                    prefixIcon: Icon(Icons.sms),
                    counterText: '',
                    hintText: '123456',
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, ingrese el código.';
                    }
                    if (value.length != 6) {
                      return 'El código debe tener 6 dígitos.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verificar Código'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    logger.info('Botón "Reenviar Código" presionado.');
                    _sendCode();
                  },
                  child: const Text('Reenviar Código'),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}