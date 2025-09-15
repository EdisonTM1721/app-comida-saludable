import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/pages/home_page.dart';
import 'package:emprendedor/presentation/pages/product_list_page.dart';
import 'package:emprendedor/presentation/pages/order_list_page.dart'; // <-- import actualizado
import 'package:emprendedor/presentation/pages/statistics_page.dart';
import 'package:emprendedor/presentation/pages/promotions_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_page.dart';
import 'package:emprendedor/presentation/pages/settings_page.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ProductListPage(),
    const OrderListPage(), // <-- reemplazo correcto
    const StatisticsPage(),
    const PromotionsPage(),
    const BusinessProfilePage(),
  ];

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: _appBarActions[_selectedIndex],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Productos'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Promociones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
