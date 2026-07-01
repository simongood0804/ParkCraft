import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/models/car.dart';
import 'package:parkcraft/services/level_parser.dart';

void main() {
  group('LevelParser', () {
    late LevelParser parser;

    setUp(() {
      parser = LevelParser();
    });

    final validJson = '''
    {
      "levelId": "test_001",
      "difficulty": "easy",
      "gridSize": 6,
      "exit": {
        "row": 2,
        "col": 5,
        "orientation": "horizontal"
      },
      "targetCar": {
        "id": "T",
        "row": 2,
        "col": 0,
        "length": 2,
        "orientation": "horizontal"
      },
      "blockingCars": [
        { "id": "A", "row": 0, "col": 0, "length": 3, "orientation": "horizontal" },
        { "id": "B", "row": 0, "col": 3, "length": 2, "orientation": "vertical" },
        { "id": "C", "row": 3, "col": 0, "length": 2, "orientation": "horizontal" }
      ]
    }
    ''';

    test('解析标准合法 JSON 应返回正确的 Level 对象', () {
      final level = parser.parseFromString(validJson);

      expect(level.levelId, 'test_001');
      expect(level.difficulty, 'easy');
      expect(level.gridSize, 6);
      expect(level.exit.row, 2);
      expect(level.exit.col, 5);
      expect(level.exit.orientation, CarOrientation.horizontal);
      expect(level.targetCar.id, 'T');
      expect(level.targetCar.length, 2);
      expect(level.targetCar.isTarget, true);
      expect(level.blockingCars.length, 3);
      expect(level.allCars.length, 4);
    });

    test('默认难度应为 easy', () {
      final json = validJson.replaceAll('"difficulty": "easy",\n    ', '');
      final level = parser.parseFromString(json);
      expect(level.difficulty, 'easy');
    });

    test('缺少必填字段应抛出 ParserException', () {
      final json = '''
      { "gridSize": 6, "exit": {}, "targetCar": {}, "blockingCars": [] }
      ''';
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('缺少 gridSize 应抛出 ParserException', () {
      final json = '''
      { "levelId": "x", "exit": {}, "targetCar": {}, "blockingCars": [] }
      ''';
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('gridSize 小于 3 应抛出异常', () {
      final json = validJson.replaceAll('"gridSize": 6', '"gridSize": 2');
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('gridSize 大于 12 应抛出异常', () {
      final json = validJson.replaceAll('"gridSize": 6', '"gridSize": 13');
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('目标车辆长度不为 2 应抛出异常', () {
      final json = validJson.replaceAll('"length": 2,', '"length": 3,');
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('堵塞车辆长度不为 2 或 3 应抛出异常', () {
      final json = validJson.replaceAll('"length": 3,', '"length": 4,');
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('车辆 ID 重复应抛出异常', () {
      final json = validJson.replaceAll('"id": "B"', '"id": "A"');
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('车辆位置重叠应抛出异常', () {
      final json = validJson.replaceAll(
        '"row": 0, "col": 3',
        '"row": 0, "col": 1',
      );
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('出口不在边界应抛出异常', () {
      final json = validJson.replaceAll('"col": 5', '"col": 4');
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('目标车辆朝向与出口不一致应抛出异常', () {
      final json = validJson.replaceAll(
        '"orientation": "horizontal"',
        '"orientation": "vertical"',
      );
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('车辆超出网格边界应抛出异常', () {
      final json = validJson.replaceAll('"row": 0, "col": 0', '"row": 0, "col": 5');
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('空字符串应抛出异常', () {
      expect(
        () => parser.parseFromString(''),
        throwsA(isA<ParserException>()),
      );
    });

    test('orientation 值无效应抛出异常', () {
      final json = validJson.replaceAll(
        '"orientation": "horizontal"',
        '"orientation": "diagonal"',
      );
      expect(
        () => parser.parseFromString(json),
        throwsA(isA<ParserException>()),
      );
    });

    test('JSON 数组格式应解析第一个元素', () {
      final arrayJson = '[$validJson]';
      final level = parser.parseFromString(arrayJson);
      expect(level.levelId, 'test_001');
    });

    test('空 JSON 数组应抛出异常', () {
      expect(
        () => parser.parseFromString('[]'),
        throwsA(isA<ParserException>()),
      );
    });

    test('垂直出口垂直目标车应校验通过', () {
      final verticalJson = '''
      {
        "levelId": "v_test",
        "gridSize": 6,
        "exit": { "row": 5, "col": 2, "orientation": "vertical" },
        "targetCar": { "id": "T", "row": 0, "col": 2, "length": 2, "orientation": "vertical" },
        "blockingCars": [
          { "id": "A", "row": 2, "col": 2, "length": 2, "orientation": "vertical" }
        ]
      }
      ''';
      final level = parser.parseFromString(verticalJson);
      expect(level.levelId, 'v_test');
      expect(level.exit.orientation, CarOrientation.vertical);
      expect(level.targetCar.orientation, CarOrientation.vertical);
    });
  });
}
