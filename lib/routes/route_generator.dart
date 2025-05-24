import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation.dart'; // Importación corregida
import '../screens/detail_screen.dart';
import '../screens/error_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.main: // Usando AppRoutes.main en lugar de home
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      case AppRoutes.detail:
        return MaterialPageRoute(builder: (_) => const DetailScreen());
      default:
        return MaterialPageRoute(builder: (_) => const ErrorScreen());
    }
  }
}
