# 音效与国际化模块详细设计

- **模块编号**：M8
- **对应文件**：
  - `lib/services/audio_service.dart`
  - `lib/services/localization_service.dart`
- **依赖模块**：无

---

## 第一部分：音效模块

---

## 1. 职责

负责游戏内所有音效和背景音乐的加载、播放、暂停和控制。

---

## 2. 技术选型

- **音频引擎**：`audioplayers` 插件（Flutter 生态最成熟的音频播放库）
- **音频格式**：WAV（短音效）/ MP3（背景音乐）
- **资源存储**：Flutter `assets/` 目录

---

## 3. AudioService 设计

```dart
class AudioService {
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _sfxPlayer;
  bool _soundEnabled = true;

  /// 初始化音频引擎
  Future<void> init();

  // ─── 音效播放 ───

  /// 播放车辆移动音效
  Future<void> playMoveSound();

  /// 播放通关音效
  Future<void> playWinSound();

  /// 播放按钮点击音效
  Future<void> playButtonClickSound();

  /// 播放非法操作反馈音效
  Future<void> playErrorSound();

  // ─── 背景音乐 ───

  /// 开始播放背景音乐（循环）
  Future<void> startBGM();

  /// 停止背景音乐
  Future<void> stopBGM();

  /// 暂停背景音乐
  Future<void> pauseBGM();

  /// 恢复背景音乐
  Future<void> resumeBGM();

  // ─── 全局控制 ───

  /// 设置音效开关
  void setSoundEnabled(bool enabled);

  /// 释放资源
  void dispose();
}
```

---

## 4. 音效资源清单

| 资源文件 | 播放时机 | 说明 |
|----------|----------|------|
| `assets/sounds/move.wav` | 每次车辆移动成功 | 短促"咔哒"声 |
| `assets/sounds/win.wav` | 通关时 | 欢快上升音阶 |
| `assets/sounds/click.wav` | 按钮点击 | 轻柔点击 |
| `assets/sounds/error.wav` | 非法操作 | 低沉拒绝音 |
| `assets/sounds/bgm.mp3` | 游戏进行中 | 轻松舒缓循环曲 |

---

## 5. 播放策略

- **背景音乐**：仅在游戏页和菜单页播放，暂停弹窗时自动暂停
- **音效**：随时播放，但连续快速操作时音效不叠加（同一音效再次触发时重新播放）
- **开关同步**：从 `SettingsProvider` 读取 `soundEnabled` 状态，变化时即时生效

```dart
/// 移动音效播放（带防重叠）
Future<void> playMoveSound() async {
  if (!_soundEnabled) return;
  await _sfxPlayer?.stop(); // 停止当前音效
  _sfxPlayer = AudioPlayer();
  await _sfxPlayer?.play(AssetSource('sounds/move.wav'));
}
```

---

## 6. 初始化流程

```dart
Future<void> init() async {
  _bgmPlayer = AudioPlayer();
  _sfxPlayer = AudioPlayer();

  // 设置背景音乐循环
  _bgmPlayer?.setReleaseMode(ReleaseMode.loop);

  // 设置音量
  _bgmPlayer?.setVolume(0.5);
  _sfxPlayer?.setVolume(0.8);
}
```

---

## 第二部分：国际化模块

---

## 7. 职责

1. 支持应用内多语言切换
2. 提供所有 UI 文本的多语言翻译
3. 语言切换时即时生效，无需重启应用

---

## 8. 技术选型

- **方案**：Flutter 内置的 `intl` + `flutter_localizations`
- **替代方案**：`easy_localization`（更简单但增加依赖）、`i18n_extension`
- **选择理由**：官方方案，零额外依赖，配合 ARB 文件管理翻译

---

## 9. LocalizationService 设计

