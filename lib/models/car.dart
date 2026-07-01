/// 车辆类型枚举。
enum VehicleType {
  bus,
  semiTruck,
  cementTruck,
  hazmatTruck,
  sportsCar,
  taxi,
  ambulance,
  sedan,
  policeCar,
}

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
  final VehicleType vehicleType;

  Car({
    required this.id,
    required this.row,
    required this.col,
    required this.length,
    required this.orientation,
    this.isTarget = false,
    required this.vehicleType,
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
      vehicleType: vehicleType,
    );
  }

  /// SVG 资源文件名。
  String get svgAsset {
    if (isTarget) return 'assets/vehicles/police.svg';
    switch (vehicleType) {
      case VehicleType.bus:
        return 'assets/vehicles/bus.svg';
      case VehicleType.semiTruck:
        return 'assets/vehicles/semi_truck.svg';
      case VehicleType.cementTruck:
        return 'assets/vehicles/cement_truck.svg';
      case VehicleType.hazmatTruck:
        return 'assets/vehicles/hazmat_truck.svg';
      case VehicleType.sportsCar:
        return 'assets/vehicles/sports_car.svg';
      case VehicleType.taxi:
        return 'assets/vehicles/taxi.svg';
      case VehicleType.ambulance:
        return 'assets/vehicles/ambulance.svg';
      case VehicleType.sedan:
        return 'assets/vehicles/sedan.svg';
      case VehicleType.policeCar:
        return 'assets/vehicles/police.svg';
    }
  }

  @override
  String toString() => 'Car($id: $vehicleType '
      '($row,$col) len=$length $orientation)';
}
