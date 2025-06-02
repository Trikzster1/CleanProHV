import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/detail_screen.dart';
import '../screens/error_screen.dart';
import '../routes/app_routes.dart';
import '../screens/home_screen.dart'; // Asegúrate que aquí esté Residence

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.main:
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      case AppRoutes.detail:
        final residence = settings.arguments as Residence;
        return MaterialPageRoute(
          builder: (_) => DetailScreen(residence: residence),
        );
      default:
        return MaterialPageRoute(builder: (_) => const ErrorScreen());
    }
  }
}
