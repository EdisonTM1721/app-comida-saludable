import 'package:provider/single_child_widget.dart';

import 'entrepreneur_providers.dart';
import 'client_providers.dart';
import 'nutritionist_providers.dart';

class AppProviders {
  static List<SingleChildWidget> providers = [
    ...EntrepreneurProviders.providers,
    ...ClientProviders.providers,
    ...NutritionistProviders.providers,
  ];
}