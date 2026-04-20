import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/app/app.dart';
import 'package:emprendedor/firebase_options.dart';

final Logger logger = Logger('AppLogger');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();

  await _initializeFirebase();
  await _initializeAppCheck();

  runApp(const App());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.time} [${record.loggerName}]: ${record.message}',
    );
  });
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase inicializado con éxito.');
    } else {
      debugPrint('ℹ️ Firebase ya estaba activo, saltando inicialización.');
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('⚠️ Aviso: Firebase ya existe (duplicado ignorado).');
    } else {
      debugPrint('❌ Error inesperado en Firebase: $e');
    }
  }
}

Future<void> _initializeAppCheck() async {
  if (kDebugMode) {
    try {
      debugPrint('🚀 Activando App Check y generando token...');

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );

      final debugToken = await FirebaseAppCheck.instance.getToken();

      print('\n${'💎' * 40}');
      print('*** COPIA ESTE TOKEN EN LA CONSOLA DE FIREBASE ***');
      print(debugToken);
      print('${'💎' * 40}\n');
    } catch (e) {
      debugPrint('❌ Error al obtener el token de App Check: $e');
    }
  } else {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    } catch (e) {
      debugPrint('❌ Error en App Check Producción: $e');
    }
  }
}