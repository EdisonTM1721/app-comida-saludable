import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/controllers/stats_controller.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/presentation/pages/product_list_page.dart';
import 'package:emprendedor/presentation/pages/order_list_page.dart';
import 'package:emprendedor/presentation/pages/statistics_page.dart';
import 'package:emprendedor/presentation/pages/promotions_page.dart';
import 'package:emprendedor/presentation/pages/home_page.dart';
import 'package:emprendedor/presentation/pages/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'firebase_options.dart';

// Importaciones necesarias
final Logger logger = Logger('AppLogger');

// Función principal para la configuración de Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Configuración del registro
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    logger.info('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      logger.severe('  ERROR: ${record.error}');
    }
    if (record.stackTrace != null) {
      logger.severe('  STACKTRACE: ${record.stackTrace}');
    }
  });
}

// Clase principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Metodo para construir la aplicación
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductController()),
        ChangeNotifierProvider(create: (context) => OrderController()),
        ChangeNotifierProvider(create: (context) => StatsController()),
        ChangeNotifierProvider(create: (context) => PromotionController()),
        // Agrega el nuevo controlador del perfil aquí
        ChangeNotifierProvider(create: (context) => ProfileController()),
      ],
      child: MaterialApp(
        title: 'App Emprendedor',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        locale: const Locale('es', 'ES'),
        theme: ThemeData(
          primarySwatch: Colors.teal,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.teal,
          ).copyWith(
            secondary: Colors.amberAccent,
          ),
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
          chipTheme: ChipThemeData(
            backgroundColor: Colors.grey[300],
            labelStyle: const TextStyle(color: Colors.black87),
            secondaryLabelStyle: const TextStyle(color: Colors.white),
            secondarySelectedColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        debugShowCheckedModeBanner: false,

        // CAMBIO PRINCIPAL: Ahora la aplicación inicia con un gestor de autenticación
        home: const AuthWrapper(),
      ),
    );
  }
}

// Clase para la pantalla principal
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  // Metodo para construir la pantalla principal
  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

// Estado de la pantalla principal
class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;

  // Lista de las pantallas
  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const ProductListPage(),
    const OrderListPage(),
    const StatisticsPage(),
    const PromotionsPage(),
    // Agrega la nueva página de perfil aquí
    const ProfilePage(),
  ];

  // Lista de los titulos de las pantallas
  static const List<String> _pageTitles = <String>[
    'Panel de Inicio',
    'Gestión de Productos',
    'Gestión de Pedidos',
    'Estadísticas de la Tienda',
    'Gestión de Promociones',
    'Perfil',
  ];

  // Metodo para cambiar de pantalla
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await _auth.signOut();
  }

  // Metodo para construir la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: _selectedIndex == 5 ? [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BusinessProfileEditPage(),
                ),
              );
            },
            tooltip: 'Ajustes',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ] : null,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Promociones',
          ),
          // Agrega la nueva pestaña de perfil aquí
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Nueva clase para gestionar el flujo de autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // Usuario autenticado, muestra la aplicación principal
          return const MainAppShell();
        } else {
          // Usuario no autenticado, muestra la página de inicio de sesión
          return const LoginPage();
        }
      },
    );
  }
}
