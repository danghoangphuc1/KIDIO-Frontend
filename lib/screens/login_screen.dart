import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/glassmorphic_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '374569495508-vuonlvgep7ike3cps4f8n1bsv88v2kgm.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken != null) {
        final success = await authProvider.loginWithGoogle(idToken);
        if (success && mounted) {
          // Navigation is handled by AuthWrapper
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(context, 'Lỗi: Không nhận được ID Token.', isError: true);
        }
      }
    } catch (error) {
      if (mounted) {
        debugPrint("Detailed Error: $error");
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lỗi đăng nhập Google'),
            content: Text('Không thể đăng nhập bằng Google.\n\n$error'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đồng ý'))
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleEmailLogin(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: PlayfulBackground(
        backgroundColors: const [Color(0xFF3EA5FF), Color(0xFF8ED8FF), Color(0xFFC4F0FF)],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Logo & Rainbow Section (GSAP-like animations: bounce down)
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Rainbow Curve Background
                        Positioned(
                          top: 10,
                          child: CustomPaint(
                            size: const Size(360, 96),
                            painter: _RainbowPainter(),
                          )
                              .animate()
                              .scaleX(begin: 0.5, duration: 800.ms, curve: Curves.easeOut),
                        ),
                        // Cloud Left
                        Positioned(
                          left: -14,
                          top: 35,
                          child: const FluffyCloud(width: 84, height: 50, opacity: 0.92)
                              .animate()
                              .fade(duration: 800.ms)
                              .slideX(begin: -0.3, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
                        ),
                        // Cloud Right
                        Positioned(
                          right: 15,
                          top: 15,
                          child: const FluffyCloud(width: 84, height: 50, opacity: 0.92)
                              .animate()
                              .fade(duration: 800.ms)
                              .slideX(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
                        ),
                        // Sparkles
                        Positioned(
                          left: 20,
                          top: 8,
                          child: const SparkleWidget()
                              .animate()
                              .scale(duration: 1.seconds, curve: Curves.easeOutBack),
                        ),
                        Positioned(
                          right: 25,
                          top: 0,
                          child: const SparkleWidget(color: Color(0xFFFF5C9F))
                              .animate()
                              .scale(duration: 1.2.seconds, curve: Curves.easeOutBack),
                        ),

                        // Logo Text
                        Column(
                          children: [
                            const Text(
                              'KIDIO',
                              style: TextStyle(
                                fontFamily: 'Fredoka One',
                                fontSize: 70,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 6,
                                height: 1.1,
                                shadows: [
                                  Shadow(color: Color(0xFF0566C5), offset: Offset(0, 5), blurRadius: 0),
                                  Shadow(color: Color(0xFF0566C5), offset: Offset(-1, -1), blurRadius: 0),
                                  Shadow(color: Color(0xFF0566C5), offset: Offset(1, -1), blurRadius: 0),
                                  Shadow(color: Color(0xFF0566C5), offset: Offset(-1, 1), blurRadius: 0),
                                  Shadow(color: Color(0xFF0566C5), offset: Offset(1, 1), blurRadius: 0),
                                ],
                              ),
                            )
                                .animate()
                                .slideY(begin: -0.5, end: 0, duration: 800.ms, curve: Curves.easeOutBack)
                                .fade(duration: 800.ms),
                            const SizedBox(height: 6),
                            const Text(
                              '🌎 Learn English Through Adventures',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF102D54),
                                fontWeight: FontWeight.w800,
                              ),
                            )
                                .animate()
                                .fade(duration: 600.ms, delay: 400.ms),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Panda Mascot with Speech Bubble (GSAP-like floating)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const KikiPanda(size: 112)
                            .animate()
                            .slideX(begin: -0.4, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                            .fade(duration: 600.ms)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .slideY(begin: 0.0, end: -0.05, duration: 2.seconds, curve: Curves.easeInOut),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpeechBubble()
                              .animate()
                              .scale(begin: Offset.zero, duration: 500.ms, delay: 300.ms, curve: Curves.easeOutBack),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Main Auth Glass Card Container
                    GlassCard(
                      borderRadius: BorderRadius.circular(32),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      fillColor: Colors.white.withOpacity(0.25),
                      borderColor: Colors.white.withOpacity(0.45),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (authProvider.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    authProvider.errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (authProvider.errorMessage!.toLowerCase().contains('verified') || 
                                      authProvider.errorMessage!.toLowerCase().contains('xác thực'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: GestureDetector(
                                        onTap: () async {
                                          final email = _emailController.text.trim();
                                          if (email.isEmpty) {
                                            CustomSnackBar.show(context, 'Vui lòng nhập Email trước khi gửi lại!', isError: true);
                                            return;
                                          }
                                          final success = await authProvider.resendVerification(email);
                                          if (success && mounted) {
                                            CustomSnackBar.show(context, 'Đã gửi lại Email xác thực thành công. Vui lòng kiểm tra hộp thư!', isError: false);
                                          }
                                        },
                                        child: const Text(
                                          'Chưa nhận được? Gửi lại Email xác thực',
                                          style: TextStyle(
                                            color: Color(0xFF0877F2),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            decoration: TextDecoration.underline,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // Email Label & Field
                          const Text(
                            '📧 Email Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF102D54),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
                            decoration: _buildInputDecor(hint: 'your@email.com'),
                            validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập email' : null,
                          ),
                          const SizedBox(height: 16),

                          // Password Label & Field
                          const Text(
                            '🔒 Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF102D54),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
                            decoration: _buildInputDecor(
                              hint: 'Enter your password',
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF9AB0C8),
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                          ),
                          const SizedBox(height: 6),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF0877F2),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Play Button
                          authProvider.isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF1F6E)))
                              : Animated3DButton(
                                  text: '🚀 Login & Play!',
                                  onPressed: () => _handleEmailLogin(authProvider),
                                  baseColor: const Color(0xFFFF5C9F),
                                  shadowColor: const Color(0xFFB8154E),
                                ),

                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Container(height: 1.5, color: const Color(0xFFE0EAF4).withOpacity(0.5))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: Color(0xFF9AB0C8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(child: Container(height: 1.5, color: const Color(0xFFE0EAF4).withOpacity(0.5))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google sign in button
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => _handleGoogleSignIn(authProvider),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                backgroundColor: Colors.white.withOpacity(0.35),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 28);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF102D54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.2, end: 0, duration: 700.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                        .fade(duration: 700.ms, delay: 200.ms),
                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "New here? ",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF102D54), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Create Account ✨',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0877F2),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Decorative bouncing emojis (Row of flowers & stars)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: ["🌸", "⭐", "🌺", "✨", "🌷", "🌸", "⭐", "🌼", "🌺", "✨", "🌸"]
                          .asMap()
                          .entries
                          .map((entry) {
                        final i = entry.key;
                        final emoji = entry.value;
                        return Text(
                          emoji,
                          style: TextStyle(fontSize: i % 3 == 1 ? 14 : 20),
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .slideY(
                              begin: 0.0,
                              end: -0.3,
                              duration: (1200 + i * 120).ms,
                              curve: Curves.easeInOut,
                            );
                      }).toList(),
                    ).animate().slideY(begin: 0.5, end: 0, duration: 600.ms, delay: 500.ms),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble() {
    return GlassCard(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
        bottomLeft: Radius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: Colors.white.withOpacity(0.35),
      borderColor: Colors.white.withOpacity(0.45),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi friend! 👋',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              color: Color(0xFF102D54),
              fontSize: 13,
            ),
          ),
          SizedBox(height: 2),
          Text(
            "Let's learn English together!",
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: Color(0xFF0877F2),
              fontSize: 13,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Your adventure is waiting 🚀',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: Color(0xFF9AB0C8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecor({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AB0C8), fontWeight: FontWeight.w500, fontSize: 14),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2.5),
      ),
    );
  }
}

// Custom Rainbow curve painter to match Figma
class _RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 1.3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final colors = [
      const Color(0xFF9B59B6), // Purple (inside)
      const Color(0xFF0877F2), // Blue
      const Color(0xFF03A566), // Green
      const Color(0xFFFDE047), // Yellow
      const Color(0xFFFF8C00), // Orange
      const Color(0xFFFF0000), // Red (outside)
    ];

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      final radius = size.width / 3.4 + (i * 6.8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi, // Start angle (Pi)
        pi,  // Sweep angle (Pi)
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Fluffy Cloud Widget from Figma SVG mockup
class FluffyCloud extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const FluffyCloud({
    super.key,
    required this.width,
    required this.height,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CloudPainter(opacity: opacity),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double opacity;
  _CloudPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final wScale = size.width / 84;
    final hScale = size.height / 50;

    canvas.drawCircle(Offset(22 * wScale, 34 * hScale), 17 * wScale, paint);
    canvas.drawCircle(Offset(42 * wScale, 24 * hScale), 23 * wScale, paint);
    canvas.drawCircle(Offset(62 * wScale, 32 * hScale), 16 * wScale, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10 * wScale, 34 * hScale, 64 * wScale, 16 * hScale),
        Radius.circular(8 * wScale),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Sparkle Widget
class SparkleWidget extends StatelessWidget {
  final Color color;
  const SparkleWidget({super.key, this.color = const Color(0xFFFDE047)});

  @override
  Widget build(BuildContext context) {
    return Text(
      '✨',
      style: TextStyle(fontSize: 18, color: color),
    );
  }
}

// Full-body Kiki Panda mascot custom vector painted
class KikiPanda extends StatelessWidget {
  final double size;

  const KikiPanda({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PandaPainter(),
      ),
    );
  }
}

class _PandaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double scale = w / 120.0;

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale
      ..color = const Color(0xFF222222);

    // 1. Shadow
    paint.color = Colors.black.withOpacity(0.09);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(60 * scale, 116 * scale),
        width: 52 * scale,
        height: 10 * scale,
      ),
      paint,
    );

    // 2. Arms (transform rotate)
    paint.color = Colors.white;
    // Left arm rotated -20 deg around 28, 78
    canvas.save();
    canvas.translate(28 * scale, 78 * scale);
    canvas.rotate(-20 * pi / 180);
    final leftArmRect = Rect.fromCenter(center: const Offset(0, 0), width: 20 * scale, height: 26 * scale);
    canvas.drawOval(leftArmRect, paint);
    canvas.drawOval(leftArmRect, strokePaint);
    canvas.restore();

    // Right arm rotated 20 deg around 92, 78
    canvas.save();
    canvas.translate(92 * scale, 78 * scale);
    canvas.rotate(20 * pi / 180);
    final rightArmRect = Rect.fromCenter(center: const Offset(0, 0), width: 20 * scale, height: 26 * scale);
    canvas.drawOval(rightArmRect, paint);
    canvas.drawOval(rightArmRect, strokePaint);
    canvas.restore();

    // 3. Legs
    // Left leg
    final leftLegRect = Rect.fromCenter(center: Offset(46 * scale, 106 * scale), width: 20 * scale, height: 14 * scale);
    canvas.drawOval(leftLegRect, paint);
    canvas.drawOval(leftLegRect, strokePaint);
    // Right leg
    final rightLegRect = Rect.fromCenter(center: Offset(74 * scale, 106 * scale), width: 20 * scale, height: 14 * scale);
    canvas.drawOval(rightLegRect, paint);
    canvas.drawOval(rightLegRect, strokePaint);

    // 4. Body
    paint.color = Colors.white;
    final bodyRect = Rect.fromCenter(center: Offset(60 * scale, 82 * scale), width: 62 * scale, height: 58 * scale);
    canvas.drawOval(bodyRect, paint);
    canvas.drawOval(bodyRect, strokePaint);

    // Inner grey tummy
    paint.color = const Color(0xFFF5F5F5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(60 * scale, 85 * scale), width: 38 * scale, height: 34 * scale),
      paint,
    );

    // 5. Ears
    paint.color = const Color(0xFF2D2D2D);
    canvas.drawCircle(Offset(36 * scale, 20 * scale), 12 * scale, paint);
    canvas.drawCircle(Offset(84 * scale, 20 * scale), 12 * scale, paint);

    // Inner ear
    paint.color = const Color(0xFF4A4A4A);
    canvas.drawCircle(Offset(36 * scale, 20 * scale), 7 * scale, paint);
    canvas.drawCircle(Offset(84 * scale, 20 * scale), 7 * scale, paint);

    // 6. Head
    paint.color = Colors.white;
    canvas.drawCircle(Offset(60 * scale, 46 * scale), 29 * scale, paint);
    canvas.drawCircle(Offset(60 * scale, 46 * scale), 29 * scale, strokePaint);

    // 7. Eye patches
    paint.color = const Color(0xFF2D2D2D);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(49 * scale, 43 * scale), width: 20 * scale, height: 20 * scale),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(71 * scale, 43 * scale), width: 20 * scale, height: 20 * scale),
      paint,
    );

    // 8. Outer eye whites
    paint.color = Colors.white;
    canvas.drawCircle(Offset(49 * scale, 43 * scale), 5.5 * scale, paint);
    canvas.drawCircle(Offset(71 * scale, 43 * scale), 5.5 * scale, paint);

    // Pupils
    paint.color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(50 * scale, 42 * scale), 3 * scale, paint);
    canvas.drawCircle(Offset(72 * scale, 42 * scale), 3 * scale, paint);

    // Pupil Shines
    paint.color = Colors.white;
    canvas.drawCircle(Offset(51.5 * scale, 40.5 * scale), 1.2 * scale, paint);
    canvas.drawCircle(Offset(73.5 * scale, 40.5 * scale), 1.2 * scale, paint);

    // 9. Cheek blushes
    paint.color = const Color(0xFFFFB3C6).withOpacity(0.65);
    canvas.drawCircle(Offset(43 * scale, 54 * scale), 5.5 * scale, paint);
    canvas.drawCircle(Offset(77 * scale, 54 * scale), 5.5 * scale, paint);

    // 10. Nose
    paint.color = const Color(0xFFFFB3C6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(60 * scale, 51 * scale), width: 9 * scale, height: 6 * scale),
      paint,
    );

    // 11. Mouth (curved path)
    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF222222);

    final Path mouthPath = Path();
    mouthPath.moveTo(53 * scale, 57 * scale);
    mouthPath.quadraticBezierTo(60 * scale, 65 * scale, 67 * scale, 57 * scale);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Premium 3D button widget matching Figma specifications
class Animated3DButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color baseColor;
  final Color shadowColor;
  final double height;

  const Animated3DButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.baseColor,
    required this.shadowColor,
    this.height = 56,
  });

  @override
  State<Animated3DButton> createState() => _Animated3DButtonState();
}

class _Animated3DButtonState extends State<Animated3DButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isTapped ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.shadowColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: _isTapped ? 2 : 6),
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isTapped
                  ? null
                  : [
                      BoxShadow(
                        color: widget.baseColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Fredoka One',
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
