import 'package:flutter/material.dart';
import 'package:emprendedor/presentation/pages/home_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // Retorna directamente el contenido de la página,
    // que es tu HomeScreen.
    // Envuelve el HomeScreen en un Container con un color blanco
    // para asegurar que el fondo sea visible.
    return Container(
      color: Colors.white,
      child: const HomeScreen(),
    );
  }
}