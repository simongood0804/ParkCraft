# 车辆视觉优化 —— SVG 俯视车型

> **状态**：`已完成（V2 - PNG参考图重制）`
>
> **实现时间**：2026-07-01
>
> **更新时间**：2026-07-01（根据PNG参考图重制全部9个SVG）
>
> **实现版本**：`e72ff46` → `SVG V2`

---

## 1. 方案

### 技术选型
- 每个车型一个独立 `.svg` 文件（约 1~2KB）
- **俯视角度（从正上方90°看车辆轮廓）**，参考 `assets/vehicles/*.png` 真实照片风格
- Flutter 通过 `flutter_svg` + `SvgPicture.asset` 渲染
- 使用 `Stack(CustomPaint + Positioned(SvgPicture))` 叠加，车辆在上层

### 车型清单

| 长度 | 车型 | 文件 | 俯视特征 (V2 PNG参考) |
|------|------|------|----------|
| 3 | 公交车 | `bus.svg` | 黄色长车身 + 多侧窗 + 屋顶空调机组 + 黑色腰线 |
| 3 | 半挂卡车 | `semi_truck.svg` | 蓝色驾驶室(带格栅) + 红色集装箱(波纹板) |
| 3 | 水泥搅拌车 | `cement_truck.svg` | 绿色驾驶室 + 大型白色搅拌罐(螺旋纹理) + 液压缸 + 操作平台 |
| 3 | 危险品运输车 | `hazmat_truck.svg` | 红色驾驶室 + 银色罐体 + 深灰双色带 + **黄色危险条纹** + **警示菱形标志⚠** |
| 2 | 跑车 | `sports_car.svg` | **紫色宽扁低趴** + 引擎舱可见 + 轻量侧镜 + 进气口 |
| 2 | 出租车 | `taxi.svg` | **红车身+白顶** + TAXI顶灯牌 + 金色装饰条 |
| 2 | 救护车 | `ambulance.svg` | **白色方箱体** + 四角红灯 + 前部红灯条 + **红十字标识** + 天线 |
| 2 | 小轿车 | `sedan.svg` | **深灰色流线轿车** + 天窗 + 前后风挡玻璃 + 后窗 |
| 2 | 警车(目标车) | `police.svg` | **蓝/白分色车身** + 红/蓝警灯条 + 天线 + "POLICE"字样 |

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
| `assets/vehicles/*.svg` | 9 个俯视车型 SVG 文件（V2，基于PNG参考图） |
| `assets/vehicles/*.png` | 9 个PNG参考图文件 |
| `gen_levels.py` | 关卡生成器（保留） |

## 3. 变更记录

### V2 更新 (2026-07-01)
- 根据 `assets/vehicles/*.png` 参考图重新绘制全部 9 个 SVG
- 所有 SVG 统一为**正上方90°俯视角度**
- 各车型特征对齐 PNG 参考：
  - **sedan**: 深灰流线轿车，天窗、前后风挡、侧后镜
  - **police**: 蓝/白双色，警灯条(红+蓝+白)，天线，POLICE标识
  - **taxi**: 经典红车身+白顶配色，TAXI顶灯
  - **sports_car**: 紫色超跑，宽扁低趴造型，引擎舱透过玻璃可见
  - **ambulance**: 白色方箱救护车，四角红灯，红十字，前部警灯条
  - **bus**: 黄色长公交车，8个侧窗，2个空调机组，黑腰线
  - **semi_truck**: 蓝色美式长头卡车+红色波纹集装箱
  - **cement_truck**: 绿色欧式平头卡车+大型白色水泥搅拌罐+操作平台
  - **hazmat_truck**: 红色卡车+银色双色调罐体+黄色危险条纹+警示菱形

### V1 初始版本 (2026-07-01)
- 初次实现 SVG 车型替换纯色色块方案
- 使用 flutter_svg 渲染 SVG 图片资源
