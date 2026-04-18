import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/pages/home_page.dart';
import 'package:emprendedor/presentation/pages/product_list_page.dart';
import 'package:emprendedor/presentation/pages/order_list_page.dart';
import 'package:emprendedor/presentation/pages/statistics_page.dart';
import 'package:emprendedor/presentation/pages/promotions_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_page.dart';
import 'package:emprendedor/presentation/pages/settings_page.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  static const List<String> _pageTitles = [
    'Panel de Inicio',
    'Mis Productos',
    'Mis Pedidos',
    'Estadísticas de la Tienda',
    'Mis Promociones',
    'Mi Perfil',
  ];

  late final Map<int, List<Widget>> _appBarActions;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomePage(),
      ProductListPage(),
      OrderListPage(),
      StatisticsPage(),
      PromotionsPage(),
      BusinessProfilePage(
        key: ValueKey('business_profile_page'),
      ),
    ];
    _appBarActions = {
      4: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            final controller = context.read<PromotionController>();
            controller.fetchPromotions();
          },
          tooltip: 'Refrescar Promociones',
        ),
      ],
      5: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          tooltip: 'Ajustes',
        ),
      ],
    };
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentPage() {
    return IndexedStack(
      index: _selectedIndex,
      children: _pages,
    );
  }

  List<Widget> _buildAppBarActions() {
    final pageActions = _appBarActions[_selectedIndex] ?? [];

    return [
      ...pageActions,
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Cerrar sesión',
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cerrar sesión'),
              content: const Text('¿Deseas salir de tu cuenta?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Salir'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _logout();
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: _buildAppBarActions(),
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Productos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Promociones',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
