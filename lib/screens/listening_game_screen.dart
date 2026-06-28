import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../repositories/tts_repository.dart';
import '../api/api_client.dart';
import '../providers/child_provider.dart';
import '../local/cache_service.dart';

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
    if (w.contains('cow')) return '🐄';
    if (w.contains('sheep')) return '🐑';
    if (w.contains('pig')) return '🐷';
    if (w.contains('apple')) return '🍎';
    if (w.contains('banana')) return '🍌';
    if (w.contains('orange')) return '🍊';
    if (w.contains('grape')) return '🍇';
    if (w.contains('mango')) return '🥭';
    if (w.contains('carrot')) return '🥕';
    if (w.contains('potato')) return '🥔';
    if (w.contains('tomato')) return '🍅';
    if (w.contains('cucumber')) return '🥒';
    if (w.contains('milk')) return '🥛';
    if (w.contains('bread')) return '🍞';
    if (w.contains('family')) return '👪';
    if (w.contains('mother') || w.contains('mom')) return '👩';
    if (w.contains('father') || w.contains('dad')) return '👨';
    if (w.contains('brother')) return '👦';
    if (w.contains('sister')) return '👧';
    if (w.contains('baby')) return '👶';
    if (w.contains('school')) return '🎒';
    if (w.contains('book')) return '📚';
    if (w.contains('pencil')) return '✏️';
    if (w.contains('teacher')) return '👩‍🏫';
    if (w.contains('desk')) return '🪑';
    if (w.contains('car')) return '🚗';
    if (w.contains('bus')) return '🚌';
    if (w.contains('bike') || w.contains('bicycle')) return '🚲';
    if (w.contains('red')) return '🔴';
    if (w.contains('blue')) return '🔵';
    if (w.contains('green')) return '🟢';
    if (w.contains('yellow')) return '🟡';
    if (w.contains('one')) return '1️⃣';
    if (w.contains('two')) return '2️⃣';
    if (w.contains('three')) return '3️⃣';
    if (w.contains('circle')) return '⭕';
    if (w.contains('square')) return '⬛';
    if (w.contains('triangle')) return '🔺';
    if (w.contains('sunny')) return '☀️';
    if (w.contains('rainy')) return '🌧️';
    if (w.contains('windy')) return '💨';
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

  void _onAnswerSelected(Vocabulary option) {
    if (_hasAnswered) return;

    setState(() {
      _selectedVocabId = option.id;
      _hasAnswered = true;
    });

    final round = _rounds[_currentRoundIndex];
    if (option.id == round.correctVocab.id) {
      if (_firstTryCorrect) {
        setState(() => _starsEarned += 10);
      } else {
        setState(() => _starsEarned += 5);
      }
      Future.delayed(const Duration(milliseconds: 1600), _nextRound);
    } else {
      setState(() => _firstTryCorrect = false);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _selectedVocabId = null;
            _hasAnswered = false;
            round.options.shuffle();
          });
        }
      });
    }
  }

  void _nextRound() {
    if (_currentRoundIndex < _rounds.length - 1) {
      setState(() {
        _currentRoundIndex++;
        _selectedVocabId = null;
        _hasAnswered = false;
        _firstTryCorrect = true;
      });
      _playRoundSound();
    } else {
      _showCompletionScreen();
    }
  }

  void _showCompletionScreen() {
    try {
      final childId = Provider.of<ChildProvider>(context, listen: false).selectedChild?.id;
      if (childId != null) {
        CacheService().saveActivityStatus(childId, widget.lessonId, 'listening', true);
      }
    } catch (e) {
      debugPrint('Error caching listening status: $e');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E0854), Color(0xFF5B118F)],
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
                        '🌟 EXCELLENT! 🌟',
                        style: TextStyle(
                          fontFamily: 'FredokaOne',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
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
                                    fontFamily: 'FredokaOne',
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
    if (_rounds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listening Game')),
        body: const Center(child: Text('Đang tải câu hỏi...')),
      );
    }

    final round = _rounds[_currentRoundIndex];
    final double progressVal = (_currentRoundIndex + 1) / _rounds.length;

    final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
    final baseUrl = dioBaseUrl.endsWith('/api/')
        ? dioBaseUrl.substring(0, dioBaseUrl.length - 5)
        : dioBaseUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Top header row
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
                          '$_starsEarned',
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

              // Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFCBD5E1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2E93)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Centered Speaker Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Listen carefully!',
                      style: TextStyle(
                        fontFamily: 'FredokaOne',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102D54),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ripple Effect Speaker Button
                    GestureDetector(
                      onTap: _playRoundSound,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withOpacity(0.4),
                              blurRadius: _isAudioPlaying ? 24 : 12,
                              spreadRadius: _isAudioPlaying ? 6 : 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0284C7), // Blue-cyan color
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── 2x2 grid of options (emoji only) ──
              Expanded(
                child: GridView.builder(
                  itemCount: round.options.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final option = round.options[index];
                    final isSelected = _selectedVocabId == option.id;
                    final isCorrect = option.id == round.correctVocab.id;

                    Color cardBorderColor = const Color(0xFFE2E8F0);
                    Color cardColor = Colors.white;

                    if (_hasAnswered) {
                      if (isSelected) {
                        cardColor = isCorrect ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
                        cardBorderColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                      } else if (isCorrect) {
                        cardColor = const Color(0xFFD1FAE5);
                        cardBorderColor = const Color(0xFF10B981);
                      }
                    }

                    Widget optionCard = GestureDetector(
                      onTap: () => _onAnswerSelected(option),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cardBorderColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Builder(
                          builder: (context) {
                            final wordLower = option.word.toLowerCase();
                            final mockImages = {
                              'dog': 'https://cdn-icons-png.flaticon.com/512/616/616408.png',
                              'cat': 'https://cdn-icons-png.flaticon.com/512/616/616430.png',
                              'cow': 'https://cdn-icons-png.flaticon.com/512/2395/2395796.png',
                              'one': 'https://cdn-icons-png.flaticon.com/512/3840/3840745.png',
                              'two': 'https://cdn-icons-png.flaticon.com/512/3840/3840750.png',
                              'three': 'https://cdn-icons-png.flaticon.com/512/3840/3840754.png',
                              'circle': 'https://cdn-icons-png.flaticon.com/512/481/481069.png',
                              'square': 'https://cdn-icons-png.flaticon.com/512/481/481048.png',
                              'triangle': 'https://cdn-icons-png.flaticon.com/512/481/481050.png',
                              'sunny': 'https://cdn-icons-png.flaticon.com/512/869/869869.png',
                              'rainy': 'https://cdn-icons-png.flaticon.com/512/1146/1146860.png',
                              'windy': 'https://cdn-icons-png.flaticon.com/512/1146/1146869.png',
                              'teacher': 'https://cdn-icons-png.flaticon.com/512/194/194935.png',
                              'book': 'https://cdn-icons-png.flaticon.com/512/2232/2232688.png',
                              'desk': 'https://cdn-icons-png.flaticon.com/512/2663/2663158.png',
                            };
                            final fallbackUrl = mockImages[wordLower];
                            final finalUrl = (option.imageUrl != null && option.imageUrl!.isNotEmpty) ? option.imageUrl : fallbackUrl;
                            
                            if (finalUrl != null && finalUrl.isNotEmpty) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  finalUrl.startsWith('http')
                                      ? finalUrl
                                      : '$baseUrl${finalUrl.startsWith('/') ? '' : '/'}$finalUrl',
                                  headers: const {'User-Agent': 'KidioApp/1.0'},
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Text(_getEmoji(option.word), style: const TextStyle(fontSize: 64)),
                                ),
                              );
                            }
                            
                            return Text(_getEmoji(option.word), style: const TextStyle(fontSize: 64));
                          }
                        ),
                      ),
                    );

                    if (_hasAnswered && isSelected && !isCorrect) {
                      optionCard = optionCard.animate().shake(duration: 500.ms, hz: 6);
                    }

                    return optionCard;
                  },
                ),
              ),

              // ── Mascot Section ──
              Container(
                margin: const EdgeInsets.only(top: 10),
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
                        child: const Text(
                          "Listen to the sound and choose the matching friend!",
                          style: TextStyle(
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
}
