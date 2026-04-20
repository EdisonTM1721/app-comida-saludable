import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:emprendedor/presentation/controllers/nutritionist/nutritionist_profile_controller.dart';

class NutritionistProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => NutritionistProfileController()),
  ];
}