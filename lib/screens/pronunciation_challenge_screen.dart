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
import '../providers/child_provider.dart';
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
  bool _isScoring = false;

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
      setState(() {
        _isRecording = false;
        _isScoring = true;
      });

      if (path != null && mounted) {
        final file = File(path);
        if (await file.exists()) {
          final pronProvider = context.read<PronunciationProvider>();
          final childId = context.read<ChildProvider>().selectedChild?.id;
          final vocab = widget.vocabularies[_currentIndex];

          await pronProvider.submitPronunciation(
            childId: childId ?? '',
            vocabularyId: vocab.id,
            audioFile: file,
            lessonId: widget.lessonId,
          );

          if (mounted) {
            setState(() => _isScoring = false);
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
      setState(() => _isScoring = false);
      debugPrint('Error submitting record: $e');
    }
  }

  Future<void> _playTtsFeedback(bool isSuccess) async {
    final ttsRepo = context.read<TtsRepository>();
    try {
      final text = isSuccess ? "Great job!" : "Try again!";
      final response = await ttsRepo.synthesize(text).timeout(const Duration(seconds: 4));
      final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
      final baseUrl = dioBaseUrl.endsWith('/api/')
          ? dioBaseUrl.substring(0, dioBaseUrl.length - 5)
          : dioBaseUrl;
      String fullUrl = response.audioUrl.startsWith('http')
          ? response.audioUrl
          : '$baseUrl${response.audioUrl.startsWith('/') ? '' : '/'}${response.audioUrl}';
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      debugPrint('Tts Feedback error: $e');
    }
  }

  void _nextWord() {
    if (_currentIndex < widget.vocabularies.length - 1) {
      setState(() {
        _currentIndex++;
        _currentScore = null;
      });
      _playCurrentWord();
    } else {
      _showCompletionScreen();
    }
  }

  void _showCompletionScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'YOU ARE A STAR! 🎤',
                        style: TextStyle(
                          fontFamily: 'FredokaOne',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate().shake(duration: 800.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'Con phát âm rất xuất sắc!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 36),
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
                              fontFamily: 'FredokaOne',
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
    final double progressPct = (_currentIndex + 1) / widget.vocabularies.length;

    // Speech bubble text builder
    String mascotText = "Say: '${vocab.word.toUpperCase()}' into the mic! 🐼";
    if (_isRecording) {
      mascotText = "Listening... Speak now! 🎤";
    } else if (_isScoring) {
      mascotText = "Evaluating your pronunciation... Please wait! ⌛";
    } else if (_currentScore != null) {
      if (_currentScore!.overallScore >= 80) {
        mascotText = "Awesome job! You got ${_currentScore!.overallScore}% accuracy! 🌟";
      } else {
        mascotText = "Good try! You got ${_currentScore!.overallScore}% accuracy. Try again! 👍";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF102D54), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'AI Pronunciation',
                    style: TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF102D54),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentScore?.overallScore ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPct,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFCBD5E1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2E93)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Details Card (Orange Header, White Bottom) ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        // Upper Orange Half
                        Expanded(
                          flex: 5,
                          child: Container(
                            width: double.infinity,
                            color: const Color(0xFFFFEDD5),
                            padding: const EdgeInsets.all(20),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'TARGET WORD',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFEA580C),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      vocab.word.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'FredokaOne',
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFF7E06),
                                      ),
                                    ).animate(key: ValueKey(vocab.id)).shake(duration: 600.ms),
                                    if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        vocab.phoneticText!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Speaker button top-right
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _playCurrentWord,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.volume_up_rounded,
                                        color: Color(0xFFFF7E06),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Lower White Half (horizontal waveform visualizer pills)
                        Expanded(
                          flex: 5,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_currentScore == null) ...[
                                  const Text(
                                    'TAP THE MIC AND TALK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Horizontal animated visualizer waveform pills (5 bars)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (idx) {
                                      return Container(
                                        width: 14,
                                        height: _isRecording ? (25 + idx * 10.0) : 15,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: _isRecording ? const Color(0xFFFF7E06) : const Color(0xFFCBD5E1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ).animate(
                                        target: _isRecording ? 1 : 0,
                                        onPlay: (controller) => controller.repeat(reverse: true),
                                      ).scaleY(
                                        begin: 0.5,
                                        end: 1.5,
                                        duration: Duration(milliseconds: 300 + idx * 100),
                                      );
                                    }),
                                  ),
                                ] else ...[
                                  // Score display
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentScore!.overallScore >= 60
                                              ? const Color(0xFFD1FAE5)
                                              : const Color(0xFFFFE4E6),
                                          border: Border.all(
                                            color: _currentScore!.overallScore >= 60
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFF43F5E),
                                            width: 6,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${_currentScore!.overallScore}',
                                          style: TextStyle(
                                            fontFamily: 'FredokaOne',
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: _currentScore!.overallScore >= 60
                                                ? const Color(0xFF065F46)
                                                : const Color(0xFF9F1239),
                                          ),
                                        ),
                                      ).animate().scale(duration: 400.ms),
                                      const SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildScoreMiniBar('Accuracy', _currentScore!.accuracyScore),
                                          _buildScoreMiniBar('Fluency', _currentScore!.fluencyScore),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Large Blue Circular Microphone Button ──
              if (!_isScoring && _currentScore == null)
                GestureDetector(
                  onTap: () {
                    if (_isRecording) {
                      _stopAndSubmit();
                    } else {
                      _startRecording();
                    }
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE0F2FE),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                          blurRadius: _isRecording ? 24 : 12,
                          spreadRadius: _isRecording ? 6 : 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ).animate(target: _isRecording ? 1 : 0).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                    )
              else if (_currentScore != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Speak again button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentScore = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFFF2E93), width: 2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh_rounded, color: Color(0xFFFF2E93), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'SPEAK AGAIN',
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF2E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Next word button
                    GestureDetector(
                      onTap: _nextWord,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2E93),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2E93).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'NEXT WORD',
                              style: TextStyle(
                                fontFamily: 'FredokaOne',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(strokeWidth: 4),
                ),
              const SizedBox(height: 20),

              // ── Mascot Section ──
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Text(
                      '🐼',
                      style: TextStyle(fontSize: 48),
                    ).animate().shake(hz: 2, duration: 2.seconds),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black12.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Text(
                          mascotText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102D54),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreMiniBar(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: $score%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 4),
          Container(
            width: 120,
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
                  color: score >= 60 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
