import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/localization_service.dart';

/// 游戏操作按钮栏。
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton(
                context,
                Icons.undo,
                AppLocalizations.tr('gameUndo'),
                provider.canUndo,
                () => provider.undo(),
              ),
              _buildButton(
                context,
                Icons.refresh,
                AppLocalizations.tr('gameRestart'),
                true,
                () => _showRestartDialog(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, String label,
      bool enabled, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  void _showRestartDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('gameRestart')),
        content: Text(AppLocalizations.tr('gameRestartConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.tr('generalCancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.reset();
            },
            child: Text(AppLocalizations.tr('settingsConfirm')),
          ),
        ],
      ),
    );
  }
}
