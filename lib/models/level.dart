import 'car.dart';
import 'exit.dart';

/// 关卡信息。
class Level {
  final String levelId;
  final int gridSize;
  final Exit exit;
  final Car targetCar;
  final List<Car> blockingCars;
  final String difficulty;

  Level({
    required this.levelId,
    required this.gridSize,
    required this.exit,
    required this.targetCar,
    required this.blockingCars,
    this.difficulty = 'easy',
  });

  List<Car> get allCars => [targetCar, ...blockingCars];
}
