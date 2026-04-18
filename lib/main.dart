import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

// Importaciones locales
import 'firebase_options.dart';
import 'package:emprendedor/core/theme/app_theme.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/controllers/stats_controller.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/social_media_controller.dart';
import 'package:emprendedor/presentation/controllers/payment_method_controller.dart';
import 'package:emprendedor/presentation/pages/auth_wrapper.dart';
import 'package:emprendedor/presentation/widgets/user_session_initializer.dart';

final Logger logger = Logger('AppLogger');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();

  // 1. INICIALIZACIÓN DE FIREBASE CON PROTECCIÓN ANTI-DUPLICADO
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase inicializado con éxito.");
    } else {
      debugPrint("ℹ️ Firebase ya estaba activo, saltando inicialización.");
    }
  } catch (e) {
    // Si sale el error de duplicate-app, lo atrapamos aquí para que la app continúe
    if (e.toString().contains('duplicate-app')) {
      debugPrint("⚠️ Aviso: Firebase ya existe (duplicado ignorado).");
    } else {
      debugPrint("❌ Error inesperado en Firebase: $e");
    }
  }

  // 2. CONFIGURACIÓN DE APP CHECK Y OBTENCIÓN DEL TOKEN
  if (kDebugMode) {
    try {
      debugPrint("🚀 Activando App Check y generando token...");

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );

      // SOLICITUD DEL TOKEN PARA LA CONSOLA DE FIREBASE
      String? debugToken = await FirebaseAppCheck.instance.getToken();

      print('\n' + '💎' * 40);
      print('*** COPIA ESTE TOKEN EN LA CONSOLA DE FIREBASE ***');
      print('$debugToken');
      print('💎' * 40 + '\n');

    } catch (e) {
      debugPrint("❌ Error al obtener el token de App Check: $e");
    }
  } else {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    } catch (e) {
      debugPrint("❌ Error en App Check Producción: $e");
    }
  }

  runApp(const MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.level.name}] ${record.time} [${record.loggerName}]: ${record.message}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => StatsController()),
        ChangeNotifierProvider(create: (_) => PromotionController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => SocialMediaController()),
        ChangeNotifierProvider(create: (_) => PaymentMethodController()),
      ],
      child: MaterialApp(
        title: 'App Emprendedor',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES')],
        locale: const Locale('es', 'ES'),
        theme: AppTheme.build(),
        home: const UserSessionInitializer(
          child: AuthWrapper(),
        ),
      ),
    );
  }
}
