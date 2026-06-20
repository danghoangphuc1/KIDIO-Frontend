import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../repositories/tts_repository.dart';
import '../api/api_client.dart';

class ListeningGameScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final String lessonId;

  const ListeningGameScreen({
    super.key,
    required this.vocabularies,
    required this.lessonId,
  });

  @override
  State<ListeningGameScreen> createState() => _ListeningGameScreenState();
}

class ListeningRound {
  final Vocabulary correctVocab;
  final List<Vocabulary> options;

  ListeningRound({required this.correctVocab, required this.options});
}

class _ListeningGameScreenState extends State<ListeningGameScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<ListeningRound> _rounds = [];
  int _currentRoundIndex = 0;
  bool _isAudioPlaying = false;
  String? _selectedVocabId;
  bool _hasAnswered = false;
  int _starsEarned = 0;
  bool _firstTryCorrect = true;

  @override
  void initState() {
    super.initState();
    _generateRounds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rounds.isNotEmpty) {
        _playRoundSound();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getEmoji(String word) {
    final w = word.toLowerCase().trim();
    if (w.contains('cat')) return '🐱';
    if (w.contains('dog')) return '🐶';
    if (w.contains('bird')) return '🐦';
    if (w.contains('fish')) return '🐠';
    if (w.contains('lion')) return '🦁';
    if (w.contains('elephant')) return '🐘';
    if (w.contains('tiger')) return '🐯';
    if (w.contains('monkey')) return '🐵';
    if (w.contains('bear')) return '🐻';
    if (w.contains('panda')) return '🐼';
    if (w.contains('rabbit')) return '🐰';
    if (w.contains('apple')) return '🍎';
    if (w.contains('banana')) return '🍌';
    if (w.contains('orange')) return '🍊';
    if (w.contains('grape')) return '🍇';
    if (w.contains('milk')) return '🥛';
    if (w.contains('bread')) return '🍞';
    if (w.contains('family')) return '👪';
    if (w.contains('mother') || w.contains('mom')) return '👩';
    if (w.contains('father') || w.contains('dad')) return '👨';
    if (w.contains('baby')) return '👶';
    if (w.contains('school')) return '🎒';
    if (w.contains('book')) return '📚';
    if (w.contains('pencil')) return '✏️';
    if (w.contains('teacher')) return '👩‍🏫';
    if (w.contains('red')) return '🔴';
    if (w.contains('blue')) return '🔵';
    if (w.contains('green')) return '🟢';
    if (w.contains('yellow')) return '🟡';
    if (w.contains('one')) return '1️⃣';
    if (w.contains('two')) return '2️⃣';
    if (w.contains('three')) return '3️⃣';
    return '✨';
  }

  void _generateRounds() {
    final random = Random();
    List<ListeningRound> rounds = [];

    for (var vocab in widget.vocabularies) {
      List<Vocabulary> options = [vocab];
      List<Vocabulary> distractors =
          widget.vocabularies.where((v) => v.id != vocab.id).toList();
      distractors.shuffle(random);

      for (var d in distractors) {
        if (options.length >= 4) break;
        options.add(d);
      }

      // If less than 4 vocabulary items are available overall, fill options
      while (options.length < 4 && widget.vocabularies.isNotEmpty) {
        options.add(widget.vocabularies[random.nextInt(widget.vocabularies.length)]);
      }

      options.shuffle(random);

      rounds.add(ListeningRound(correctVocab: vocab, options: options));
    }

    rounds.shuffle(random);
    setState(() {
      _rounds = rounds;
    });
  }

  Future<void> _playRoundSound() async {
    if (_isAudioPlaying) return;
    setState(() => _isAudioPlaying = true);

    try {
      final vocab = _rounds[_currentRoundIndex].correctVocab;
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

  void _onAnswerSelected(Vocabulary selectedVocab) {
    if (_hasAnswered) return;

    final round = _rounds[_currentRoundIndex];
    final isCorrect = selectedVocab.id == round.correctVocab.id;

    setState(() {
      _selectedVocabId = selectedVocab.id;
      _hasAnswered = true;
    });

    if (isCorrect) {
      if (_firstTryCorrect) {
        _starsEarned++;
      }
      _playTtsFeedback(true);

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          if (_currentRoundIndex < _rounds.length - 1) {
            setState(() {
              _currentRoundIndex++;
              _hasAnswered = false;
              _selectedVocabId = null;
              _firstTryCorrect = true;
            });
            _playRoundSound();
          } else {
            _showGameComplete();
          }
        }
      });
    } else {
      _firstTryCorrect = false;
      _playTtsFeedback(false);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _hasAnswered = false;
            _selectedVocabId = null;
          });
        }
      });
    }
  }

  Future<void> _playTtsFeedback(bool isCorrect) async {
    try {
      if (isCorrect) {
        await _audioPlayer.play(UrlSource(
            'https://dict.youdao.com/dictvoice?audio=excellent&type=1'));
      } else {
        await _audioPlayer.play(UrlSource(
            'https://dict.youdao.com/dictvoice?audio=try+again&type=1'));
      }
    } catch (e) {
      debugPrint('Feedback voice error: $e');
    }
  }

  void _showGameComplete() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3EA5FF), Color(0xFF03A566)],
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
                        'AWESOME WORK! 🎧',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate().shake(duration: 800.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'Con nghe rất chuẩn!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Stars reward box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6))
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Stars Earned',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
                                const SizedBox(width: 8),
                                Text(
                                  '+$_starsEarned',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF102D54),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().scale(delay: 400.ms),
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
    if (_rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listening Game')),
        body: const Center(child: Text('Đang tải câu hỏi...')),
      );
    }

    final round = _rounds[_currentRoundIndex];
    final double progress = (_currentRoundIndex + 1) / _rounds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFE6FFFA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6FFFA), Color(0xFFB2F5EA)],
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
                      'Round ${_currentRoundIndex + 1}/${_rounds.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102D54),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_starsEarned',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF854D0E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Linear progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.teal.shade50,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
                const SizedBox(height: 24),

                // Waving Panda character prompting to listen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '🐼',
                        style: TextStyle(fontSize: 48),
                      ).animate().shake(hz: 3, duration: 1.5.seconds, curve: Curves.easeInOut),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Click to Listen! 🔊',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF102D54),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nghe và chọn hình vẽ tương ứng với từ con nghe được!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_up_rounded, color: Colors.white),
                        ),
                        onPressed: _playRoundSound,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2x2 grid of options
                Expanded(
                  child: GridView.builder(
                    itemCount: round.options.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final option = round.options[index];
                      final isSelected = _selectedVocabId == option.id;
                      final isCorrect = option.id == round.correctVocab.id;

                      Color cardBorderColor = Colors.grey.shade200;
                      Color cardColor = Colors.white;

                      if (_hasAnswered) {
                        if (isSelected) {
                          cardColor = isCorrect ? Colors.green.shade50 : Colors.red.shade50;
                          cardBorderColor = isCorrect ? Colors.green : Colors.red;
                        } else if (isCorrect) {
                          // Highlight correct option if incorrect selected
                          cardColor = Colors.green.shade50;
                          cardBorderColor = Colors.green;
                        }
                      }

                      Widget optionCard = GestureDetector(
                        onTap: () => _onAnswerSelected(option),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: cardBorderColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getEmoji(option.word),
                                style: const TextStyle(fontSize: 54),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                option.meaning,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102D54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      // Animate on wrong answer tap shake
                      if (_hasAnswered && isSelected && !isCorrect) {
                        optionCard = optionCard.animate().shake(duration: 500.ms, hz: 6);
                      }

                      return optionCard;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
