import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/localization_service.dart';

/// 游戏信息栏（步数 + 计时）。
class InfoBar extends StatelessWidget {
  const InfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                Icons.undo,
                AppLocalizations.tr('gameUndo'),
                () => provider.undo(),
                enabled: provider.canUndo,
              ),
              Text(
                '${AppLocalizations.tr('gameMoves')}: ${provider.moveCount}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                _formatTime(provider.elapsedSeconds),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              _buildInfoChip(
                Icons.lightbulb_outline,
                AppLocalizations.tr('gameHint'),
                () => provider.requestHint(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String tooltip, VoidCallback onTap,
      {bool enabled = true}) {
    return IconButton(
      icon: Icon(icon),
      onPressed: enabled ? onTap : null,
      tooltip: tooltip,
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
