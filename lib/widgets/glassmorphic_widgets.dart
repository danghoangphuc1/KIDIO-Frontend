import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium glassmorphic card widget designed in the Soft Playful Glassmorphism style.
/// It uses BackdropFilter to blur the background, a semi-transparent white/pastel fill,
/// and a subtle border with light reflections.
class GlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry? borderRadius;
  final double blur;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 16.0,
    this.fillColor = const Color(0x3DFFAEC9), // Soft pink/white opacity
    this.borderColor = const Color(0x66FFFFFF), // Semi-transparent white
    this.borderWidth = 2.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.shadows,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(28.0);
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.blue.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.pink.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A bouncy, glossy 3D glassmorphic button with micro-animations.
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final double height;
  final double width;

  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 24.0,
    this.baseColor = const Color(0x59FFFFFF),
    this.highlightColor = const Color(0x80FFFFFF),
    this.height = 54.0,
    this.width = double.infinity,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withOpacity(_isHovered ? 0.25 : 0.15),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isHovered ? widget.highlightColor : widget.baseColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glossy glassmorphic text input field.
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0x991E3A8A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.white.withOpacity(0.35),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF0EA5E9),
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.red.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 2.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A background container with floating animated colorful blobs.
/// This creates the perfect vibrant & organic back-drop required for beautiful Glassmorphism.
class PlayfulBackground extends StatefulWidget {
  final Widget child;
  final List<Color> backgroundColors;

  const PlayfulBackground({
    super.key,
    required this.child,
    this.backgroundColors = const [
      Color(0xFFE0F2FE), // Light sky blue
      Color(0xFFFEE2E2), // Light pink/red
      Color(0xFFFEF9C3), // Light yellow
    ],
  });

  @override
  State<PlayfulBackground> createState() => _PlayfulBackgroundState();
}

class _PlayfulBackgroundState extends State<PlayfulBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Blob> _blobs = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Initialize random blobs
    _blobs.addAll([
      _Blob(
        color: const Color(0xFFFFC0D9).withOpacity(0.5),
        radius: 120,
        speedX: 0.04,
        speedY: 0.03,
        initialX: 0.2,
        initialY: 0.15,
      ),
      _Blob(
        color: const Color(0xFF96E9FF).withOpacity(0.5),
        radius: 160,
        speedX: -0.03,
        speedY: 0.05,
        initialX: 0.8,
        initialY: 0.4,
      ),
      _Blob(
        color: const Color(0xFFFFF5B8).withOpacity(0.6),
        radius: 140,
        speedX: 0.03,
        speedY: -0.04,
        initialX: 0.3,
        initialY: 0.7,
      ),
      _Blob(
        color: const Color(0xFFC7F9CC).withOpacity(0.5),
        radius: 150,
        speedX: -0.04,
        speedY: -0.03,
        initialX: 0.7,
        initialY: 0.85,
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Solid Gradient Base
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.backgroundColors,
            ),
          ),
        ),
        // Floating Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _BlobPainter(_blobs, _controller.value),
            );
          },
        ),
        // Foreground Content
        widget.child,
      ],
    );
  }
}

class _Blob {
  final Color color;
  final double radius;
  final double speedX;
  final double speedY;
  final double initialX;
  final double initialY;

  _Blob({
    required this.color,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.initialX,
    required this.initialY,
  });

  Offset getOffset(Size size, double animValue) {
    // Wave animation based on animValue (0.0 to 1.0)
    final double angle = animValue * 2 * math.pi;
    final double dx = math.sin(angle * 1.5) * 40 * speedX / 0.03;
    final double dy = math.cos(angle * 1.2) * 40 * speedY / 0.03;

    final double x = (initialX * size.width) + dx;
    final double y = (initialY * size.height) + dy;

    return Offset(x, y);
  }
}

class _BlobPainter extends CustomPainter {
  final List<_Blob> blobs;
  final double animValue;

  _BlobPainter(this.blobs, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final blob in blobs) {
      final paint = Paint()
        ..color = blob.color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35); // Softens blob edges

      final offset = blob.getOffset(size, animValue);
      canvas.drawCircle(offset, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
