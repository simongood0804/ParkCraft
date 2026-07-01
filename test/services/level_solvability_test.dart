import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/services/level_manager.dart';
import 'package:parkcraft/services/level_parser.dart';
import 'package:parkcraft/services/game_engine.dart';
import 'package:parkcraft/services/hint_solver.dart';

void main() {
  late LevelParser parser;
  late GameEngine engine;
  late HintSolver solver;

  setUp(() {
    parser = LevelParser();
    engine = GameEngine();
    solver = HintSolver();
  });

  for (final assetPath in kBuiltInLevelAssets) {
    test('${assetPath.replaceAll('assets/levels/', '')} 应有解',
        () {
      final filePath = assetPath;
      final file = File(filePath);
      expect(file.existsSync(), true,
          reason: '关卡文件 $filePath 不存在');

      final json = file.readAsStringSync();
      final level = parser.parseFromString(json);
      final state = engine.loadLevel(level);

      final path = solver.solve(state);

      expect(path.isNotEmpty, true,
          reason: '关卡 ${level.levelId} 无解！'
              '(${level.difficulty}, ${level.gridSize}×${level.gridSize})');
    }, timeout: const Timeout(Duration(seconds: 30)));
  }
}
