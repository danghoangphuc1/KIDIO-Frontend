import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
  bool _isVerified = false; // Trạng thái xác thực thành công
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    // Bắt đầu tự động kiểm tra mỗi 3 giây
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
    
    // Thử đăng nhập để kiểm tra xem email đã được xác thực chưa
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage ?? 'Xác thực thất bại')),
          );
        }
      }
    }
  }

  Future<void> _handleNext() async {
    if (_isVerified) {
      // Nếu đã xác thực xong, nhấn Tiếp tục để vào màn hình chọn bé
      Navigator.of(context).popUntil((route) => route.isFirst);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email'), backgroundColor: Colors.orange),
      );
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final success = await authProvider.resendVerification(emailToSend);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lại email xác thực!'), backgroundColor: Colors.green),
        );
        setState(() => _isErrorMode = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Gửi lại thất bại'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          _isChecking 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : TextButton(
                onPressed: _handleNext,
                child: const Row(
                  children: [
                    Text('Tiếp tục', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    Icon(Icons.chevron_right, color: Colors.blueAccent),
                  ],
                ),
              ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isVerified) ...[
                // Trang xác thực thành công (Giống ảnh 3 bạn gửi)
                const Icon(Icons.check_circle, size: 120, color: Colors.green),
                const SizedBox(height: 30),
                const Text(
                  "Email của bạn đã được xác thực!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Bằng cách tiếp tục sử dụng ứng dụng, bạn đồng ý với các điều khoản dịch vụ và chính sách bảo mật của chúng tôi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Nhấn 'Tiếp tục' để bắt đầu hành trình học tập cùng KidIO.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF1A237E), fontWeight: FontWeight.w500),
                ),
              ] else if (!_isErrorMode) ...[
                // Trang hướng dẫn
                const Icon(Icons.mail_outline, size: 100, color: Colors.orangeAccent),
                const SizedBox(height: 40),
                const Text(
                  "Vui lòng kiểm tra email và nhấn nút 'Xác thực Email'.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Sau đó, nhấn nút 'Tiếp tục' ở trên khi bạn đã hoàn tất.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                ),
                const SizedBox(height: 60),
                TextButton(
                  onPressed: _handleResend,
                  child: const Text(
                    'Gửi lại Email',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ),
              ] else ...[
                // Trang báo lỗi
                const Text(
                  "Ối! Bạn vẫn chưa xác thực. Vui lòng kiểm tra lại email.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Nhập lại email nếu sai",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        onPressed: () => _emailController.clear(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.pets, size: 60, color: Colors.tealAccent),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: _handleResend,
                  child: const Text(
                    'Gửi lại mã xác thực tới email này',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    context.read<AuthProvider>().clearError();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Nhập sai email? Đăng ký lại',
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
