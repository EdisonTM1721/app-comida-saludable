import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/pages/home_page.dart';
import 'package:emprendedor/presentation/pages/product_list_page.dart';
import 'package:emprendedor/presentation/pages/order_list_page.dart';
import 'package:emprendedor/presentation/pages/statistics_page.dart';
import 'package:emprendedor/presentation/pages/promotions_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_page.dart';
import 'package:emprendedor/presentation/pages/settings_page.dart';

// Configuración de registro
final Logger logger = Logger('MainAppShellLogger');

// Página principal de la aplicación
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  // Metodo para crear una nueva instancia de la página
  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

// Estado de la página principal de la aplicación
class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  // Lista de páginas
  final List<Widget> _pages = const [
    HomePage(),
    ProductListPage(),
    OrderListPage(),
    StatisticsPage(),
    PromotionsPage(),
    BusinessProfilePage(),
  ];

  // Títulos de las páginas
  static const List<String> _pageTitles = [
    'Panel de Inicio',
    'Mis Productos',
    'Mis Pedidos',
    'Estadísticas de la Tienda',
    'Mis Promociones',
    'Mi Perfil',
  ];

  // Acciones de la barra de navegación
  late final Map<int, List<Widget>> _appBarActions;

  // Inicialización de la barra de navegación
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

  // Cambio de página
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Construye el widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: _appBarActions[_selectedIndex],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // IMPORTANTE: asegura que el fondo se vea
        backgroundColor: Colors.white,       // Fondo de la barra
        selectedItemColor: Colors.blue,      // Color del ítem seleccionado
        unselectedItemColor: Colors.grey,    // Color de los ítems no seleccionados
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
