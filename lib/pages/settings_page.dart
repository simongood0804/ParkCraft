import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/level_provider.dart';
import '../services/localization_service.dart';

/// 设置页。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr('menuSettings')),
      ),
      body: Consumer2<SettingsProvider, LevelProvider>(
        builder: (context, settings, levelProvider, _) {
          return ListView(
            children: [
              SwitchListTile(
                title: Text(AppLocalizations.tr('settingsSound')),
                value: settings.soundEnabled,
                onChanged: (v) => settings.setSoundEnabled(v),
              ),
              SwitchListTile(
                title: Text(AppLocalizations.tr('settingsVibration')),
                value: settings.vibrationEnabled,
                onChanged: (v) => settings.setVibrationEnabled(v),
              ),
              ListTile(
                title: Text(AppLocalizations.tr('settingsLanguage')),
                trailing: DropdownButton<String>(
                  value: settings.locale.languageCode,
                  items: [
                    DropdownMenuItem(value: 'zh', child: Text(AppLocalizations.tr('languageZh'))),
                    DropdownMenuItem(value: 'en', child: Text(AppLocalizations.tr('languageEn'))),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.setLanguage(v);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(AppLocalizations.tr('settingsReset')),
                trailing: TextButton(
                  onPressed: () => _showResetDialog(context, levelProvider),
                  child: Text(AppLocalizations.tr('settingsReset')),
                ),
              ),
              const SizedBox(height: 32),
              Center(child: Text(AppLocalizations.tr('appVersion'))),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(
      BuildContext context, LevelProvider levelProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('settingsReset')),
        content: Text(AppLocalizations.tr('settingsResetConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.tr('settingsCancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              levelProvider.resetAllProgress();
            },
            child: Text(AppLocalizations.tr('settingsConfirm')),
          ),
        ],
      ),
    );
  }
}
