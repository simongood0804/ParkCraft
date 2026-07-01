import 'dart:collection';

import '../models/game_state.dart';
import 'game_engine.dart';

/// BFS 提示求解器。
class HintSolver {
  final GameEngine _engine = GameEngine();

  /// 求解从当前状态到胜利的最少步数路径。
  ///
  /// 返回 [Move] 列表，顺序执行即可通关。不可解或超时返回空列表。
  List<Move> solve(GameState state) {
    final queue = Queue<(GameState, List<Move>)>();
    final visited = HashSet<String>();

    queue.add((state.copyWith(), []));
    visited.add(state.serialize());

    while (queue.isNotEmpty) {
      if (visited.length > 100000) break;

      final (currentState, path) = queue.removeFirst();

      if (_engine.checkWin(currentState)) {
        return path;
      }

      for (final move in _engine.getAllPossibleMoves(currentState)) {
        final nextState = _engine.applyMove(currentState, move);
        final serialized = nextState.serialize();

        if (!visited.contains(serialized)) {
          visited.add(serialized);
          queue.add((nextState, [...path, move]));
        }
      }
    }

    return [];
  }

  /// 仅获取下一步建议。
  Move? getNextHint(GameState state) {
    final path = solve(state);
    if (path.isEmpty) return null;
    return path.first;
  }

}
