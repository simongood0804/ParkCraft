import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/level_provider.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../widgets/game_grid_widget.dart';
import '../widgets/info_bar.dart';
import '../widgets/action_buttons.dart';

/// 游戏主页面。
class GamePage extends StatefulWidget {
  final String levelId;
  const GamePage({super.key, required this.levelId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late GameProvider _gameProvider;

  @override
  void initState() {
    super.initState();
    final audio = context.read<AudioService>();
    final levelProvider = context.read<LevelProvider>();

    _gameProvider = GameProvider(
      audio: audio,
      onWin: (levelId, moves, timeSeconds) {
        levelProvider.onLevelCompleted(
            widget.levelId, moves, timeSeconds);
      },
    );

    final level = levelProvider.getLevelData(widget.levelId);
    if (level != null) {
      _gameProvider.loadLevel(level);
      _gameProvider.startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameProvider,
      child: Consumer<GameProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.pause),
                onPressed: () => _showPauseDialog(context, provider),
              ),
              title: Text(AppLocalizations.tr('appName')),
            ),
            body: Column(
              children: [
                const InfoBar(),
                const Spacer(),
                const GameGrid(),
                const Spacer(),
                const ActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPauseDialog(BuildContext context, GameProvider provider) {
    provider.pause();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('gamePaused')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.tr('gameMoves')}: ${provider.moveCount}',
            ),
            Text(
              '${AppLocalizations.tr('gameTime')}: ${_formatTime(provider.elapsedSeconds)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.resume();
            },
            child: Text(AppLocalizations.tr('gameResume')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.resume();
              provider.reset();
            },
            child: Text(AppLocalizations.tr('gameRestart')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // 返回关卡选择
            },
            child: Text(AppLocalizations.tr('gameBackToMenu')),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
