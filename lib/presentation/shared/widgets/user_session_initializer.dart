import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/order_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/payment_method_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/product_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/social_media_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/stats_controller.dart';
import 'package:emprendedor/presentation/controllers/client/client_order_controller.dart';

class UserSessionInitializer extends StatefulWidget {
  final Widget child;

  const UserSessionInitializer({
    super.key,
    required this.child,
  });

  @override
  State<UserSessionInitializer> createState() => _UserSessionInitializerState();
}

class _UserSessionInitializerState extends State<UserSessionInitializer> {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
        ) async {
      if (!mounted) return;

      await _syncControllers(user?.uid);
    });
  }

  Future<void> _syncControllers(String? userId) async {
    await Future.wait([
      context.read<ProductController>().setUserId(userId),
      context.read<OrderController>().setBusinessUserId(userId),
      context.read<StatsController>().setUserId(userId),
      context.read<ProfileController>().setUserId(userId),
      context.read<PromotionController>().setUserId(userId),
      context.read<SocialMediaController>().setUserId(userId),
      context.read<PaymentMethodController>().setUserId(userId),
      context.read<ClientOrderController>().setUserId(userId),
    ]);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}