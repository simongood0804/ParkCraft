import 'car.dart';
import 'exit.dart';
import 'level.dart';

/// 游戏运行时状态（可变）。
class GameState {
  final int gridSize;
  final List<Car> cars;
  final Exit exit;
  final String targetCarId;

  GameState({
    required this.gridSize,
    required this.cars,
    required this.exit,
    required this.targetCarId,
  });

  /// 从 Level 创建初始 GameState。
  factory GameState.fromLevel(Level level) {
    return GameState(
      gridSize: level.gridSize,
      cars: level.allCars.map((c) => c.copyWith()).toList(),
      exit: level.exit,
      targetCarId: level.targetCar.id,
    );
  }

  /// 获取指定位置的车辆，无车返回 null。
  Car? carAt(int row, int col) {
    for (final car in cars) {
      final cells = car.getOccupiedCells();
      for (final cell in cells) {
        if (cell.$1 == row && cell.$2 == col) return car;
      }
    }
    return null;
  }

  /// 获取目标车辆。
  Car get targetCar => cars.firstWhere((c) => c.id == targetCarId);

  /// 序列化为字符串（用于 BFS 判重）。
  String serialize() {
    final sorted = List<Car>.from(cars)
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted.map((c) => '${c.id}:${c.row}:${c.col}').join('|');
  }

  /// 深拷贝。
  GameState copyWith({List<Car>? cars}) {
    return GameState(
      gridSize: gridSize,
      cars: cars ?? this.cars.map((c) => c.copyWith()).toList(),
      exit: exit,
      targetCarId: targetCarId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GameState && serialize() == other.serialize();

  @override
  int get hashCode => serialize().hashCode;
}
