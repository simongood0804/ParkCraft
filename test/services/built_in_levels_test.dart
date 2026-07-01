import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/services/level_manager.dart';

void main() {
  test('所有内置关卡配置应合法', () {
    // 验证内置关卡列表不为空
    expect(kBuiltInLevelAssets.isNotEmpty, true,
        reason: 'kBuiltInLevelAssets 应为空');

    // 验证所有路径以 assets/ 开头且以 .json 结尾
    for (final path in kBuiltInLevelAssets) {
      expect(path.startsWith('assets/'), true,
          reason: '$path 应以 assets/ 开头');
      expect(path.endsWith('.json'), true,
          reason: '$path 应以 .json 结尾');
    }
  });

  test('关卡数量至少 12 个', () {
    expect(kBuiltInLevelAssets.length >= 12, true,
        reason: '内置关卡数量：${kBuiltInLevelAssets.length}');
  });

  test('每个难度至少有 3 个关卡', () {
    final easy = kBuiltInLevelAssets.where((p) => p.contains('/easy/')).length;
    final medium = kBuiltInLevelAssets.where((p) => p.contains('/medium/')).length;
    final hard = kBuiltInLevelAssets.where((p) => p.contains('/hard/')).length;

    expect(easy >= 3, true, reason: '简单关卡：$easy');
    expect(medium >= 4, true, reason: '中等关卡：$medium');
    expect(hard >= 4, true, reason: '困难关卡：$hard');
  });
}
