import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'firebase_options.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/controllers/stats_controller.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/social_media_controller.dart';
import 'package:emprendedor/presentation/controllers/payment_method_controller.dart';
import 'package:emprendedor/presentation/pages/auth_wrapper.dart';

final Logger logger = Logger('AppLogger');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activar Firebase App Check
  if (kDebugMode) {
    try {
      logger.info("Activando Firebase App Check en modo DEBUG...");
      await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);
      logger.info("✅ App Check activado en DEBUG.");
    } catch (e, stackTrace) {
      logger.severe("❌ Error App Check DEBUG: $e", e, stackTrace);
    }
  } else {
    try {
      logger.info("Activando Firebase App Check en PRODUCCIÓN...");
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
      logger.info("✅ App Check activado en PRODUCCIÓN.");
    } catch (e, stackTrace) {
      logger.severe("❌ Error App Check PRODUCCIÓN: $e", e, stackTrace);
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductController>(create: (_) => ProductController()),
        ChangeNotifierProvider<OrderController>(create: (_) => OrderController()),
        ChangeNotifierProvider<StatsController>(create: (_) => StatsController()),
        ChangeNotifierProvider<PromotionController>(create: (_) => PromotionController()),
        ChangeNotifierProvider<ProfileController>(create: (_) => ProfileController()),
        ChangeNotifierProvider<SocialMediaController>(create: (_) => SocialMediaController()),
        ChangeNotifierProvider<PaymentMethodController>(create: (_) => PaymentMethodController()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
