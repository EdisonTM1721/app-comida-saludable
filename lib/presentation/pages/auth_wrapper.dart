import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/controllers/stats_controller.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/presentation/pages/home_page.dart';
import 'package:emprendedor/presentation/pages/product_list_page.dart';
import 'package:emprendedor/presentation/pages/order_list_page.dart';
import 'package:emprendedor/presentation/pages/statistics_page.dart';
import 'package:emprendedor/presentation/pages/promotions_page.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_page.dart';
import 'package:emprendedor/presentation/pages/settings_page.dart';

final Logger logger = Logger('AuthWrapperLogger');

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final userId = snapshot.data!.uid;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ProductController(userId: userId)),
              ChangeNotifierProvider(create: (_) => OrderController(userId: userId)),
              ChangeNotifierProvider(create: (_) => StatsController(userId: userId)),
              ChangeNotifierProvider(create: (_) => PromotionController(userId: userId)),
              ChangeNotifierProvider(create: (_) => ProfileController(userId: userId)),
            ],
            child: Consumer<ProfileController>(
              builder: (context, profileController, child) {
                if (profileController.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (profileController.hasProfile) {
                  return const MainAppShell();
                } else {
                  return const BusinessProfileEditPage();
                }
              },
            ),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;

  // Esta lista ahora es dinámica para que las páginas se construyan con el contexto correcto.
  final List<Widget> _pages = <Widget>[
    const HomePage(),
    const ProductListPage(),
    const OrderListPage(),
    const StatisticsPage(),
    const PromotionsPage(),
    const BusinessProfilePage(),
  ];

  static const List<String> _pageTitles = <String>[
    'Panel de Inicio',
    'Mis Productos',
    'Mis Pedidos',
    'Estadísticas de la Tienda',
    'Mis Promociones',
    'Mi Perfil',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    try {
      await _auth.signOut();
    } catch (e, stackTrace) {
      logger.severe("Error durante el logout: $e", e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    // La página se construye dinámicamente usando el índice seleccionado.
    final currentPage = _pages[_selectedIndex];

    // Lógica para los botones de acción en el AppBar...
    List<Widget>? appBarActions;
    if (_selectedIndex == 4) {
      // Necesitas acceder al PromotionController aquí
      final promotionController = Provider.of<PromotionController>(context, listen: false);
      appBarActions = [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            promotionController.fetchPromotions();
          },
          tooltip: 'Refrescar Promociones',
        ),
      ];
    } else if (_selectedIndex == 5) {
      appBarActions = [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
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
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 08.0),
          child: Text(_pageTitles[_selectedIndex]),
        ),
        actions: appBarActions,
      ),
      // Muestra la página actual que tiene acceso al contexto correcto.
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Productos'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Promociones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}