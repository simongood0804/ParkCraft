import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/level_provider.dart';
import '../services/level_manager.dart';
import '../config/routes.dart';
import '../services/localization_service.dart';

/// 主菜单页。
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.tr('appName'),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.tr('menuSubtitle'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 64),
            _buildMenuButton(
              context,
              AppLocalizations.tr('menuStart'),
              Icons.play_arrow,
              () => _startGame(context),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              AppLocalizations.tr('menuLevels'),
              Icons.grid_view,
              () => Navigator.pushNamed(context, AppRoutes.levelSelect),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              AppLocalizations.tr('menuSettings'),
              Icons.settings,
              () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
            const SizedBox(height: 48),
            Text(
              AppLocalizations.tr('appVersion'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 240,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  void _startGame(BuildContext context) {
    final provider = context.read<LevelProvider>();
    final levels = provider.levels;
    if (levels.isEmpty) return;

    // 找第一个未完成的关卡
    LevelInfo? target;
    for (final level in levels) {
      if (!level.isCompleted && !level.isLocked) {
        target = level;
        break;
      }
    }
    target ??= levels.last;

    Navigator.pushNamed(context, AppRoutes.game, arguments: target.levelId);
  }
}
