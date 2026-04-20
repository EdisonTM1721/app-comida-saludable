import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/app/providers/app_providers.dart';
import 'package:emprendedor/core/theme/app_theme.dart';
import 'package:emprendedor/presentation/pages/auth/auth_wrapper.dart';
import 'package:emprendedor/presentation/shared/widgets/user_session_initializer.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp(
        title: 'App Emprendedor',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        locale: const Locale('es', 'ES'),
        theme: AppTheme.build(),
        home: const UserSessionInitializer(
          child: AuthWrapper(),
        ),
      ),
    );
  }
}