import 'package:flutter/material.dart';
import '../pages/splash_page.dart';
import '../pages/menu_page.dart';
import '../pages/level_select_page.dart';
import '../pages/game_page.dart';
import '../pages/settings_page.dart';

/// 应用路由。
class AppRoutes {
  static const String splash = '/splash';
  static const String menu = '/menu';
  static const String levelSelect = '/levels';
  static const String game = '/game';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.splash) {
      return MaterialPageRoute(builder: (_) => const SplashPage());
    }
    if (settings.name == AppRoutes.menu) {
      return MaterialPageRoute(builder: (_) => const MenuPage());
    }
    if (settings.name == AppRoutes.levelSelect) {
      return MaterialPageRoute(builder: (_) => const LevelSelectPage());
    }
    if (settings.name == AppRoutes.game) {
      final levelId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => GamePage(levelId: levelId),
      );
    }
    if (settings.name == AppRoutes.settings) {
      return MaterialPageRoute(builder: (_) => const SettingsPage());
    }
    return MaterialPageRoute(builder: (_) => const SplashPage());
  }
}
