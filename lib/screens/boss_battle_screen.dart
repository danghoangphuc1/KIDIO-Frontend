import 'dart:async';
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

class BossBattleScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final String lessonId;

  const BossBattleScreen({
    super.key,
    required this.vocabularies,
    required this.lessonId,
  });

  @override
  State<BossBattleScreen> createState() => _BossBattleScreenState();
}

class BattleQuestion {
  final Vocabulary targetVocab;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? imageUrl;

  BattleQuestion({
    required this.targetVocab,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
  });
}

class _BossBattleScreenState extends State<BossBattleScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<BattleQuestion> _questions = [];
  int _currentIndex = 0;

  // Battle States
  double _bossMaxHp = 100.0;
  double _bossHp = 100.0;
  int _playerLives = 3;
  int _timerSeconds = 12;
  Timer? _gameTimer;

  bool _isAnswered = false;
  String? _selectedOption;
  bool _isPlayerAttacking = false;
  bool _isBossAttacking = false;
  bool _isScreenShaking = false;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
    _startRoundTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final random = Random();
    List<BattleQuestion> questions = [];

    for (var vocab in widget.vocabularies) {
      int questionType = random.nextInt(3); // 0, 1, or 2
      if (questionType == 2 && (vocab.imageUrl == null || vocab.imageUrl!.isEmpty)) {
        questionType = random.nextInt(2); // fallback to text only
      }

      String questionText;
      String correctAnswer;
      List<String> options = [];
      String? imageUrl;

      if (questionType == 0) {
        questionText = 'Nghĩa của từ "${vocab.word}" là gì?';
        correctAnswer = vocab.meaning;
        options.add(correctAnswer);

        final otherVocabs = widget.vocabularies.where((v) => v.id != vocab.id).toList();
        otherVocabs.shuffle(random);
        for (var ov in otherVocabs) {
          if (options.length >= 3) break;
          if (!options.contains(ov.meaning)) {
            options.add(ov.meaning);
          }
        }
      } else if (questionType == 1) {
        questionText = 'Từ nào có nghĩa là "${vocab.meaning}"?';
        correctAnswer = vocab.word;
        options.add(correctAnswer);

        final otherVocabs = widget.vocabularies.where((v) => v.id != vocab.id).toList();
        otherVocabs.shuffle(random);
        for (var ov in otherVocabs) {
          if (options.length >= 3) break;
          if (!options.contains(ov.word)) {
            options.add(ov.word);
          }
        }
      } else {
        questionText = 'Từ vựng nào tương ứng với hình ảnh này?';
        correctAnswer = vocab.word;
        imageUrl = vocab.imageUrl;
        options.add(correctAnswer);

        final otherVocabs = widget.vocabularies.where((v) => v.id != vocab.id).toList();
        otherVocabs.shuffle(random);
        for (var ov in otherVocabs) {
          if (options.length >= 3) break;
          if (!options.contains(ov.word)) {
            options.add(ov.word);
          }
        }
      }

      options.shuffle(random);
      questions.add(BattleQuestion(
        targetVocab: vocab,
        questionText: questionText,
        options: options,
        correctAnswer: correctAnswer,
        imageUrl: imageUrl,
      ));
    }

    questions.shuffle(random);
    setState(() {
      _questions = questions;
      _bossMaxHp = questions.length * 20.0;
      _bossHp = _bossMaxHp;
    });
  }

  void _startRoundTimer() {
    _gameTimer?.cancel();
    setState(() {
      _timerSeconds = 12;
      _isAnswered = false;
      _selectedOption = null;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _gameTimer?.cancel();
            _handleTimeOut();
          }
        });
      }
    });
  }

  void _handleTimeOut() {
    _handleAnswerSelected('');
  }

  void _handleAnswerSelected(String option) {
    if (_isAnswered) return;
    _gameTimer?.cancel();

    final currentQ = _questions[_currentIndex];
    final isCorrect = option == currentQ.correctAnswer;

    setState(() {
      _selectedOption = option;
      _isAnswered = true;
    });

    if (isCorrect) {
      // Player attacks boss!
      setState(() {
        _isPlayerAttacking = true;
        _bossHp = max(0.0, _bossHp - 20.0);
      });
      _playAudioEffect(true);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isPlayerAttacking = false;
          });
          _checkEndConditions();
        }
      });
    } else {
      // Boss attacks player!
      setState(() {
        _isBossAttacking = true;
        _playerLives = max(0, _playerLives - 1);
        _isScreenShaking = true;
      });
      _playAudioEffect(false);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isBossAttacking = false;
            _isScreenShaking = false;
          });
          _checkEndConditions();
        }
      });
    }
  }

  Future<void> _playAudioEffect(bool success) async {
    try {
      if (success) {
        await _audioPlayer.play(UrlSource('https://dict.youdao.com/dictvoice?audio=hit&type=1'));
      } else {
        await _audioPlayer.play(UrlSource('https://dict.youdao.com/dictvoice?audio=explosion&type=1'));
      }
    } catch (e) {
      debugPrint('Sound effect error: $e');
    }
  }

  void _checkEndConditions() {
    if (_bossHp <= 0) {
      _showBattleVictory();
    } else if (_playerLives <= 0) {
      _showBattleDefeat();
    } else {
      // Next Round
      setState(() {
        _currentIndex = (_currentIndex + 1) % _questions.length;
      });
      _startRoundTimer();
    }
  }

  void _restartGame() {
    _generateQuestions();
    setState(() {
      _playerLives = 3;
      _currentIndex = 0;
    });
    _startRoundTimer();
  }

  Future<void> _showBattleVictory() async {
    try {
      final childId = Provider.of<ChildProvider>(context, listen: false).selectedChild?.id;
      if (childId != null) {
        CacheService().saveActivityStatus(childId, widget.lessonId, 'boss', true);
      }
    } catch (e) {
      debugPrint('Error caching boss status: $e');
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D0A50), Color(0xFF7B3FA8)],
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
                        'VICTORY! ⚔️',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ).animate().shake(duration: 800.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'Con đã hạ gục Boss thành công!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Haching Mystery Egg anim representation
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.yellowAccent, width: 3),
                        ),
                        child: const Text(
                          '🥚',
                          style: TextStyle(fontSize: 90),
                        ),
                      ).animate().scale(duration: 600.ms).shake(hz: 4, duration: 1.seconds),

                      const SizedBox(height: 16),
                      const Text(
                        'Bonus Star Rewards!',
                        style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                          SizedBox(width: 6),
                          Text(
                            '+15 Stars!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
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
                      ).animate().scale(delay: 500.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _showBattleDefeat() async {
    final retry = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            color: const Color(0xFF1A0B2E),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'DEFEAT... 💔',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Boss quá mạnh! Hãy ôn tập lại từ vựng nhé.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Boss laugh emoji
                      Image.asset(
                        'assets/images/boss.png',
                        width: 150,
                        height: 150,
                      )
                          .animate()
                          .scale(duration: 500.ms)
                          .shake(),

                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('THOÁT', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('THỬ LẠI', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      if (retry == true) {
        _restartGame();
      } else {
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A0B2E),
        body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      );
    }

    final currentQ = _questions[_currentIndex];

    Widget mainContent = Scaffold(
      backgroundColor: const Color(0xFF130324),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0B2E), Color(0xFF0F041C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Top Header (timer and player hearts)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Timer Dial
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _timerSeconds <= 4 ? Colors.red.shade900 : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _timerSeconds <= 4 ? Colors.redAccent : Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$_timerSeconds s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Player Hearts
                    Row(
                      children: List.generate(3, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            index < _playerLives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: index < _playerLives ? Colors.redAccent : Colors.white.withOpacity(0.2),
                            size: 24,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Boss Character & Health Bar card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.purple.withOpacity(0.2), width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/boss.png',
                            width: 120,
                            height: 120,
                          )
                              .animate(target: _isBossAttacking ? 1 : 0)
                              .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.3, 1.3),
                                  duration: 300.ms)
                              .shake(duration: 500.ms)
                              .then()
                              .animate(target: _isPlayerAttacking ? 1 : 0)
                              .tint(color: Colors.redAccent, duration: 200.ms),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.vocabularies.isNotEmpty
                            ? '👾 ${widget.vocabularies.first.word.toUpperCase()} BOSS'
                            : '👾 WORD BOSS',
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Boss HP bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _bossHp / _bossMaxHp,
                          minHeight: 12,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Question Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentQ.imageUrl != null && currentQ.imageUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  currentQ.imageUrl!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            currentQ.questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF102D54),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Options vertical column
                          ...currentQ.options.map((option) {
                            final isSelected = _selectedOption == option;
                            final isCorrect = option == currentQ.correctAnswer;

                            Color buttonBgColor = Colors.grey.shade50;
                            Color borderColor = Colors.grey.shade200;
                            Color textColor = const Color(0xFF102D54);

                            if (_isAnswered) {
                              if (isSelected) {
                                buttonBgColor = isCorrect ? Colors.green.shade50 : Colors.red.shade50;
                                borderColor = isCorrect ? Colors.green : Colors.red;
                                textColor = isCorrect ? Colors.green.shade800 : Colors.red.shade800;
                              } else if (isCorrect) {
                                buttonBgColor = Colors.green.shade50;
                                borderColor = Colors.green;
                                textColor = Colors.green.shade800;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: () => _handleAnswerSelected(option),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: buttonBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: borderColor, width: 2.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    option,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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

    if (_isScreenShaking) {
      mainContent = mainContent.animate().shake(duration: 500.ms, hz: 10);
    }

    return mainContent;
  }
}
