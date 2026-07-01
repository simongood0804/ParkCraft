import 'dart:async';

/// 游戏统计数据跟踪器（步数 + 计时）。
class StatsTracker {
  int _moveCount = 0;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  void Function(Duration elapsed)? onTick;

  /// 重置所有统计。
  void reset() {
    _moveCount = 0;
    _stopwatch.reset();
    _timer?.cancel();
    _timer = null;
  }

  /// 记录一步移动。
  void recordMove() {
    _moveCount++;
  }

  /// 步数减一（撤销时调用），不会减到负数。
  void unrecordMove() {
    if (_moveCount > 0) _moveCount--;
  }

  /// 开始计时，每秒回调 [onTick]。
  void start() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      onTick?.call(_stopwatch.elapsed);
    });
  }

  /// 暂停计时。
  void pause() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  /// 恢复计时。
  void resume() {
    start();
  }

  /// 停止计时。
  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  int get moveCount => _moveCount;
  Duration get elapsed => _stopwatch.elapsed;
  int get elapsedSeconds => _stopwatch.elapsedMilliseconds ~/ 1000;
}
