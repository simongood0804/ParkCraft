import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/models/car.dart';
import 'package:parkcraft/models/exit.dart';
import 'package:parkcraft/models/level.dart';
import 'package:parkcraft/services/game_engine.dart';

void main() {
  group('GameEngine', () {
    late GameEngine engine;
    late Level testLevel;

    setUp(() {
      engine = GameEngine();
      testLevel = Level(
        levelId: 'test',
        gridSize: 6,
        exit: Exit(row: 2, col: 5, orientation: CarOrientation.horizontal),
        targetCar: Car(
          id: 'T',
          row: 2,
          col: 0,
          length: 2,
          orientation: CarOrientation.horizontal, vehicleType: VehicleType.policeCar,
          isTarget: true,
        ),
        blockingCars: [
          Car(id: 'A', row: 0, col: 0, length: 3, orientation: CarOrientation.horizontal, vehicleType: VehicleType.bus),
          Car(id: 'B', row: 0, col: 3, length: 2, orientation: CarOrientation.vertical, vehicleType: VehicleType.sedan),
          Car(id: 'C', row: 2, col: 2, length: 3, orientation: CarOrientation.horizontal, vehicleType: VehicleType.bus),
          Car(id: 'D', row: 4, col: 0, length: 3, orientation: CarOrientation.horizontal, vehicleType: VehicleType.bus),
        ],
      );
    });

    test('loadLevel 应创建正确的 GameState', () {
      final state = engine.loadLevel(testLevel);

      expect(state.gridSize, 6);
      expect(state.cars.length, 5);
      expect(state.targetCarId, 'T');
      expect(state.exit.orientation, CarOrientation.horizontal);

      // 确保深拷贝，修改不影响原始 level
      state.cars[0].col = 99;
      expect(testLevel.blockingCars[0].col, 0);
    });

    test('tryMove 成功移动车辆应返回 true', () {
      final state = engine.loadLevel(testLevel);
      final carD = state.cars[4]; // D 在 (4,0) 水平 3 格

      final result = engine.tryMove(state, carD.id, 1);

      expect(result, true);
      expect(carD.col, 1); // 从 col=0 移到 col=1
    });

    test('tryMove 碰撞时应返回 false 且不移动车辆', () {
      final state = engine.loadLevel(testLevel);
      final carA = state.cars[0]; // A 在 (0,0) 水平 3 格

      // 向右移 2 格会碰到 B (0,3)
      final result = engine.tryMove(state, carA.id, 2);

      expect(result, false);
      expect(carA.col, 0); // 位置不变
    });

    test('tryMove 对不存在的车辆 ID 应返回 false', () {
      final state = engine.loadLevel(testLevel);
      expect(engine.tryMove(state, 'NONEXIST', 1), false);
    });

    test('垂直车移动', () {
      final state = engine.loadLevel(testLevel);
      final carB = state.cars[1]; // B 垂直车在 (0,3)

      // 向上移不合法（边界）
      expect(engine.tryMove(state, carB.id, -1), false);

      // C 车在 (2,2)(2,3)(2,4)，所以 B 向下 1 步到 (1,3)(2,3) 与 C 碰撞
      expect(engine.tryMove(state, carB.id, 1), false);
    });

    test('checkWin 目标车未驶出应返回 false', () {
      final state = engine.loadLevel(testLevel);
      expect(engine.checkWin(state), false);
    });

    test('checkWin 目标车完全驶出出口应返回 true', () {
      final state = engine.loadLevel(testLevel);
      // 将 C 车移开，T 推到出口
      state.cars[3].row = 3; // C 移到 row=3

      // 先将 T 推到 col=4，占据 (2,4)(2,5)
      state.targetCar.col = 4;
      // 再推 1 格 → (2,5)(2,6)，col+length=6 > gridSize=6
      engine.tryMove(state, 'T', 1);

      expect(engine.checkWin(state), true);
    });

    test('胜利判定：垂直目标车驶出', () {
      final level = Level(
        levelId: 'v_test',
        gridSize: 6,
        exit: Exit(row: 5, col: 2, orientation: CarOrientation.vertical),
        targetCar: Car(
          id: 'T', row: 0, col: 2, length: 2,
          orientation: CarOrientation.vertical, isTarget: true, vehicleType: VehicleType.policeCar,
        ),
        blockingCars: [],
      );
      final state = engine.loadLevel(level);

      // T 在 (0,2)(1,2)，推到 row=4 → (4,2)(5,2)
      state.targetCar.row = 4;
      expect(engine.checkWin(state), false);

      // 再推 1 格 → (5,2)(6,2) → row+length=6 > gridSize=6
      state.targetCar.row = 5;
      expect(engine.checkWin(state), true);
    });

    test('getValidMoveRange 返回正确的范围', () {
      final state = engine.loadLevel(testLevel);
      final carD = state.cars[4]; // D 在 (4,0) 水平 3 格

      final (min, max) = engine.getValidMoveRange(state, carD.id);

      expect(min, 0); // 左侧是边界 0，不能左移
      expect(max, 3); // 向右可移 3 格到 col=3（col=4 时撞到网格边界）
    });

    test('getAllPossibleMoves 返回所有合法单步移动', () {
      // 创建一个只有目标车的简单关卡
      final simpleLevel = Level(
        levelId: 'simple',
        gridSize: 4,
        exit: Exit(row: 0, col: 3, orientation: CarOrientation.horizontal),
        targetCar: Car(
          id: 'T', row: 0, col: 0, length: 2,
          orientation: CarOrientation.horizontal, isTarget: true, vehicleType: VehicleType.policeCar,
        ),
        blockingCars: [
          Car(id: 'A', row: 1, col: 0, length: 2, orientation: CarOrientation.vertical, vehicleType: VehicleType.sedan),
        ],
      );
      final state = engine.loadLevel(simpleLevel);

      final moves = engine.getAllPossibleMoves(state);

      // T 可右移 1 步（左移撞边界），A 可下移 1 步（上移撞边界）
      expect(moves.any((m) => m.carId == 'T' && m.steps == 1), true);
      expect(moves.any((m) => m.carId == 'A' && m.steps == 1), true);
      expect(moves.any((m) => m.steps == -1), false); // 没有车可以向后移动
    });

    test('applyMove 返回新状态不修改原状态', () {
      final state = engine.loadLevel(testLevel);
      final originalCol = state.cars[4].col;

      final newState = engine.applyMove(state, Move('D', 1));

      // 原状态不变
      expect(state.cars[4].col, originalCol);
      // 新状态已移动
      expect(newState.cars[4].col, originalCol + 1);
    });

    test('Moves 不能互相跨越（间接碰撞）', () {
      // A 和 B 紧密排列，B 不能穿过 A
      final level = Level(
        levelId: 'block',
        gridSize: 5,
        exit: Exit(row: 0, col: 4, orientation: CarOrientation.horizontal),
        targetCar: Car(
          id: 'T', row: 0, col: 0, length: 2,
          orientation: CarOrientation.horizontal, isTarget: true, vehicleType: VehicleType.policeCar,
        ),
        blockingCars: [
          Car(id: 'A', row: 0, col: 2, length: 2, orientation: CarOrientation.horizontal, vehicleType: VehicleType.sedan),
        ],
      );
      final state = engine.loadLevel(level);

      // T 在 (0,0)(0,1)，A 在 (0,2)(0,3)，T 最多只能右移 1 格到 (0,1)(0,2) 与 A 接触
      expect(engine.tryMove(state, 'T', 1), true);
      expect(engine.tryMove(state, 'T', 1), false); // 再移 1 格会撞 A
    });
  });
}
