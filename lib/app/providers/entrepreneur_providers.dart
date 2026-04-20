import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:emprendedor/presentation/controllers/entrepreneur/order_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/payment_method_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/product_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/profile_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/promotion_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/social_media_controller.dart';
import 'package:emprendedor/presentation/controllers/entrepreneur/stats_controller.dart';

class EntrepreneurProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => ProductController()),
    ChangeNotifierProvider(create: (_) => OrderController()),
    ChangeNotifierProvider(create: (_) => StatsController()),
    ChangeNotifierProvider(create: (_) => PromotionController()),
    ChangeNotifierProvider(create: (_) => ProfileController()),
    ChangeNotifierProvider(create: (_) => SocialMediaController()),
    ChangeNotifierProvider(create: (_) => PaymentMethodController()),
  ];
}