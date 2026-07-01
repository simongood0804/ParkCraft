import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';

/// 设置状态管理。
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;
  final AudioService _audio;

  late Locale _locale;
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  SettingsProvider(this._storage, this._audio) {
    _loadSettings();
  }

  void _loadSettings() {
    _soundEnabled = _storage.getSoundEnabled();
    _vibrationEnabled = _storage.getVibrationEnabled();
    _locale = Locale(_storage.getLanguage());
    AppLocalizations.currentLocale = _locale;
  }

  Locale get locale => _locale;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    AppLocalizations.currentLocale = _locale;
    await _storage.setLanguage(languageCode);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    _audio.setSoundEnabled(enabled);
    await _storage.setSoundEnabled(enabled);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _storage.setVibrationEnabled(enabled);
    notifyListeners();
  }
}
