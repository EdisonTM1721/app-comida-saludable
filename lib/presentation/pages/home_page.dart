import 'package:flutter/material.dart';
import 'package:emprendedor/presentation/pages/home_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Se eliminan todas las variables y la lógica de navegación
  // porque el Scaffold principal y la navegación se gestionan en MainAppShell.

  @override
  Widget build(BuildContext context) {
    // Retorna directamente el contenido de la página,
    // que es tu HomeScreen.
    return const HomeScreen();
  }
}