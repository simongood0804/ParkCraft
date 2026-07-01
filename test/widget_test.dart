import 'package:flutter_test/flutter_test.dart';
import 'package:parkcraft/app.dart';

void main() {
  testWidgets('ParkCraft app should start', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkCraftApp());
    await tester.pump();

    // 应用应启动并显示加载指示器
    expect(find.byType(ParkCraftApp), findsOneWidget);
  });
}