```dart
class AppLocalizations {
  // 当前语言代码
  static Locale currentLocale = const Locale('zh');

  // 支持的语种
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'), // 简体中文
    Locale('en', 'US'), // 美式英语
  ];

  // 翻译映射表
  static final Map<String, Map<String, String>> _translations = {
    'zh': {
      'app_name': 'ParkCraft',
      'menu_start': '开始游戏',
      'menu_levels': '关卡选择',
      'menu_settings': '设置',
      'level_easy': '简单',
      'level_medium': '中等',
      'level_hard': '困难',
      'game_pause': '暂停',
      'game_resume': '继续',
      'game_restart': '重开',
      'game_undo': '撤销',
      'game_hint': '提示',
      'game_moves': '步数',
      'game_time': '用时',
      'game_paused': '游戏暂停',
      'game_win_title': '恭喜通关！',
      'game_win_new_record': '🏆 最佳记录！',
      'game_next_level': '下一关',
      'game_back_to_menu': '返回菜单',
      'game_no_hint': '暂无可用的提示',
      'settings_sound': '音效',
      'settings_vibration': '震动反馈',
      'settings_language': '语言',
      'settings_reset': '重置游戏进度',
      'settings_reset_confirm': '确定要重置所有游戏进度吗？此操作不可撤销。',
      'settings_confirm': '确定',
      'settings_cancel': '取消',
      'level_locked': '未解锁',
      'level_completed': '已完成',
      'import_title': '导入关卡',
      'import_from_file': '从文件导入',
      'import_paste': '粘贴 JSON',
      'import_success': '关卡导入成功',
      'import_fail': '关卡导入失败：{message}',
      'general_ok': '确定',
      'general_cancel': '取消',
      'general_loading': '加载中...',
    },
    'en': {
      'app_name': 'ParkCraft',
      'menu_start': 'Start Game',
      'menu_levels': 'Level Select',
      'menu_settings': 'Settings',
      'level_easy': 'Easy',
      'level_medium': 'Medium',
      'level_hard': 'Hard',
      'game_pause': 'Pause',
      'game_resume': 'Resume',
      'game_restart': 'Restart',
      'game_undo': 'Undo',
      'game_hint': 'Hint',
      'game_moves': 'Moves',
      'game_time': 'Time',
      'game_paused': 'Game Paused',
      'game_win_title': 'Congratulations!',
      'game_win_new_record': '🏆 New Record!',
      'game_next_level': 'Next Level',
      'game_back_to_menu': 'Back to Menu',
      'game_no_hint': 'No hint available',
      'settings_sound': 'Sound Effects',
      'settings_vibration': 'Vibration',
      'settings_language': 'Language',
      'settings_reset': 'Reset Progress',
      'settings_reset_confirm': 'Are you sure you want to reset all progress? This cannot be undone.',
      'settings_confirm': 'Confirm',
      'settings_cancel': 'Cancel',
      'level_locked': 'Locked',
      'level_completed': 'Completed',
      'import_title': 'Import Level',
      'import_from_file': 'Import from File',
      'import_paste': 'Paste JSON',
      'import_success': 'Level imported successfully',
      'import_fail': 'Import failed: {message}',
      'general_ok': 'OK',
      'general_cancel': 'Cancel',
      'general_loading': 'Loading...',
    },
  };

  /// 获取当前语言的翻译文本
  static String tr(String key, {Map<String, String>? params}) {
    final langCode = currentLocale.languageCode;
    var text = _translations[langCode]?[key]
        ?? _translations['en']?[key]
        ?? key;

    // 参数替换
    if (params != null) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }
}
```

---

## 10. App 集成

```dart
// lib/app.dart
class ParkCraftApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          AppLocalizations.currentLocale = settings.locale;

          return MaterialApp(
            title: 'ParkCraft',
            theme: AppTheme.lightTheme,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
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
```

---

## 11. SettingsProvider 扩展

```dart
class SettingsProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh');
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // ... getters ...

  void setLanguage(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
    // 持久化保存
  }

  void setSoundEnabled(bool enabled) { ... }
  void setVibrationEnabled(bool enabled) { ... }
}
```

---

## 12. 国际化文字使用示例

```dart
// 在 UI 中使用
Text(AppLocalizations.tr('menu_start'));
Text(AppLocalizations.tr('game_moves'));

// 带参数的翻译
Text(AppLocalizations.tr('import_fail', params: {'message': error}));
```

---

## 13. 扩展性

- 新增语言：在 `_translations` 中新增语言代码映射表即可
- 新增文本：在所有语言映射表中添加对应的 key 和翻译
- 建议后续使用 ARB 文件管理翻译以支持团队协作和翻译工具链

---

## 14. 单元测试要点

| 测试用例 | 预期 |
|----------|------|
| 中文环境下获取已有 key | 返回正确的中文翻译 |
| 英文环境下获取已有 key | 返回正确的英文翻译 |
| 获取不存在的 key | 返回 key 本身（保底策略） |
| 带参数替换的翻译 | 参数被正确替换 |
| 切换语言后重新获取 | 返回新语言的翻译 |
