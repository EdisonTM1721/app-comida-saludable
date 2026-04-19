import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Importaciones locales
import 'firebase_options.dart';
import 'package:emprendedor/core/theme/app_theme.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/product_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/order_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/stats_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/social_media_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/payment_method_controller.dart';
import 'package:emprendedor/presentation/controllers/client/client_profile_controller.dart';
import 'package:emprendedor/presentation/controllers/nutritionist/nutritionist_profile_controller.dart';
import 'package:emprendedor/presentation/pages/auth/auth_wrapper.dart';
import 'package:emprendedor/presentation/widgets/user_session_initializer.dart';
import 'package:emprendedor/presentation/controllers/client/cart_controller.dart';

final Logger logger = Logger('AppLogger');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();

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
    if (e.toString().contains('duplicate-app')) {
      debugPrint("⚠️ Aviso: Firebase ya existe (duplicado ignorado).");
    } else {
      debugPrint("❌ Error inesperado en Firebase: $e");
    }
  }

  if (kDebugMode) {
    try {
      debugPrint("🚀 Activando App Check y generando token...");

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );

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
    debugPrint(
      '[${record.level.name}] ${record.time} [${record.loggerName}]: ${record.message}',
    );
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
        ChangeNotifierProvider(create: (_) => ClientProfileController()),
        ChangeNotifierProvider(create: (_) => NutritionistProfileController()),
        ChangeNotifierProvider(create: (_) => CartController()),
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