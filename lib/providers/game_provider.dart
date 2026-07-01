import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../services/game_engine.dart';
import '../services/undo_manager.dart';
import '../services/stats_tracker.dart';
import '../services/hint_solver.dart';
import '../services/audio_service.dart';
import '../services/collision_detector.dart';

/// 游戏页面状态管理。
class GameProvider extends ChangeNotifier {
  final GameEngine _engine = GameEngine();
  final UndoManager _undoManager = UndoManager();
  final StatsTracker _stats = StatsTracker();
  final HintSolver _hintSolver = HintSolver();
  final AudioService _audio;
  final void Function(String levelId, int moves, int timeSeconds) _onWin;

  GameState? _state;
  Level? _currentLevel; // 保存原始关卡用于重置
  bool _isPaused = false;
  bool _isCompleted = false;
  Move? _currentHint;

  GameProvider({
    required AudioService audio,
    required void Function(String levelId, int moves, int timeSeconds) onWin,
  })  : _audio = audio,
        _onWin = onWin;

  GameState? get state => _state;
  int get moveCount => _stats.moveCount;
  int get elapsedSeconds => _stats.elapsedSeconds;
  bool get isPaused => _isPaused;
  bool get isCompleted => _isCompleted;
  bool get canUndo => _undoManager.canUndo;
  Move? get currentHint => _currentHint;

  void loadLevel(Level level) {
    _currentLevel = level;
    _state = _engine.loadLevel(level);
    _undoManager.clear();
    _stats.reset();
    _isPaused = false;
    _isCompleted = false;
    _currentHint = null;
    notifyListeners();
  }

  bool moveCar(String carId, int steps) {
    if (_state == null || _isCompleted) return false;

    final car = _state!.cars.firstWhere((c) => c.id == carId);
    if (CollisionDetector.wouldCollide(_state!, car, steps)) {
      return false;
    }

    _undoManager.recordBeforeMove(_state!, carId);

    _engine.tryMove(_state!, carId, steps);
    _stats.recordMove();
    _currentHint = null;
    _audio.playMoveSound();

    if (_engine.checkWin(_state!)) {
      _isCompleted = true;
      _stats.stop();
      _audio.playWinSound();
      _onWin('', _stats.moveCount, _stats.elapsedSeconds);
    }

    notifyListeners();
    return true;
  }

  void undo() {
    if (_state == null || !_undoManager.canUndo) return;

    final snapshot = _undoManager.undo();
    if (snapshot != null) {
      final car = _state!.cars.firstWhere((c) => c.id == snapshot.carId);
      car.row = snapshot.fromRow;
      car.col = snapshot.fromCol;
      _stats.unrecordMove();
      _currentHint = null;
      notifyListeners();
    }
  }

  /// 重置关卡：从保存的原始 Level 重新加载。
  void reset() {
    if (_currentLevel == null) return;
    loadLevel(_currentLevel!);
    _stats.start();
    notifyListeners();
  }

  void requestHint() {
    if (_state == null) return;
    final hint = _hintSolver.getNextHint(_state!);
    _currentHint = hint;
    notifyListeners();
  }

  void startTimer() {
    _stats.start();
  }

  void pause() {
    _isPaused = true;
    _stats.pause();
    _audio.pauseBGM();
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    _stats.resume();
    _audio.resumeBGM();
    notifyListeners();
  }
}
