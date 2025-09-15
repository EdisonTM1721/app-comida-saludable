import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:emprendedor/presentation/controllers/product_controller.dart';
import 'package:emprendedor/presentation/controllers/order_controller.dart';
import 'package:emprendedor/presentation/controllers/stats_controller.dart';
import 'package:emprendedor/presentation/controllers/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/social_media_controller.dart';
import 'package:emprendedor/presentation/controllers/payment_method_controller.dart';
import 'package:emprendedor/presentation/pages/login_page.dart';
import 'package:emprendedor/presentation/pages/business_profile_edit_page.dart';
import 'package:emprendedor/presentation/pages/main_app_shell.dart';

final Logger logger = Logger('AuthWrapperLogger');

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Escucha los cambios de autenticación para actualizar los controladores
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final String? userId = user?.uid;

      // Solo si el widget está montado y el contexto es válido, actualiza los controladores
      if (mounted) {
        context.read<ProductController>().setUserId(userId);
        context.read<OrderController>().setUserId(userId);
        context.read<StatsController>().setUserId(userId);
        context.read<PromotionController>().setUserId(userId);
        context.read<ProfileController>().setUserId(userId);
        context.read<SocialMediaController>().setUserId(userId);
        context.read<PaymentMethodController>().setUserId(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          logger.info("Usuario no autenticado. Navegando a LoginPage.");
          return const LoginPage();
        }

        // Si el usuario está autenticado, muestra el shell de la app.
        return Consumer<ProfileController>(
          builder: (context, profileController, child) {
            if (profileController.isLoading) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            return profileController.hasProfile
                ? const MainAppShell()
                : const BusinessProfileEditPage();
          },
        );
      },
    );
  }
}