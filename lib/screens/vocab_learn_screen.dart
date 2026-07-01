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

class _VocabLearnScreenState extends State<VocabLearnScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentIndex = 0;
  bool _isAudioPlaying = false;

  // ── 3D Flip state ──
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  // ── Swipe state ──
  double _dragX = 0.0;
  bool _isDragging = false;
  static const double _swipeThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.vocabularies.isNotEmpty) _playCurrentWord();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _resetFlip() {
    _flipController.value = 0;
    _isFlipped = false;
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
      if (mounted) setState(() => _isAudioPlaying = false);
    }
  }

  void _nextWord() {
    _resetFlip();
    if (_currentIndex < widget.vocabularies.length - 1) {
      setState(() => _currentIndex++);
      _playCurrentWord();
    } else {
      _showCompletionScreen();
    }
  }

  void _prevWord() {
    _resetFlip();
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _playCurrentWord();
    }
  }

  // Swipe gesture handlers
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _isDragging = true;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragX > _swipeThreshold) {
      // Swipe right → Known (go next)
      _nextWord();
    } else if (_dragX < -_swipeThreshold) {
      // Swipe left → Unknown (go next too, but show red)
      _nextWord();
    }
    setState(() {
      _dragX = 0;
      _isDragging = false;
    });
  }

  void _showCompletionScreen() {
    try {
      final childId = Provider.of<ChildProvider>(context, listen: false).selectedChild?.id;
      if (childId != null) {
        CacheService().saveActivityStatus(childId, widget.lessonId, 'vocab', true);
      }
    } catch (e) {
      debugPrint('Error caching vocab status: $e');
    }

    Navigator.pushReplacement(
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
                          fontFamily: 'FredokaOne',
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: ['🎈', '🎉', '🏆', '🎉', '🎈']
                            .asMap()
                            .entries
                            .map((entry) => Text(entry.value, style: const TextStyle(fontSize: 48))
                                .animate(delay: (entry.key * 150).ms)
                                .scale(duration: 500.ms)
                                .shake())
                            .toList(),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: const Text(
                            'QUAY LẠI HOẠT ĐỘNG',
                            style: TextStyle(fontFamily: 'FredokaOne', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF102D54)),
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
    final double progressPct = (_currentIndex + 1) / widget.vocabularies.length;
    const themeColor = Color(0xFFFF7E06);

    final dioBaseUrl = context.read<ApiClient>().dio.options.baseUrl;
    final baseUrl = dioBaseUrl.endsWith('/api/')
        ? dioBaseUrl.substring(0, dioBaseUrl.length - 5)
        : dioBaseUrl;

    // Swipe-driven tint overlay
    final bool isSwipingRight = _dragX > 20;
    final bool isSwipingLeft = _dragX < -20;
    final double swipeOpacity = (_dragX.abs() / _swipeThreshold).clamp(0.0, 0.7);
    final Color swipeTint = isSwipingRight
        ? Colors.green.withOpacity(swipeOpacity)
        : isSwipingLeft
            ? Colors.red.withOpacity(swipeOpacity)
            : Colors.transparent;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF102D54), size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    '${_currentIndex + 1} / ${widget.vocabularies.length}',
                    style: const TextStyle(
                      fontFamily: 'FredokaOne',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF102D54),
                    ),
                  ),
                  // Flip hint button
                  IconButton(
                    icon: const Icon(Icons.flip, color: Color(0xFFFF7E06), size: 26),
                    tooltip: 'Tap card to flip',
                    onPressed: _toggleFlip,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progressPct),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      builder: (ctx, value, _) => Stack(
                        children: [
                          Container(
                            height: 8,
                            width: constraints.maxWidth,
                            color: const Color(0xFFCBD5E1),
                          ),
                          Container(
                            height: 8,
                            width: constraints.maxWidth * value,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2E93),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ── 3D Flip Card with Swipe ──
              Expanded(
                child: GestureDetector(
                  onTap: _toggleFlip,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onHorizontalDragCancel: () => setState(() {
                    _dragX = 0;
                    _isDragging = false;
                  }),
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * pi;
                      final isShowingBack = angle > pi / 2;

                      // Apply swipe offset + rotation
                      final tiltAngle = _isDragging ? (_dragX / 600.0) : 0.0;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle)
                          ..rotateZ(tiltAngle)
                          ..translate(_dragX * 0.6, 0.0, 0.0),
                        alignment: Alignment.center,
                        child: isShowingBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: _buildBackCard(vocab, swipeTint),
                              )
                            : _buildFrontCard(vocab, baseUrl, swipeTint, themeColor),
                      );
                    },
                  ),
                ),
              ),

              // Swipe hint labels
              if (_isDragging)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedOpacity(
                        opacity: isSwipingLeft ? swipeOpacity * 1.4 : 0,
                        duration: 100.ms,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('😅 Chưa thuộc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isSwipingRight ? swipeOpacity * 1.4 : 0,
                        duration: 100.ms,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('✅ Đã thuộc!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 16),

              // Mascot
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('🐼', style: TextStyle(fontSize: 44))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleY(begin: 1.0, end: 1.06, duration: 2.seconds, curve: Curves.easeInOut),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Text(
                          _isFlipped
                              ? "Great! Swipe right if you know it 👉"
                              : "Tap the card to reveal the meaning! 🔄",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF102D54)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Opacity(
                    opacity: _currentIndex > 0 ? 1.0 : 0.4,
                    child: GestureDetector(
                      onTap: _currentIndex > 0 ? _prevWord : null,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF102D54), size: 26),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _nextWord,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2E93),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF2E93).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [

                          Text(
                            _currentIndex == widget.vocabularies.length - 1 ? 'COMPLETED' : 'NEXT WORD',
                            style: const TextStyle(fontFamily: 'FredokaOne', fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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
    );
  }
  Widget _buildFrontCard(Vocabulary vocab, String baseUrl, Color tintOverlay, Color themeColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: tintOverlay == Colors.transparent ? Colors.transparent : tintOverlay,
          width: 3,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Column(
              children: [
                // Upper half – orange background + image
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFFEDD5),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        vocab.imageUrl != null && vocab.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.network(
                                  vocab.imageUrl!.startsWith('http')
                                      ? vocab.imageUrl!
                                      : '$baseUrl${vocab.imageUrl!.startsWith('/') ? '' : '/'}${vocab.imageUrl}',
                                  headers: const {'User-Agent': 'KidioApp/1.0'},
                                  height: 140,
                                  width: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Text(_getEmoji(vocab.word), style: const TextStyle(fontSize: 90)),
                                ),
                              )
                            : Text(_getEmoji(vocab.word), style: const TextStyle(fontSize: 90)),
                        // Speaker button
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: _playCurrentWord,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF7E06), size: 22),
                            ),
                          ),
                        ),
                        // "Tap to flip" hint
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFFFF7E06)),
                                SizedBox(width: 4),
                                Text('Tap to flip', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF7E06))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lower half – white word info
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            vocab.word.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'FredokaOne',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF7E06),
                              letterSpacing: 1,
                            ),
                          ).animate(key: ValueKey(vocab.id)).shake(duration: 600.ms),
                        ),
                        if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            vocab.phoneticText!,
                            style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _playCurrentWord,
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEAD2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFC085), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isAudioPlaying ? 'PLAYING...' : 'Listen!',
                                  style: const TextStyle(fontFamily: 'FredokaOne', fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.volume_up_rounded, color: Color(0xFFD97706), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Swipe tint overlay
            if (tintOverlay != Colors.transparent)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: tintOverlay,
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Back card (meaning + example) ──
  Widget _buildBackCard(Vocabulary vocab, Color tintOverlay) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7E06), Color(0xFFFF5C9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📖', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 20),
                Text(
                  vocab.meaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'FredokaOne',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty)
                  Text(
                    vocab.phoneticText!,
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.85)),
                  ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '← Swipe left if unknown\nSwipe right if known →',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          if (tintOverlay != Colors.transparent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: tintOverlay, borderRadius: BorderRadius.circular(26)),
              ),
            ),
        ],
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
