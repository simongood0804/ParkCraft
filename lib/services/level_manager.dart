import '../models/level.dart';
import 'level_parser.dart';
import 'storage_service.dart';

/// 内置关卡资源路径列表。
///
/// 难度按步数划分：初阶 15~20 / 中阶 21~29 / 高阶 30~44
/// 所有关卡均为 6×6 网格，出口不在拐角。
const List<String> kBuiltInLevelAssets = [
  'assets/levels/easy/level_001.json',
  'assets/levels/easy/level_002.json',
  'assets/levels/easy/level_003.json',
  'assets/levels/easy/level_004.json',
  'assets/levels/medium/level_005.json',
  'assets/levels/medium/level_006.json',
  'assets/levels/medium/level_007.json',
  'assets/levels/medium/level_008.json',
  'assets/levels/hard/level_009.json',
  'assets/levels/hard/level_010.json',
  'assets/levels/hard/level_011.json',
  'assets/levels/hard/level_012.json',
];

/// 关卡元数据（用于 UI 展示）。
class LevelInfo {
  final String levelId;
  final int gridSize;
  final String difficulty;
  final bool isLocked;
  final bool isCompleted;
  final int? bestMoves;
  final int? bestTimeSeconds;

  LevelInfo({
    required this.levelId,
    required this.gridSize,
    required this.difficulty,
    this.isLocked = false,
    this.isCompleted = false,
    this.bestMoves,
    this.bestTimeSeconds,
  });

  LevelInfo copyWith({
    bool? isLocked,
    bool? isCompleted,
    int? bestMoves,
    int? bestTimeSeconds,
  }) {
    return LevelInfo(
      levelId: levelId,
      gridSize: gridSize,
      difficulty: difficulty,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
      bestMoves: bestMoves ?? this.bestMoves,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
    );
  }
}

/// 关卡管理器。
class LevelManager {
  final LevelParser _parser = LevelParser();
  final StorageService _storage;

  final List<Level> _loadedLevels = [];
  List<LevelInfo> _levelInfos = [];

  LevelManager(this._storage);

  List<LevelInfo> get levelInfos => List.unmodifiable(_levelInfos);
  List<Level> get loadedLevels => List.unmodifiable(_loadedLevels);

  Future<void> initialize() async {
    await _loadBuiltInLevels();
    _restoreProgress();
  }

  Future<void> _loadBuiltInLevels() async {
    for (final assetPath in kBuiltInLevelAssets) {
      try {
        final level = await _parser.parseFromAsset(assetPath);
        _loadedLevels.add(level);
      } catch (e) {
        // ignore: avoid_print
        print('加载关卡失败: $assetPath — $e');
      }
    }
  }

  void _restoreProgress() {
    final allProgress = _storage.getAllProgress();
    final highest = _storage.highestUnlocked;

    _levelInfos = _loadedLevels.asMap().entries.map((entry) {
      final level = entry.value;
      final index = entry.key;
      final progress = allProgress[level.levelId];

      final isLocked = index > 0 &&
          (highest == null ||
              _loadedLevels.indexWhere(
                      (l) => l.levelId == highest) < index);

      return LevelInfo(
        levelId: level.levelId,
        gridSize: level.gridSize,
        difficulty: level.difficulty,
        isLocked: isLocked,
        isCompleted: progress?.completed ?? false,
        bestMoves: progress?.bestMoves,
        bestTimeSeconds: progress?.bestTimeSeconds,
      );
    }).toList();
  }

  Level? getLevel(String levelId) {
    for (final level in _loadedLevels) {
      if (level.levelId == levelId) return level;
    }
    return null;
  }

  Future<String> importLevel(String jsonString) async {
    final level = _parser.parseFromString(jsonString);
    _loadedLevels.add(level);

    _levelInfos.add(LevelInfo(
      levelId: level.levelId,
      gridSize: level.gridSize,
      difficulty: level.difficulty,
      isLocked: false,
    ));

    await _storage.saveCustomLevel(level.levelId, jsonString);
    return level.levelId;
  }

  Future<void> markCompleted(
      String levelId, int moves, int timeSeconds) async {
    final existing = _storage.getLevelProgress(levelId);
    final progress = existing != null
        ? existing.mergeWith(moves, timeSeconds)
        : LevelProgress(
            bestMoves: moves,
            bestTimeSeconds: timeSeconds,
            completed: true,
          );

    await _storage.saveLevelProgress(levelId, progress);

    final index = _levelInfos.indexWhere((l) => l.levelId == levelId);
    if (index >= 0 && index + 1 < _levelInfos.length) {
      final nextLevelId = _levelInfos[index + 1].levelId;
      await _storage.setHighestUnlocked(nextLevelId);
    }

    _restoreProgress();
  }

  String? getNextLevelId(String currentLevelId) {
    final index = _levelInfos.indexWhere((l) => l.levelId == currentLevelId);
    if (index >= 0 && index + 1 < _levelInfos.length) {
      return _levelInfos[index + 1].levelId;
    }
    return null;
  }

  List<LevelInfo> getLevelsByDifficulty(String difficulty) {
    return _levelInfos.where((l) => l.difficulty == difficulty).toList();
  }

  Future<void> resetAllProgress() async {
    await _storage.clearAllProgress();
    _restoreProgress();
  }
}
