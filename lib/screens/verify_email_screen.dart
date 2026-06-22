import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/parent_pin_dialogs.dart';
import '../widgets/glassmorphic_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String initialEmail;
  final String password;

  const VerifyEmailScreen({
    super.key,
    required this.initialEmail,
    required this.password,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late TextEditingController _emailController;
  bool _isErrorMode = false;
  bool _isChecking = false;
  bool _isVerified = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isChecking && !_isVerified) {
        _checkVerificationStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus({bool silent = false}) async {
    final authProvider = context.read<AuthProvider>();
    
    if (!silent) setState(() => _isChecking = true);
    
    final success = await authProvider.login(
      widget.initialEmail, 
      widget.password,
    );

    if (mounted) {
      if (!silent) setState(() => _isChecking = false);
      
      if (success) {
        _pollingTimer?.cancel();
        setState(() {
          _isVerified = true;
          _isErrorMode = false;
        });
      } else if (!silent) {
        final error = authProvider.errorMessage?.toLowerCase() ?? '';
        if (error.contains('verified') || error.contains('confirm')) {
          setState(() => _isErrorMode = true);
        } else {
          CustomSnackBar.show(context, authProvider.errorMessage ?? 'Xác thực thất bại', isError: true);
        }
      }
    }
  }

  Future<void> _handleNext() async {
    if (_isVerified) {
      final authProvider = context.read<AuthProvider>();
      final hasPin = await authProvider.hasParentPin();
      
      if (!hasPin && mounted) {
        await ParentPinDialogs.showCreatePinDialog(context, dismissible: false);
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    if (_isErrorMode) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      context.read<AuthProvider>().clearError();
      setState(() {
        _isErrorMode = false;
        _emailController.text = widget.initialEmail;
      });
      return;
    }

    await _checkVerificationStatus();
  }

  Future<void> _handleResend() async {
    final authProvider = context.read<AuthProvider>();
    final emailToSend = _emailController.text.trim();
    
    if (emailToSend.isEmpty) {
      CustomSnackBar.show(context, 'Vui lòng nhập email', isError: true);
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final success = await authProvider.resendVerification(emailToSend);
    
    if (mounted) {
      if (success) {
        CustomSnackBar.show(context, 'Đã gửi lại email xác thực!');
        setState(() => _isErrorMode = false);
      } else {
        CustomSnackBar.show(context, authProvider.errorMessage ?? 'Gửi lại thất bại', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _handleNext,
              child: const Row(
                children: [
                  Text(
                    'Tiếp tục',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: PlayfulBackground(
        backgroundColors: const [
          Color(0xFFC4F0FF), // Sky blue light
          Color(0xFF8ED8FF), // Sky blue mid
          Color(0xFF3EA5FF), // Sky blue dark
        ],
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isVerified) ...[
                  // Verified Success Screen with celebration styling
                  GlassCard(
                    borderRadius: BorderRadius.circular(32),
                    padding: const EdgeInsets.all(24),
                    fillColor: Colors.white.withOpacity(0.92),
                    borderColor: Colors.white.withOpacity(0.4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Green Success Badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF03A566), Color(0xFF028A55)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x3F03A566),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.check_rounded, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        
                        // Celebrating Mascot representation
                        const Text(
                          '🐼🎉',
                          style: TextStyle(fontSize: 72),
                        ),
                        const SizedBox(height: 12),
                        
                        const Text(
                          "Email Verified! 🎉",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102D54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tài khoản của bạn đã sẵn sàng và sẵn lòng đồng hành cùng bé học tập! 🚀",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF102D54).withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        GlassButton(
                          onPressed: _handleNext,
                          baseColor: const Color(0xFF03A566),
                          highlightColor: const Color(0xFF028A55),
                          borderRadius: 24,
                          child: const Text(
                            'TIẾP TỤC',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (!_isErrorMode) ...[
                  // Instructions screen
                  GlassCard(
                    borderRadius: BorderRadius.circular(32),
                    padding: const EdgeInsets.all(24),
                    fillColor: Colors.white.withOpacity(0.92),
                    borderColor: Colors.white.withOpacity(0.4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mail Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEDD5),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.mail_outline_rounded, size: 44, color: Colors.orangeAccent),
                        ),
                        const SizedBox(height: 16),
                        
                        // Waiting Mascot
                        const Text(
                          '🐼📬',
                          style: TextStyle(fontSize: 72),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          "Xác thực Email của bạn",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102D54),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Chúng tôi đã gửi link kích hoạt đến email của bạn. Vui lòng kiểm tra hộp thư và nhấn nút 'Xác thực Email' để kích hoạt tài khoản.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF102D54).withOpacity(0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        GlassButton(
                          onPressed: _handleNext,
                          baseColor: const Color(0xFFFF5C9F),
                          highlightColor: const Color(0xFFFF1F6E),
                          borderRadius: 24,
                          child: const Text(
                            'KIỂM TRA NGAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        TextButton(
                          onPressed: _handleResend,
                          child: const Text(
                            'Gửi lại Email xác nhận',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF5C9F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Error mode / Retry email input
                  GlassCard(
                    borderRadius: BorderRadius.circular(32),
                    padding: const EdgeInsets.all(24),
                    fillColor: Colors.white.withOpacity(0.92),
                    borderColor: Colors.white.withOpacity(0.4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Warning Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.warning_amber_rounded, size: 44, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 16),
                        
                        // Oops Mascot
                        const Text(
                          '🐼⚠️',
                          style: TextStyle(fontSize: 72),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          "Chưa xác thực email!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'FredokaOne',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102D54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bạn vẫn chưa kích hoạt tài khoản qua email. Hãy kiểm tra lại hoặc đổi sang email khác bên dưới:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF102D54).withOpacity(0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Transparent input box for email update
                        GlassTextField(
                          controller: _emailController,
                          hintText: "Nhập lại email của bạn",
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.blueAccent),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.cancel_rounded, color: Colors.grey),
                            onPressed: () => _emailController.clear(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        GlassButton(
                          onPressed: _handleResend,
                          baseColor: const Color(0xFF3EA5FF),
                          highlightColor: const Color(0xFF0EA5E9),
                          borderRadius: 24,
                          child: const Text(
                            'GỬI LẠI MÃ KÍCH HOẠT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        TextButton(
                          onPressed: () {
                            context.read<AuthProvider>().clearError();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Nhập sai email? Đăng ký lại',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF102D54).withOpacity(0.7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
