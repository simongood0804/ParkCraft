import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/models/car.dart';
import 'package:parkcraft/models/exit.dart';
import 'package:parkcraft/models/game_state.dart';
import 'package:parkcraft/services/collision_detector.dart';

void main() {
  group('CollisionDetector', () {
    GameState createState() {
      final cars = [
        Car(id: 'A', row: 0, col: 0, length: 3, orientation: CarOrientation.horizontal),
        Car(id: 'B', row: 0, col: 3, length: 2, orientation: CarOrientation.vertical),
        Car(id: 'T', row: 2, col: 0, length: 2, orientation: CarOrientation.horizontal, isTarget: true),
        Car(id: 'C', row: 2, col: 2, length: 3, orientation: CarOrientation.horizontal),
        Car(id: 'D', row: 4, col: 0, length: 3, orientation: CarOrientation.horizontal),
      ];
      return GameState(
        gridSize: 6,
        cars: cars,
        exit: Exit(row: 2, col: 5, orientation: CarOrientation.horizontal),
        targetCarId: 'T',
      );
    }

    test('空路移动不应碰撞', () {
      final state = createState();
      final car = state.cars[4]; // D 车在 row=4, col=0

      expect(CollisionDetector.wouldCollide(state, car, 1), false);
    });

    test('车辆移动后与其他车重叠应碰撞', () {
      final state = createState();
      final car = state.cars[0]; // A 车在 row=0, col=0，向右移

      // A 车向右移 1 格会碰到 B 车 (B 占据 row=0,col=3 和 row=1,col=3)
      // A 移动后占据 (0,1)(0,2)(0,3) → 与 B 的 (0,3) 重叠
      expect(CollisionDetector.wouldCollide(state, car, 2), true);
    });

    test('目标车从出口方向移出不应碰撞', () {
      final state = createState();
      state.cars[2].col = 4; // 将 T 车移到 col=4，再移 1 步即可出界
      final target = state.cars[2]; // T 车

      // T 车从 (2,4) 向右移 1 步 → 占据 (2,4)(2,5)，然后车头 col+2=6 > gridSize=6
      // 但 C 车在 (2,2) length=3 占据 (2,2)(2,3)(2,4)，所以 T 移到 (2,4) 已重叠
      // 重新设置：T 在 (2,4), C 移到别处
      state.cars[3].row = 3; // C 车移到 row=3

      expect(CollisionDetector.wouldCollide(state, target, 1), false);
    });

    test('非出口方向越界应碰撞', () {
      final state = createState();
      final car = state.cars[0]; // A 车在 row=0, col=0

      // 尝试向左移（超出左边界）
      expect(CollisionDetector.wouldCollide(state, car, -1), true);
    });

    test('垂直车移动与其他车重叠应碰撞', () {
      final state = createState();
      final car = state.cars[1]; // B 垂直车在 row=0, col=3，length=2

      // 向下移 1 格 → (1,3)(2,3)，C 车占据 (2,3)，应碰撞
      expect(CollisionDetector.wouldCollide(state, car, 1), true);
    });

    test('垂直车空路移动不应碰撞', () {
      final state = createState();
      // 将 C 车移开让出空间
      state.cars[3].row = 3;
      final car = state.cars[1]; // B 垂直车在 row=0, col=3，length=2

      // 向下移 1 格 → (1,3)(2,3)，C 车已移开，不应碰撞
      expect(CollisionDetector.wouldCollide(state, car, 1), false);
    });

    test('获取合法移动范围', () {
      final state = createState();
      final car = state.cars[4]; // D 在 row=4, col=0，水平 3 格

      final (min, max) = CollisionDetector.getValidMoveRange(state, car);

      // D 占据 (4,0)(4,1)(4,2)，右边到 col=5 无阻挡
      expect(min, 0); // 左侧是边界，不能左移
      expect(max, 3); // 向右可移 3 格到 col=3
    });
  });
}
