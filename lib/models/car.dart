/// 车辆在网格中的朝向。
enum CarOrientation {
  horizontal,
  vertical,
}

/// 网格中的一辆车。
class Car {
  final String id;
  int row;
  int col;
  final int length;
  final CarOrientation orientation;
  final bool isTarget;

  Car({
    required this.id,
    required this.row,
    required this.col,
    required this.length,
    required this.orientation,
    this.isTarget = false,
  });

  /// 获取车辆占用的所有格子坐标。
  List<(int row, int col)> getOccupiedCells() {
    final cells = <(int, int)>[];
    for (int i = 0; i < length; i++) {
      if (orientation == CarOrientation.horizontal) {
        cells.add((row, col + i));
      } else {
        cells.add((row + i, col));
      }
    }
    return cells;
  }

  /// 深拷贝。
  Car copyWith({int? row, int? col}) {
    return Car(
      id: id,
      row: row ?? this.row,
      col: col ?? this.col,
      length: length,
      orientation: orientation,
      isTarget: isTarget,
    );
  }

  @override
  String toString() => 'Car($id: [${isTarget ? "T" : "B"}] '
      '($row,$col) len=$length $orientation)';
}
