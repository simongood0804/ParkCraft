import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/car.dart';
import '../models/exit.dart';
import '../models/level.dart';
import '../config/constants.dart';

/// 关卡配置解析异常。
class ParserException implements Exception {
  final String message;
  final String? levelId;
  ParserException(this.message, {this.levelId});

  @override
  String toString() => 'ParserException($levelId): $message';
}

/// 关卡 JSON 配置解析器。
class LevelParser {
  /// 从 JSON 字符串解析单个关卡。
  Level parseFromString(String jsonString) {
    if (jsonString.trim().isEmpty) {
      throw ParserException('JSON 内容为空');
    }

    final dynamic decoded = jsonDecode(jsonString);

    // 支持单对象和数组
    if (decoded is List) {
      if (decoded.isEmpty) {
        throw ParserException('JSON 数组为空');
      }
      return _parseJson(decoded[0] as Map<String, dynamic>);
    }

    if (decoded is Map<String, dynamic>) {
      return _parseJson(decoded);
    }

    throw ParserException('JSON 格式不支持');
  }

  /// 从 assets 资源路径解析关卡。
  Future<Level> parseFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return parseFromString(jsonString);
  }

  /// 批量解析多个关卡。
  (List<Level>, List<String>) parseMultiple(List<String> jsonStrings) {
    final levels = <Level>[];
    final errors = <String>[];
    for (final json in jsonStrings) {
      try {
        levels.add(parseFromString(json));
      } on ParserException catch (e) {
        errors.add(e.message);
      } catch (e) {
        errors.add(e.toString());
      }
    }
    return (levels, errors);
  }

  Level _parseJson(Map<String, dynamic> json) {
    // 校验必填字段
    _requireField(json, 'levelId');
    _requireField(json, 'gridSize');
    _requireField(json, 'exit');
    _requireField(json, 'targetCar');
    _requireField(json, 'blockingCars');

    final levelId = json['levelId'] as String;
    final gridSize = json['gridSize'] as int;
    final difficulty = json['difficulty'] as String? ?? 'easy';

    // 校验 gridSize 范围
    if (gridSize < appMinGridSize || gridSize > appMaxGridSize) {
      throw ParserException(
        'gridSize 必须在 $appMinGridSize~$appMaxGridSize 之间',
        levelId: levelId,
      );
    }

    // 解析出口
    final exitJson = json['exit'] as Map<String, dynamic>;
    final exit = Exit(
      row: exitJson['row'] as int,
      col: exitJson['col'] as int,
      orientation: _parseOrientation(exitJson['orientation'] as String),
    );

    // 校验出口在边界上
    final onBoundary = exit.orientation == CarOrientation.horizontal
        ? exit.col == gridSize - 1
        : exit.row == gridSize - 1;
    if (!onBoundary) {
      throw ParserException('出口必须在网格边界上', levelId: levelId);
    }

    // 解析目标车辆
    final targetJson = json['targetCar'] as Map<String, dynamic>;
    final targetCar = _parseCar(targetJson, isTarget: true, levelId: levelId);
    if (targetCar.length != appTargetCarLength) {
      throw ParserException(
        '目标车辆长度必须为 $appTargetCarLength',
        levelId: levelId,
      );
    }
    // 目标车辆朝向必须与出口一致
    if (targetCar.orientation != exit.orientation) {
      throw ParserException(
        '目标车辆朝向必须与出口一致',
        levelId: levelId,
      );
    }

    // 解析堵塞车辆
    final blockingList = json['blockingCars'] as List<dynamic>;
    final blockingCars = <Car>[];
    final ids = <String>{targetCar.id};
    for (final item in blockingList) {
      final car = _parseCar(item as Map<String, dynamic>, levelId: levelId);
      if (ids.contains(car.id)) {
        throw ParserException('车辆 ID 重复：${car.id}', levelId: levelId);
      }
      if (car.length != 2 && car.length != 3) {
        throw ParserException(
          '堵塞车辆长度只能为 2 或 3，当前：${car.length}',
          levelId: levelId,
        );
      }
      ids.add(car.id);
      blockingCars.add(car);
    }

    // 校验车辆位置不重叠
    _checkOverlap(targetCar, blockingCars, levelId);

    // 校验所有车辆不超出边界
    _checkBounds([targetCar, ...blockingCars], gridSize, levelId);

    return Level(
      levelId: levelId,
      gridSize: gridSize,
      exit: exit,
      targetCar: targetCar,
      blockingCars: blockingCars,
      difficulty: difficulty,
    );
  }

  void _requireField(Map<String, dynamic> json, String field) {
    if (!json.containsKey(field)) {
      throw ParserException('缺少必填字段：$field');
    }
  }

  // 车型分配池 —— 按长度分组，依次分配确保多样性
  static const List<VehicleType> _longTypes = [
    VehicleType.bus,
    VehicleType.semiTruck,
    VehicleType.cementTruck,
    VehicleType.hazmatTruck,
  ];
  static const List<VehicleType> _shortTypes = [
    VehicleType.sportsCar,
    VehicleType.taxi,
    VehicleType.ambulance,
    VehicleType.sedan,
  ];

  int _longIdx = 0;
  int _shortIdx = 0;

  Car _parseCar(Map<String, dynamic> json,
      {bool isTarget = false, String? levelId}) {
    final id = json['id'] as String;
    final row = json['row'] as int;
    final col = json['col'] as int;
    final length = json['length'] as int;
    final orientation = _parseOrientation(json['orientation'] as String);

    // 分配车型
    late VehicleType vt;
    if (isTarget) {
      vt = VehicleType.policeCar;
    } else if (length == 3) {
      vt = _longTypes[_longIdx % _longTypes.length];
      _longIdx++;
    } else {
      vt = _shortTypes[_shortIdx % _shortTypes.length];
      _shortIdx++;
    }

    return Car(
      id: id,
      row: row,
      col: col,
      length: length,
      orientation: orientation,
      isTarget: isTarget,
      vehicleType: vt,
    );
  }

  CarOrientation _parseOrientation(String value) {
    switch (value) {
      case 'horizontal':
        return CarOrientation.horizontal;
      case 'vertical':
        return CarOrientation.vertical;
      default:
        throw ParserException('orientation 必须为 horizontal 或 vertical');
    }
  }

  void _checkOverlap(
      Car targetCar, List<Car> blockingCars, String? levelId) {
    final occupied = <String>{};
    for (final cell in targetCar.getOccupiedCells()) {
      occupied.add('${cell.$1},${cell.$2}');
    }
    for (final car in blockingCars) {
      for (final cell in car.getOccupiedCells()) {
        if (occupied.contains('${cell.$1},${cell.$2}')) {
          throw ParserException(
            '车辆 ${car.id} 与其他车辆在 (${cell.$1},${cell.$2}) 处重叠',
            levelId: levelId,
          );
        }
        occupied.add('${cell.$1},${cell.$2}');
      }
    }
  }

  void _checkBounds(List<Car> cars, int gridSize, String? levelId) {
    for (final car in cars) {
      for (final cell in car.getOccupiedCells()) {
        if (cell.$1 < 0 ||
            cell.$1 >= gridSize ||
            cell.$2 < 0 ||
            cell.$2 >= gridSize) {
          throw ParserException(
            '车辆 ${car.id} 超出网格边界',
            levelId: levelId,
          );
        }
      }
    }
  }
}
