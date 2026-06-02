import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final _isPlayingController = StreamController<bool>.broadcast();

  AudioPlayerService() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlayingController.add(state == PlayerState.playing);
    });
  }

  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  Future<void> play(String url) async {
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      print("AudioPlayer error: $e");
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
    _isPlayingController.close();
  }
}
