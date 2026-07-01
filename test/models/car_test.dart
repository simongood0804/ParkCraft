import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/models/car.dart';

void main() {
  group('Car', () {
    test('水平车辆应返回正确的占据格子', () {
      final car = Car(
        id: 'A',
        row: 2,
        col: 3,
        length: 3,
        orientation: CarOrientation.horizontal,
      );

      final cells = car.getOccupiedCells();

      expect(cells.length, 3);
      expect(cells[0], (2, 3));
      expect(cells[1], (2, 4));
      expect(cells[2], (2, 5));
    });

    test('垂直车辆应返回正确的占据格子', () {
      final car = Car(
        id: 'B',
        row: 1,
        col: 0,
        length: 2,
        orientation: CarOrientation.vertical,
      );

      final cells = car.getOccupiedCells();

      expect(cells.length, 2);
      expect(cells[0], (1, 0));
      expect(cells[1], (2, 0));
    });

    test('copyWith 应深拷贝', () {
      final car = Car(
        id: 'T',
        row: 0,
        col: 0,
        length: 2,
        orientation: CarOrientation.horizontal,
        isTarget: true,
      );

      final copy = car.copyWith(row: 1);

      expect(copy.id, 'T');
      expect(copy.row, 1);
      expect(copy.col, 0);
      expect(copy.length, 2);
      expect(copy.orientation, CarOrientation.horizontal);
      expect(copy.isTarget, true);

      // 原对象不变
      expect(car.row, 0);
    });

    test('目标车辆 isTarget 应为 true', () {
      final car = Car(
        id: 'T',
        row: 0,
        col: 0,
        length: 2,
        orientation: CarOrientation.horizontal,
        isTarget: true,
      );

      expect(car.isTarget, true);
    });

    test('堵塞车辆 isTarget 应为 false', () {
      final car = Car(
        id: 'A',
        row: 0,
        col: 0,
        length: 3,
        orientation: CarOrientation.horizontal,
      );

      expect(car.isTarget, false);
    });
  });
}
