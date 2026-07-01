import 'car.dart';

/// 网格出口。
class Exit {
  final int row;
  final int col;
  final CarOrientation orientation;

  const Exit({
    required this.row,
    required this.col,
    required this.orientation,
  });
}
