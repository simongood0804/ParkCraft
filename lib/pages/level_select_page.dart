import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/level_provider.dart';
import '../config/routes.dart';
import '../services/localization_service.dart';
import '../services/level_manager.dart';

/// 关卡选择页。
class LevelSelectPage extends StatelessWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.tr('menuLevels')),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.tr('levelEasy')),
              Tab(text: AppLocalizations.tr('levelMedium')),
              Tab(text: AppLocalizations.tr('levelHard')),
            ],
          ),
        ),
        body: Consumer<LevelProvider>(
          builder: (context, provider, _) {
            switch (provider.state) {
              case LevelLoadState.loading:
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在加载关卡...'),
                    ],
                  ),
                );
              case LevelLoadState.error:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadLevels(),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              case LevelLoadState.loaded:
                return TabBarView(
                  children: [
                    _buildLevelGrid(context, provider, 'easy'),
                    _buildLevelGrid(context, provider, 'medium'),
                    _buildLevelGrid(context, provider, 'hard'),
                  ],
                );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showImportDialog(context),
          tooltip: AppLocalizations.tr('importTitle'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildLevelGrid(
      BuildContext context, LevelProvider provider, String difficulty) {
    final levels = provider.levels
        .where((l) => l.difficulty == difficulty)
        .toList();

    if (levels.isEmpty) {
      return Center(child: Text(AppLocalizations.tr('levelNoLevels')));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: levels.length,
      itemBuilder: (_, index) => _buildLevelCard(context, levels[index]),
    );
  }

  Widget _buildLevelCard(BuildContext context, LevelInfo info) {
    final number = info.levelId.replaceAll('level_', '');
    final isUnlocked = !info.isLocked;
    final isCompleted = info.isCompleted;

    return GestureDetector(
      onTap: isUnlocked
          ? () => Navigator.pushNamed(
                context,
                AppRoutes.game,
                arguments: info.levelId,
              )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green.shade50
              : isUnlocked
                  ? Theme.of(context).colorScheme.surface
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.grey.shade300,
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.black87 : Colors.grey,
              ),
            ),
            if (info.isLocked)
              const Icon(Icons.lock, size: 32, color: Colors.grey),
            if (isCompleted && info.bestMoves != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '★${info.bestMoves}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('importTitle')),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: AppLocalizations.tr('importJsonHint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.tr('generalCancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<LevelProvider>();
              final result = await provider.importLevelFromJson(
                  controller.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? AppLocalizations.tr('importSuccess')
                          : '${AppLocalizations.tr('importFail')}: ${result.errorMessage}',
                    ),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.tr('generalOk')),
          ),
        ],
      ),
    );
  }
}
