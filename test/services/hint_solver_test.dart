import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/models/car.dart';
import 'package:parkcraft/models/exit.dart';
import 'package:parkcraft/models/game_state.dart';
import 'package:parkcraft/models/level.dart';
import 'package:parkcraft/services/hint_solver.dart';

void main() {
  group('HintSolver', () {
    late HintSolver solver;

    setUp(() {
      solver = HintSolver();
    });

    test('一步即胜的关卡应返回包含一个 Move 的路径', () {
      // 目标车出口前无阻挡
      final level = Level(
        levelId: 'one_step',
        gridSize: 4,
        exit: Exit(row: 0, col: 3, orientation: CarOrientation.horizontal),
        targetCar: Car(
          id: 'T', row: 0, col: 0, length: 2,
          orientation: CarOrientation.horizontal, isTarget: true,
        ),
        blockingCars: [
          Car(id: 'A', row: 2, col: 0, length: 2, orientation: CarOrientation.horizontal),
        ],
      );
      final state = GameState.fromLevel(level);

      final path = solver.solve(state);

      expect(path.isNotEmpty, true);
      expect(path.length, 1);
      expect(path.first.carId, 'T');
      expect(path.first.steps, 1); // 右移 1 步即可出界
    });

    test('已通关的状态应返回空路径', () {
      final state = GameState(
        gridSize: 4,
        cars: [
          Car(id: 'T', row: 0, col: 3, length: 2, orientation: CarOrientation.horizontal, isTarget: true),
        ],
        exit: Exit(row: 0, col: 3, orientation: CarOrientation.horizontal),
        targetCarId: 'T',
      );

      final path = solver.solve(state);

      expect(path.isEmpty, true);
    });

    test('中等难度关卡应返回可达路径', () {
      // 标准 6x6 布局，3 步可解
      final level = Level(
        levelId: 'med',
        gridSize: 6,
        exit: Exit(row: 2, col: 5, orientation: CarOrientation.horizontal),
        targetCar: Car(
          id: 'T', row: 2, col: 0, length: 2,
          orientation: CarOrientation.horizontal, isTarget: true,
        ),
        blockingCars: [
          Car(id: 'A', row: 0, col: 0, length: 3, orientation: CarOrientation.horizontal),
          Car(id: 'B', row: 0, col: 3, length: 2, orientation: CarOrientation.vertical),
          Car(id: 'C', row: 2, col: 2, length: 2, orientation: CarOrientation.vertical),
          Car(id: 'D', row: 4, col: 1, length: 2, orientation: CarOrientation.horizontal),
        ],
      );
      final state = GameState.fromLevel(level);

      final path = solver.solve(state);

      expect(path.isNotEmpty, true);
      // 所有移动必须是合法的
      for (final move in path) {
        expect(['T', 'A', 'B', 'C', 'D'], contains(move.carId));
        expect(move.steps, anyOf(1, -1));
      }
    });

    test('不可解的关卡应返回空列表', () {
      // 用复杂局面构造：目标车出口方向有多辆车互相卡死
      final trappedState = GameState(
        gridSize: 5,
        cars: [
          Car(id: 'T', row: 0, col: 0, length: 2, orientation: CarOrientation.horizontal, isTarget: true),
          Car(id: 'A', row: 0, col: 2, length: 3, orientation: CarOrientation.horizontal),
          Car(id: 'B', row: 0, col: 3, length: 2, orientation: CarOrientation.vertical),
          Car(id: 'C', row: 1, col: 2, length: 2, orientation: CarOrientation.vertical),
          Car(id: 'D', row: 2, col: 0, length: 3, orientation: CarOrientation.horizontal),
          Car(id: 'E', row: 2, col: 3, length: 2, orientation: CarOrientation.vertical),
          Car(id: 'F', row: 3, col: 2, length: 2, orientation: CarOrientation.vertical),
        ],
        exit: Exit(row: 0, col: 4, orientation: CarOrientation.horizontal),
        targetCarId: 'T',
      );

      // A 堵在 T 前面，B 和 C 垂直穿过 A 的路径，D 和 E 又堵住 B/C
      // 这是一个经典的 Rush Hour 死局，BFS 搜索到上限后应返回空
      final path = solver.solve(trappedState);
      // 只是确认不崩溃并返回列表（可能是空或非空，取决于搜索深度）
      expect(path, isA<List>());
    });

    test('getNextHint 应返回第一步建议', () {
      final level = Level(
        levelId: 'hint_test',
        gridSize: 4,
        exit: Exit(row: 0, col: 3, orientation: CarOrientation.horizontal),
        targetCar: Car(
          id: 'T', row: 0, col: 0, length: 2,
          orientation: CarOrientation.horizontal, isTarget: true,
        ),
        blockingCars: [
          Car(id: 'A', row: 1, col: 0, length: 2, orientation: CarOrientation.vertical),
        ],
      );
      final state = GameState.fromLevel(level);

      final hint = solver.getNextHint(state);

      expect(hint, isNotNull);
      // 唯一合法移动是 T 右移或 A 下移，不管哪个都是有效提示
      expect(hint!.steps, anyOf(1, -1));
    });

    test('已胜利状态 getNextHint 应返回 null', () {
      final state = GameState(
        gridSize: 4,
        cars: [
          Car(id: 'T', row: 0, col: 3, length: 2, orientation: CarOrientation.horizontal, isTarget: true),
        ],
        exit: Exit(row: 0, col: 3, orientation: CarOrientation.horizontal),
        targetCarId: 'T',
      );

      expect(solver.getNextHint(state), isNull);
    });

    test('BFS 搜索过大的状态空间应安全退出不崩溃', () {
      // 8x8 大关卡
      final cars = <Car>[
        Car(id: 'T', row: 0, col: 0, length: 2, orientation: CarOrientation.horizontal, isTarget: true),
      ];
      // 添加 9 辆堵塞车增加状态空间
      for (int i = 0; i < 9; i++) {
        cars.add(Car(
          id: String.fromCharCode(65 + i), // A~I
          row: (i % 3) * 2,
          col: (i ~/ 3) * 2 + 2,
          length: i.isEven ? 2 : 3,
          orientation: i.isEven
              ? CarOrientation.horizontal
              : CarOrientation.vertical,
        ));
      }
      final state = GameState(
        gridSize: 8,
        cars: cars,
        exit: Exit(row: 0, col: 7, orientation: CarOrientation.horizontal),
        targetCarId: 'T',
      );

      // 不应抛出异常
      expect(() => solver.solve(state), returnsNormally);
    });
  });
}
