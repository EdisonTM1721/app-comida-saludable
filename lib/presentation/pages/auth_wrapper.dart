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
  final Map<Type, ChangeNotifier> _controllers = {};
  String? _currentUserId;

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          _disposeControllers();
          _currentUserId = null;
          logger.info("Usuario no autenticado. Navegando a LoginPage.");
          return const LoginPage();
        }

        final user = snapshot.data!;
        final userId = user.uid;

        if (_currentUserId != userId) {
          _disposeControllers();
          _currentUserId = userId;

          _controllers[ProductController] = ProductController();
          _controllers[OrderController] = OrderController();
          _controllers[StatsController] = StatsController();
          _controllers[PromotionController] = PromotionController();
          _controllers[ProfileController] = ProfileController();
          _controllers[SocialMediaController] = SocialMediaController();
          _controllers[PaymentMethodController] = PaymentMethodController();
        }

        return FutureBuilder<void>(
          future: Future.wait<void>([
            (_controllers[ProductController] as ProductController).setUserId(userId),
            (_controllers[OrderController] as OrderController).setUserId(userId),
            (_controllers[StatsController] as StatsController).setUserId(userId),
            (_controllers[PromotionController] as PromotionController).setUserId(userId),
            (_controllers[ProfileController] as ProfileController).setUserId(userId),
            (_controllers[SocialMediaController] as SocialMediaController).setUserId(userId),
            (_controllers[PaymentMethodController] as PaymentMethodController).setUserId(userId),
          ]),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (futureSnapshot.hasError) {
              logger.severe("Error al inicializar los datos: ${futureSnapshot.error}");
              return const Center(child: Text('Error al inicializar los datos del usuario.'));
            }

            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(
                    value: _controllers[ProductController] as ProductController),
                ChangeNotifierProvider.value(
                    value: _controllers[OrderController] as OrderController),
                ChangeNotifierProvider.value(
                    value: _controllers[StatsController] as StatsController),
                ChangeNotifierProvider.value(
                    value: _controllers[PromotionController] as PromotionController),
                ChangeNotifierProvider.value(
                    value: _controllers[ProfileController] as ProfileController),
                ChangeNotifierProvider.value(
                    value: _controllers[SocialMediaController] as SocialMediaController),
                ChangeNotifierProvider.value(
                    value: _controllers[PaymentMethodController] as PaymentMethodController),
              ],
              child: Consumer<ProfileController>(
                builder: (context, profileController, child) {
                  if (profileController.isLoading) {
                    return const Scaffold(
                        body: Center(child: CircularProgressIndicator()));
                  }
                  return profileController.hasProfile
                      ? const MainAppShell()
                      : const BusinessProfileEditPage();
                },
              ),
            );
          },
        );
      },
    );
  }
}
