# 车辆视觉优化 —— SVG 俯视车型

> **状态**：`已实现`
>
> **实现时间**：2026-07-01
> **实现版本**：`e72ff46`

---

## 1. 方案

### 技术选型
- 每个车型一个独立 `.svg` 文件（约 1~1.5KB）
- 俯视角度（从正上方看车辆轮廓）
- Flutter 通过 `flutter_svg` + `SvgPicture.asset` 渲染
- 使用 `Stack(CustomPaint + Positioned(SvgPicture))` 叠加，车辆在上层

### 车型清单

| 长度 | 车型 | 文件 | 俯视特征 |
|------|------|------|----------|
| 3 | 公交车 | `bus.svg` | 长方形车身 + 前挡风 + 4 侧窗 + 后窗 |
| 3 | 半挂卡车 | `semi_truck.svg` | 独立车头 + 货柜 + 货柜门线 |
| 3 | 水泥搅拌车 | `cement_truck.svg` | 车头 + 椭圆形搅拌罐 + 罐体横纹 |
| 3 | 危险品运输车 | `hazmat_truck.svg` | 红色车头 + 黄色货柜 + 危险菱形 ⚠ |
| 2 | 跑车 | `sports_car.svg` | 流线型轮廓 + 前唇 + 尾翼 + 大面积车窗 |
| 2 | 出租车 | `taxi.svg` | 黄色 + 棋盘格条纹 + TAXI 顶灯 + 挡风玻璃 |
| 2 | 救护车 | `ambulance.svg` | 白色 + 红蓝条纹 + 红色十字 + 警灯条 |
| 2 | 小轿车 | `sedan.svg` | 标准轿车 + 前后风挡 + 侧窗 |
| 2 | 警车 | `police.svg` | 黑白分段 + 红蓝条纹 + POLICE 文字 + 警灯条 |

### 渲染方式

```
Stack:
  ├── CustomPaint (网格线 + 出口箭头 + 选中高亮)
  └── Positioned × N (每辆车)
        ├── SvgPicture.asset(svgAsset, fit: BoxFit.contain)
        └── RotatedBox (quarterTurns:1) ← 垂直车旋转90°
```

## 2. 实现文件

| 文件 | 说明 |
|------|------|
| `lib/models/car.dart` | 新增 `VehicleType` 枚举、`svgAsset` getter |
| `lib/services/level_parser.dart` | 解析时根据 length 自动分配车型 |
| `lib/widgets/game_grid.dart` | `GridPainter` 仅画网格/出口/选中；`CarSvgWidget` 渲染车型 |
| `lib/widgets/game_grid_widget.dart` | `Stack` 叠加层 |
| `pubspec.yaml` | 添加 `flutter_svg` 依赖、`assets/vehicles/` 目录 |
| `assets/vehicles/*.svg` | 9 个俯视车型 SVG 文件 |
| `gen_levels.py` | 关卡生成器（保留） |

## 3. 后续可改进

- 添加车灯、保险杠等细节提升真实感
- 不同车型使用不同的颜色方案（目前保留原有颜色逻辑）
- 支持自定义涂装
