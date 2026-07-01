import 'package:audioplayers/audioplayers.dart';

/// 音效服务。
class AudioService {
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _sfxPlayer;
  bool _soundEnabled = true;

  Future<void> init() async {
    _bgmPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();

    await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer?.setVolume(0.5);
    await _sfxPlayer?.setVolume(0.8);
  }

  Future<void> playMoveSound() async {
    if (!_soundEnabled) return;
    await _sfxPlayer?.stop();
    _sfxPlayer = AudioPlayer();
    await _sfxPlayer?.play(AssetSource('sounds/move.wav'));
  }

  Future<void> playWinSound() async {
    if (!_soundEnabled) return;
    await _sfxPlayer?.stop();
    _sfxPlayer = AudioPlayer();
    await _sfxPlayer?.play(AssetSource('sounds/win.wav'));
  }

  Future<void> playButtonClickSound() async {
    if (!_soundEnabled) return;
    await _sfxPlayer?.stop();
    _sfxPlayer = AudioPlayer();
    await _sfxPlayer?.play(AssetSource('sounds/click.wav'));
  }

  Future<void> playErrorSound() async {
    if (!_soundEnabled) return;
    await _sfxPlayer?.stop();
    _sfxPlayer = AudioPlayer();
    await _sfxPlayer?.play(AssetSource('sounds/error.wav'));
  }

  Future<void> startBGM() async {
    if (!_soundEnabled) return;
    await _bgmPlayer?.play(AssetSource('sounds/bgm.mp3'));
  }

  Future<void> stopBGM() async {
    await _bgmPlayer?.stop();
  }

  Future<void> pauseBGM() async {
    await _bgmPlayer?.pause();
  }

  Future<void> resumeBGM() async {
    if (_soundEnabled) {
      await _bgmPlayer?.resume();
    }
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _bgmPlayer?.pause();
    } else {
      _bgmPlayer?.resume();
    }
  }

  void dispose() {
    _bgmPlayer?.dispose();
    _sfxPlayer?.dispose();
  }
}
