import 'package:flutter/material.dart';
import 'package:emprendedor/presentation/pages/entrepreneur/home/home_screen.dart';

// clase página de inicio
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // Metodo para crear una nueva instancia de la página
  @override
  State<HomePage> createState() => _HomePageState();
}

// Estado de la página de inicio
class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {

    // Construye el widget
    return Container(
      color: Colors.white,
      child: const HomeScreen(),
    );
  }
}