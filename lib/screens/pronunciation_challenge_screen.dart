import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/kidio_models.dart';
import '../providers/pronunciation_provider.dart';
import '../repositories/tts_repository.dart';
import '../api/api_client.dart';

class PronunciationChallengeScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final String lessonId;

  const PronunciationChallengeScreen({
    super.key,
    required this.vocabularies,
    required this.lessonId,
  });

  @override
  State<PronunciationChallengeScreen> createState() => _PronunciationChallengeScreenState();
}

class _PronunciationChallengeScreenState extends State<PronunciationChallengeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isAudioPlaying = false;
  PronunciationScore? _currentScore;

  @override
  void initState() {
    super.initState();
    _currentScore = null;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _playCurrentWord() async {
    if (_isAudioPlaying) return;
    setState(() => _isAudioPlaying = true);

    try {
      final vocab = widget.vocabularies[_currentIndex];
      final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
      final baseUrl = dioBaseUrl.endsWith('/api/')
          ? dioBaseUrl.substring(0, dioBaseUrl.length - 5)
          : dioBaseUrl;

      String audioPath;
      if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty) {
        audioPath = vocab.audioUrl!;
      } else {
        final ttsRepo = context.read<TtsRepository>();
        final response = await ttsRepo.synthesize(vocab.word).timeout(const Duration(seconds: 5));
        audioPath = response.audioUrl;
      }

      String fullUrl = audioPath.startsWith('http')
          ? audioPath
          : '$baseUrl${audioPath.startsWith('/') ? '' : '/'}$audioPath';
      if (fullUrl.contains('192.168.') || fullUrl.contains('10.')) {
        fullUrl = fullUrl.replaceFirst('https://', 'http://').replaceFirst(':7014', ':5109');
      }

      await _audioPlayer.play(UrlSource(fullUrl)).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Audio Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAudioPlaying = false);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/pron_challenge_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _currentScore = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng cấp quyền Micro để sử dụng tính năng này.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopAndSubmit() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null && mounted) {
        final file = File(path);
        if (await file.exists()) {
          _showScoringOverlay();

          final pronProvider = context.read<PronunciationProvider>();
          final vocab = widget.vocabularies[_currentIndex];

          await pronProvider.submitPronunciation(
            vocabularyId: vocab.id,
            audioFile: file,
            lessonId: widget.lessonId,
          );

          if (mounted) {
            Navigator.pop(context); // Close scoring dialog
            final score = pronProvider.lastScore;
            if (score != null) {
              setState(() {
                _currentScore = score;
              });
              _playTtsFeedback(score.overallScore >= 60);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi: ${pronProvider.errorMessage ?? "Chưa có điểm"}')),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _playTtsFeedback(bool success) async {
    try {
      if (success) {
        await _audioPlayer.play(UrlSource(
            'https://dict.youdao.com/dictvoice?audio=great+job&type=1'));
      } else {
        await _audioPlayer.play(UrlSource(
            'https://dict.youdao.com/dictvoice?audio=try+again&type=1'));
      }
    } catch (e) {
      debugPrint('Feedback voice error: $e');
    }
  }

  void _showScoringOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.pinkAccent),
            const SizedBox(height: 20),
            const Text(
              'AI is evaluating...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF102D54),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đang lắng nghe và chấm điểm phát âm!',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _nextWord() {
    if (_currentIndex < widget.vocabularies.length - 1) {
      setState(() {
        _currentIndex++;
        _currentScore = null;
      });
    } else {
      _showChallengeComplete();
    }
  }

  void _showChallengeComplete() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF2E93), Color(0xFF8B5CF6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'YOU ARE A STAR! 🎤',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate().shake(duration: 800.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'Con phát âm rất chuẩn xác!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Medal representation
                      const Text('🏆', style: TextStyle(fontSize: 80))
                          .animate()
                          .scale(duration: 500.ms)
                          .shake(),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                            ],
                          ),
                          child: const Text(
                            'QUAY LẠI HOẠT ĐỘNG',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF102D54),
                            ),
                          ),
                        ),
                      ).animate().slideY(begin: 0.2, delay: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vocabularies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pronunciation Challenge')),
        body: const Center(child: Text('Không có từ vựng nào.')),
      );
    }

    final vocab = widget.vocabularies[_currentIndex];
    final double progress = (_currentIndex + 1) / widget.vocabularies.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFFD1DF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Top header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF102D54), size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Word ${_currentIndex + 1}/${widget.vocabularies.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102D54),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.pink.shade50,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                  ),
                ),
                const SizedBox(height: 24),

                // Vocabulary Card Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const Text(
                            'SPEAK THIS WORD 🎤',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.pinkAccent,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Target Word text
                          Text(
                            vocab.word,
                            style: const TextStyle(
                              fontFamily: 'Fredoka One',
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF102D54),
                            ),
                          ).animate(key: ValueKey(vocab.id)).shake(duration: 600.ms),

                          // Listen sound helper
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _playCurrentWord,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.volume_up_rounded, color: Colors.blue.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Nghe trước',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Record button or AI feedback results
                          if (_currentScore == null) ...[
                            // Big microphone record button
                            GestureDetector(
                              onTap: () {
                                if (_isRecording) {
                                  _stopAndSubmit();
                                } else {
                                  _startRecording();
                                }
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRecording ? Colors.red : Colors.pinkAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isRecording ? Colors.red : Colors.pinkAccent)
                                          .withOpacity(0.3),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ).animate(target: _isRecording ? 1 : 0).scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.15, 1.15),
                                    duration: 500.ms,
                                    curve: Curves.easeInOut,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isRecording ? 'Đang ghi âm... Nhấn để dừng' : 'Chạm để nói',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isRecording ? Colors.red : Colors.grey.shade600,
                              ),
                            ),
                          ] else ...[
                            // Display Score Ring & stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Score Ring
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentScore!.overallScore >= 60
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    border: Border.all(
                                      color: _currentScore!.overallScore >= 60
                                          ? Colors.green
                                          : Colors.orange,
                                      width: 8,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_currentScore!.overallScore}',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: _currentScore!.overallScore >= 60
                                              ? Colors.green.shade800
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                      const Text(
                                        'score',
                                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ).animate().scale(duration: 400.ms),

                                const SizedBox(width: 24),
                                // Sub stats
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildScoreRow('Accuracy', _currentScore!.accuracyScore),
                                    _buildScoreRow('Fluency', _currentScore!.fluencyScore),
                                    _buildScoreRow('Complete', _currentScore!.completenessScore),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Feedback message
                            Text(
                              _currentScore!.feedback.isNotEmpty
                                  ? _currentScore!.feedback
                                  : (_currentScore!.overallScore >= 80
                                      ? 'Excellent pronunciation! 🌟'
                                      : 'Good job! Keep practicing! 👍'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF102D54),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Retry or Next buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _currentScore = null;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.pinkAccent,
                                    side: const BorderSide(color: Colors.pinkAccent, width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('NÓI LẠI', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _nextWord,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('TIẾP THEO', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: score >= 60 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
          ),
        ],
      ),
    );
  }
}
