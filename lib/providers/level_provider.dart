import 'package:flutter/material.dart';
import '../models/level.dart';
import '../services/level_manager.dart';

/// 导入结果。
class ImportResult {
  final bool success;
  final String? levelId;
  final String? errorMessage;

  ImportResult({required this.success, this.levelId, this.errorMessage});
}

/// 关卡加载状态。
enum LevelLoadState { loading, loaded, error }

/// 关卡列表状态管理。
class LevelProvider extends ChangeNotifier {
  final LevelManager _manager;

  LevelLoadState _state = LevelLoadState.loading;
  String _errorMessage = '';

  LevelProvider(this._manager);

  List<LevelInfo> get levels => _manager.levelInfos;
  LevelLoadState get state => _state;
  String get errorMessage => _errorMessage;

  bool isLevelUnlocked(String levelId) {
    final info = _findLevelInfo(levelId);
    return info != null && !info.isLocked;
  }

  bool isLevelCompleted(String levelId) {
    final info = _findLevelInfo(levelId);
    return info?.isCompleted ?? false;
  }

  String? getNextLevelId(String currentLevelId) {
    return _manager.getNextLevelId(currentLevelId);
  }

  Level? getLevelData(String levelId) {
    return _manager.getLevel(levelId);
  }

  Future<void> loadLevels() async {
    _state = LevelLoadState.loading;
    try {
      await _manager.initialize();
      if (_manager.levelInfos.isEmpty) {
        _state = LevelLoadState.error;
        _errorMessage = '关卡加载失败：所有关卡配置均解析错误';
      } else {
        _state = LevelLoadState.loaded;
      }
    } catch (e) {
      _state = LevelLoadState.error;
      _errorMessage = '关卡加载异常：$e';
    }
    notifyListeners();
  }

  Future<ImportResult> importLevelFromJson(String jsonString) async {
    try {
      final levelId = await _manager.importLevel(jsonString);
      notifyListeners();
      return ImportResult(success: true, levelId: levelId);
    } catch (e) {
      return ImportResult(success: false, errorMessage: e.toString());
    }
  }

  Future<void> onLevelCompleted(
      String levelId, int moves, int timeSeconds) async {
    await _manager.markCompleted(levelId, moves, timeSeconds);
    notifyListeners();
  }

  Future<void> resetAllProgress() async {
    await _manager.resetAllProgress();
    notifyListeners();
  }

  LevelInfo? _findLevelInfo(String levelId) {
    for (final info in _manager.levelInfos) {
      if (info.levelId == levelId) return info;
    }
    return null;
  }
}
