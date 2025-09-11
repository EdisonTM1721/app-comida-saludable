import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
// Importa el nuevo archivo que contiene AuthWrapper y MainAppShell
import 'package:emprendedor/presentation/pages/auth_wrapper.dart';

// Logger global
final Logger logger = Logger('AppLogger');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      logger.info("Activando Firebase App Check en modo DEBUG...");
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
      logger.info("✅ App Check activado en modo DEBUG.");
    } catch (e, stackTrace) {
      logger.severe("❌ Error activando App Check en DEBUG: $e", e, stackTrace);
    }
  } else {
    try {
      logger.info("Activando Firebase App Check en modo PRODUCCIÓN...");
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
      logger.info("✅ App Check activado en modo PRODUCCIÓN.");
    } catch (e, stackTrace) {
      logger.severe("❌ Error activando App Check en PRODUCCIÓN: $e", e, stackTrace);
    }
  }

  runApp(const MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.time} [${record.loggerName}]: ${record.message}');
    if (record.error != null) print('  ERROR: ${record.error}');
    if (record.stackTrace != null) print('  STACKTRACE: ${record.stackTrace}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Emprendedor',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal)
            .copyWith(secondary: Colors.amberAccent),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal, width: 2.0),
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.amberAccent,
          foregroundColor: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
