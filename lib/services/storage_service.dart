import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// 关卡通关记录。
class LevelProgress {
  final int bestMoves;
  final int bestTimeSeconds;
  final bool completed;
  final int playCount;
  final DateTime? lastPlayedAt;

  LevelProgress({
    required this.bestMoves,
    required this.bestTimeSeconds,
    required this.completed,
    this.playCount = 1,
    this.lastPlayedAt,
  });

  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      bestMoves: json['bestMoves'] as int,
      bestTimeSeconds: json['bestTime'] as int,
      completed: json['completed'] as bool,
      playCount: json['playCount'] as int? ?? 1,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'bestMoves': bestMoves,
        'bestTime': bestTimeSeconds,
        'completed': completed,
        'playCount': playCount,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      };

  bool isNewBest(int moves, int timeSeconds) {
    if (!completed) return true;
    return moves < bestMoves ||
        (moves == bestMoves && timeSeconds < bestTimeSeconds);
  }

  LevelProgress mergeWith(int moves, int timeSeconds) {
    final newBest = isNewBest(moves, timeSeconds);
    return LevelProgress(
      bestMoves: newBest ? moves : bestMoves,
      bestTimeSeconds: newBest ? timeSeconds : bestTimeSeconds,
      completed: true,
      playCount: playCount + 1,
      lastPlayedAt: DateTime.now(),
    );
  }
}

/// 持久化存储服务。
class StorageService {
  static const String _progressBoxName = 'levelProgress';
  static const String _settingsBoxName = 'settings';
  static const String _customLevelsBoxName = 'customLevels';

  late Box<String> _progressBox;
  late Box<String> _settingsBox;
  late Box<String> _customLevelsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _progressBox = await Hive.openBox<String>(_progressBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
    _customLevelsBox = await Hive.openBox<String>(_customLevelsBoxName);
  }

  // ─── 关卡进度 ───

  Future<void> saveLevelProgress(
      String levelId, LevelProgress progress) async {
    await _progressBox.put(levelId, jsonEncode(progress.toJson()));
  }

  LevelProgress? getLevelProgress(String levelId) {
    final raw = _progressBox.get(levelId);
    if (raw == null) return null;
    try {
      return LevelProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Map<String, LevelProgress> getAllProgress() {
    final result = <String, LevelProgress>{};
    for (final key in _progressBox.keys) {
      if (key == 'highestUnlocked') continue;
      final progress = getLevelProgress(key);
      if (progress != null) result[key] = progress;
    }
    return result;
  }

  String? get highestUnlocked {
    return _progressBox.get('highestUnlocked');
  }

  Future<void> setHighestUnlocked(String levelId) async {
    await _progressBox.put('highestUnlocked', levelId);
  }

  Future<void> clearAllProgress() async {
    await _progressBox.clear();
  }

  // ─── 设置 ───

  bool getSoundEnabled() {
    return _settingsBox.get('soundEnabled', defaultValue: 'true') == 'true';
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _settingsBox.put('soundEnabled', enabled.toString());
  }

  bool getVibrationEnabled() {
    return _settingsBox.get('vibrationEnabled', defaultValue: 'true') == 'true';
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _settingsBox.put('vibrationEnabled', enabled.toString());
  }

  String getLanguage() {
    return _settingsBox.get('language', defaultValue: 'zh') ?? 'zh';
  }

  Future<void> setLanguage(String languageCode) async {
    await _settingsBox.put('language', languageCode);
  }

  // ─── 自定义关卡 ───

  Future<void> saveCustomLevel(String levelId, String jsonContent) async {
    await _customLevelsBox.put(levelId, jsonContent);
  }

  String? getCustomLevel(String levelId) {
    return _customLevelsBox.get(levelId);
  }

  List<String> getCustomLevelIds() {
    return _customLevelsBox.keys.cast<String>().toList();
  }

  Future<void> deleteCustomLevel(String levelId) async {
    await _customLevelsBox.delete(levelId);
  }
}
