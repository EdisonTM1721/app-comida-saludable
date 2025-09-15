import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          logger.info("Usuario no autenticado. Navegando a LoginPage.");
          _clearControllers(context);
          return const LoginPage();
        }

        logger.info("Usuario autenticado. ID: ${user.uid}");
        _updateControllers(context, user.uid);

        return Consumer<ProfileController>(
          builder: (context, profileController, child) {
            if (profileController.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return profileController.hasProfile
                ? const MainAppShell()
                : const BusinessProfileEditPage();
          },
        );
      },
    );
  }

  void _updateControllers(BuildContext context, String userId) {
    Provider.of<ProductController>(context, listen: false).setUserId(userId);
    Provider.of<OrderController>(context, listen: false).setUserId(userId);
    Provider.of<StatsController>(context, listen: false).setUserId(userId);
    Provider.of<PromotionController>(context, listen: false).setUserId(userId);
    Provider.of<ProfileController>(context, listen: false).setUserId(userId);
    Provider.of<SocialMediaController>(context, listen: false).setUserId(userId);
    Provider.of<PaymentMethodController>(context, listen: false).setUserId(userId);
  }

  void _clearControllers(BuildContext context) {
    Provider.of<ProductController>(context, listen: false).setUserId(null);
    Provider.of<OrderController>(context, listen: false).setUserId(null);
    Provider.of<StatsController>(context, listen: false).setUserId(null);
    Provider.of<PromotionController>(context, listen: false).setUserId(null);
    Provider.of<ProfileController>(context, listen: false).setUserId(null);
    Provider.of<SocialMediaController>(context, listen: false).setUserId(null);
    Provider.of<PaymentMethodController>(context, listen: false).setUserId(null);
  }
}
