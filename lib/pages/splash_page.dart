import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/level_provider.dart';
import '../config/routes.dart';
import '../services/localization_service.dart';

/// 启动页。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 最少展示时间
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final levelProvider = context.read<LevelProvider>();
    await levelProvider.loadLevels();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.menu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.tr('appName'),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.tr('generalLoading')),
          ],
        ),
      ),
    );
  }
}
