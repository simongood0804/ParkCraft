import 'package:flutter/material.dart';

/// 国际化服务。
class AppLocalizations {
  static Locale currentLocale = const Locale('zh', 'CN');

  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  static const Map<String, Map<String, String>> _translations = {
    'zh': {
      'appName': 'ParkCraft',
      'menuSubtitle': '停车出库益智游戏',
      'appVersion': 'v1.0.0',
      'menuStart': '开始游戏',
      'menuLevels': '关卡选择',
      'menuSettings': '设置',
      'levelEasy': '简单',
      'levelMedium': '中等',
      'levelHard': '困难',
      'levelNoLevels': '暂无关卡',
      'gamePause': '暂停',
      'gameResume': '继续',
      'gameRestart': '重开',
      'gameRestartConfirm': '确定要重开当前关卡吗？',
      'gameUndo': '撤销',
      'gameHint': '提示',
      'gameMoves': '步数',
      'gameTime': '用时',
      'gamePaused': '游戏暂停',
      'gameWinTitle': '恭喜通关！',
      'gameWinNewRecord': '最佳记录！',
      'gameNextLevel': '下一关',
      'gameBackToMenu': '返回菜单',
      'gameNoHint': '暂无可用的提示',
      'settingsSound': '音效',
      'settingsVibration': '震动反馈',
      'settingsLanguage': '语言',
      'settingsReset': '重置游戏进度',
      'settingsResetConfirm': '确定要重置所有游戏进度吗？此操作不可撤销。',
      'settingsConfirm': '确定',
      'settingsCancel': '取消',
      'languageZh': '中文',
      'languageEn': 'English',
      'levelLocked': '未解锁',
      'levelCompleted': '已完成',
      'importTitle': '导入关卡',
      'importFromFile': '从文件导入',
      'importPaste': '粘贴 JSON',
      'importJsonHint': '粘贴关卡 JSON 配置...',
      'importSuccess': '关卡导入成功',
      'importFail': '关卡导入失败',
      'generalOk': '确定',
      'generalCancel': '取消',
      'generalLoading': '加载中...',
    },
    'en': {
      'appName': 'ParkCraft',
      'menuSubtitle': 'Parking Puzzle',
      'appVersion': 'v1.0.0',
      'menuStart': 'Start Game',
      'menuLevels': 'Level Select',
      'menuSettings': 'Settings',
      'levelEasy': 'Easy',
      'levelMedium': 'Medium',
      'levelHard': 'Hard',
      'levelNoLevels': 'No levels',
      'gamePause': 'Pause',
      'gameResume': 'Resume',
      'gameRestart': 'Restart',
      'gameRestartConfirm': 'Restart current level?',
      'gameUndo': 'Undo',
      'gameHint': 'Hint',
      'gameMoves': 'Moves',
      'gameTime': 'Time',
      'gamePaused': 'Game Paused',
      'gameWinTitle': 'Congratulations!',
      'gameWinNewRecord': 'New Record!',
      'gameNextLevel': 'Next Level',
      'gameBackToMenu': 'Back to Menu',
      'gameNoHint': 'No hint available',
      'settingsSound': 'Sound',
      'settingsVibration': 'Vibration',
      'settingsLanguage': 'Language',
      'settingsReset': 'Reset Progress',
      'settingsResetConfirm': 'Reset all progress? This cannot be undone.',
      'settingsConfirm': 'Confirm',
      'settingsCancel': 'Cancel',
      'languageZh': 'Chinese',
      'languageEn': 'English',
      'levelLocked': 'Locked',
      'levelCompleted': 'Completed',
      'importTitle': 'Import Level',
      'importFromFile': 'From File',
      'importPaste': 'Paste JSON',
      'importJsonHint': 'Paste level JSON config...',
      'importSuccess': 'Level imported',
      'importFail': 'Import failed',
      'generalOk': 'OK',
      'generalCancel': 'Cancel',
      'generalLoading': 'Loading...',
    },
  };

  static String tr(String key, {Map<String, String>? params}) {
    final langCode = currentLocale.languageCode;
    var text = _translations[langCode]?[key] ??
        _translations['en']?[key] ??
        key;

    if (params != null) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }
}
