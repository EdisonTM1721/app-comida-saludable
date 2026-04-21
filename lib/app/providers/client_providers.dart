import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:emprendedor/presentation/controllers/client/cart_controller.dart';
import 'package:emprendedor/presentation/controllers/client/client_profile_controller.dart';
import 'package:emprendedor/presentation/controllers/client/client_order_controller.dart';
import 'package:emprendedor/presentation/controllers/client/appointment_controller.dart';

class ClientProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => ClientProfileController()),
    ChangeNotifierProvider(create: (_) => CartController()),
    ChangeNotifierProvider(create: (_) => ClientOrderController()),
    ChangeNotifierProvider(create: (_) => AppointmentController()),
  ];
}