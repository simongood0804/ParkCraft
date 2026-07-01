import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'services/level_manager.dart';
import 'providers/settings_provider.dart';
import 'providers/level_provider.dart';
import 'services/localization_service.dart';
import 'config/theme.dart';
import 'config/routes.dart';

/// ParkCraft 应用根组件。
class ParkCraftApp extends StatefulWidget {
  const ParkCraftApp({super.key});

  @override
  State<ParkCraftApp> createState() => _ParkCraftAppState();
}

class _ParkCraftAppState extends State<ParkCraftApp> {
  final StorageService _storage = StorageService();
  final AudioService _audio = AudioService();

  late final SettingsProvider _settingsProvider;
  late final LevelProvider _levelProvider;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _storage.init();
    await _audio.init();

    _settingsProvider = SettingsProvider(_storage, _audio);
    _levelProvider = LevelProvider(LevelManager(_storage));

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider.value(value: _levelProvider),
        Provider.value(value: _audio),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppLocalizations.tr('appName'),
            theme: AppTheme.lightTheme,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
