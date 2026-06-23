import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/kidio_models.dart';
import '../repositories/tts_repository.dart';
import '../api/api_client.dart';
import '../widgets/glassmorphic_widgets.dart';

class VocabLearnScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final String lessonId;

  const VocabLearnScreen({
    super.key,
    required this.vocabularies,
    required this.lessonId,
  });

  @override
  State<VocabLearnScreen> createState() => _VocabLearnScreenState();
}

class _VocabLearnScreenState extends State<VocabLearnScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentIndex = 0;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.vocabularies.isNotEmpty) {
        _playCurrentWord();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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

  void _nextWord() {
    if (_currentIndex < widget.vocabularies.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _playCurrentWord();
    } else {
      _showCompletionScreen();
    }
  }

  void _prevWord() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _playCurrentWord();
    }
  }

  void _showCompletionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5C9F), Color(0xFFFF8C00)],
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
                        '🌟 FANTASTIC! 🌟',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ).animate().shake(duration: 800.ms),
                      const SizedBox(height: 16),
                      const Text(
                        'Con đã hoàn thành học từ vựng bài học này!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                      const SizedBox(height: 32),
                      // Floating balloons/stars emoji representation
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: ['🎈', '🎉', '🏆', '🎉', '🎈']
                            .asMap()
                            .entries
                            .map(
                              (entry) => Text(
                                entry.value,
                                style: const TextStyle(fontSize: 42),
                              ).animate(delay: (entry.key * 150).ms).scale(duration: 500.ms).shake(),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Pop completion screen
                          Navigator.pop(context, true); // Return true to mark completed
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
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
                      ).animate().scale(delay: 800.ms),
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
        appBar: AppBar(title: const Text('Vocabulary')),
        body: const Center(child: Text('Không có từ vựng nào trong bài này.')),
      );
    }

    final vocab = widget.vocabularies[_currentIndex];
    final double progress = (_currentIndex + 1) / widget.vocabularies.length;

    // Harmonious background color list based on order index
    final List<Color> bgGradientColors = [
      const Color(0xFF3ea5ff),
      const Color(0xFF03a566),
      const Color(0xFFff5c9f),
      const Color(0xFFff8c00),
      const Color(0xFF7b3fa8),
    ];
    final themeColor = bgGradientColors[_currentIndex % bgGradientColors.length];

    final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
    final baseUrl = dioBaseUrl.endsWith('/api/')
        ? dioBaseUrl.substring(0, dioBaseUrl.length - 5)
        : dioBaseUrl;

    return Scaffold(
      body: PlayfulBackground(
        backgroundColors: [
          themeColor.withOpacity(0.7),
          themeColor,
          themeColor.withOpacity(0.95),
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () {
                        // Return true if they reached the end
                        final isCompleted = _currentIndex >= widget.vocabularies.length - 1;
                        Navigator.pop(context, isCompleted);
                      },
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.vocabularies.length}',
                      style: const TextStyle(
                        fontFamily: 'Fredoka One',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer
                  ],
                ),
                const SizedBox(height: 12),

                // Linear progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                // Vocabulary Card
                Expanded(
                  child: GlassCard(
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(32),
                    padding: const EdgeInsets.all(24),
                    fillColor: Colors.white.withOpacity(0.35),
                    borderColor: Colors.white.withOpacity(0.55),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          // Display Image or Emoji
                          Builder(
                            builder: (context) {
                              final wordLower = vocab.word.toLowerCase();
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
                              final finalUrl = (vocab.imageUrl != null && vocab.imageUrl!.isNotEmpty) ? vocab.imageUrl : fallbackUrl;
                              
                              if (finalUrl != null && finalUrl.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    finalUrl.startsWith('http')
                                        ? finalUrl
                                        : '$baseUrl${finalUrl.startsWith('/') ? '' : '/'}$finalUrl',
                                    headers: const {'User-Agent': 'KidioApp/1.0'},
                                    height: 160,
                                    width: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Text(_getEmoji(vocab.word), style: const TextStyle(fontSize: 100)),
                                  ),
                                );
                              }
                              
                              return Text(_getEmoji(vocab.word), style: const TextStyle(fontSize: 100));
                            }
                          ),
                          const SizedBox(height: 16),

                          // Word
                          Text(
                            vocab.word,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Fredoka One',
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: themeColor,
                              letterSpacing: 0.5,
                            ),
                          ).animate(key: ValueKey(vocab.id)).shake(duration: 600.ms),

                          // Phonetic Text
                          if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              vocab.phoneticText!,
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Play Audio Button
                          GestureDetector(
                            onTap: _playCurrentWord,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isAudioPlaying
                                    ? Icons.volume_down_rounded
                                    : Icons.volume_up_rounded,
                                size: 36,
                                color: themeColor,
                              ),
                            ).animate(target: _isAudioPlaying ? 1 : 0).scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.15, 1.15),
                                  duration: 300.ms,
                                  curve: Curves.easeInOut,
                                ),
                          ),
                          const SizedBox(height: 24),

                          // Meaning Translation
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Ý nghĩa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vocab.meaning,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF102D54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Example Sentence
                          if (vocab.exampleSentence != null &&
                              vocab.exampleSentence!.isNotEmpty) ...[
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Example:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                vocab.exampleSentence!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    Opacity(
                      opacity: _currentIndex > 0 ? 1.0 : 0.4,
                      child: GestureDetector(
                        onTap: _currentIndex > 0 ? _prevWord : null,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    // Next / Finish Button
                    GestureDetector(
                      onTap: _nextWord,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentIndex == widget.vocabularies.length - 1
                                  ? 'HOÀN THÀNH'
                                  : 'TỪ TIẾP THEO',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: themeColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: themeColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}
