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

/// 关卡列表状态管理。
class LevelProvider extends ChangeNotifier {
  final LevelManager _manager;

  LevelProvider(this._manager);

  List<LevelInfo> get levels => _manager.levelInfos;

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
    await _manager.initialize();
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
