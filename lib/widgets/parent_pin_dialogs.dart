import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../screens/parent_dashboard_screen.dart';
import '../utils/snackbar_utils.dart';

class ParentPinDialogs {
  static Future<bool?> showCreatePinDialog(BuildContext context, {bool dismissible = true}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: dismissible,
      builder: (ctx) => _CreatePinDialog(dismissible: dismissible),
    );
  }

  static void showVerifyPinDialog(BuildContext context, {VoidCallback? onSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VerifyPinDialog(onSuccess: onSuccess),
    );
  }
}

// --- Bảng Numpad chung ---
class _Numpad extends StatelessWidget {
  final Function(String) onNumber;
  final VoidCallback onBackspace;

  const _Numpad({required this.onNumber, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int j = 1; j <= 3; j++)
                _buildNumBtn((i * 3 + j).toString()),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60, height: 60), // Khoảng trống
            _buildNumBtn('0'),
            _buildActionBtn(Icons.backspace_outlined, onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildNumBtn(String number) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => onNumber(number),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.blueGrey, size: 28),
        ),
      ),
    );
  }
}

// --- Dialog Tạo PIN ---
class _CreatePinDialog extends StatefulWidget {
  final bool dismissible;
  const _CreatePinDialog({this.dismissible = true});

  @override
  State<_CreatePinDialog> createState() => _CreatePinDialogState();
}

class _CreatePinDialogState extends State<_CreatePinDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  String _errorMsg = '';

  void _onNumPressed(String num) {
    setState(() {
      _errorMsg = '';
      if (!_isConfirmStep) {
        if (_pin.length < 4) _pin += num;
        if (_pin.length == 4) {
          _isConfirmStep = true;
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += num;
        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMsg = '';
      if (!_isConfirmStep && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_isConfirmStep && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (_isConfirmStep && _confirmPin.isEmpty) {
        // Quay lại bước tạo PIN
        _isConfirmStep = false;
        _pin = '';
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_pin == _confirmPin) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.setParentPin(_pin);
      if (success) {
        if (mounted) {
          CustomSnackBar.show(context, 
            'Tạo mã PIN Phụ huynh thành công!');
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMsg = authProvider.errorMessage ?? 'Cập nhật PIN thất bại';
          _isConfirmStep = false;
          _pin = '';
          _confirmPin = '';
        });
      }
    } else {
      setState(() {
        _errorMsg = 'Mã PIN không khớp. Vui lòng nhập lại.';
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 48, color: Colors.indigoAccent),
                const SizedBox(height: 16),
                Text(
                  _isConfirmStep ? 'Xác nhận mã PIN' : 'Tạo mã PIN Phụ huynh',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
                const SizedBox(height: 8),
                Text(
                  _isConfirmStep ? 'Nhập lại 4 số bạn vừa tạo' : 'Nhập 4 số để bảo vệ khu vực phụ huynh',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 24),
                _buildDots(_isConfirmStep ? _confirmPin : _pin),
                if (_errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                _Numpad(onNumber: _onNumPressed, onBackspace: _onBackspace),
              ],
            ),
          ),
          if (widget.dismissible)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDots(String currentInput) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < currentInput.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Colors.indigoAccent : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

// --- Dialog Xác thực PIN ---
class _VerifyPinDialog extends StatefulWidget {
  final VoidCallback? onSuccess;
  const _VerifyPinDialog({this.onSuccess});

  @override
  State<_VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<_VerifyPinDialog> with SingleTickerProviderStateMixin {
  String _pin = '';
  String _errorMsg = '';
  bool _isLocked = false;
  int _lockSeconds = 0;
  Timer? _timer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkLockStatus() async {
    final authProvider = context.read<AuthProvider>();
    final lockExpiration = await authProvider.getPinLockExpiration();
    
    if (lockExpiration != null) {
      final now = DateTime.now();
      if (now.isBefore(lockExpiration)) {
        final diff = lockExpiration.difference(now).inSeconds;
        setState(() {
          _isLocked = true;
          _lockSeconds = diff;
        });
        _startTimer();
      } else {
        await authProvider.resetWrongPinAttempts();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockSeconds > 0) {
        setState(() => _lockSeconds--);
      } else {
        timer.cancel();
        setState(() {
          _isLocked = false;
          _errorMsg = '';
        });
        context.read<AuthProvider>().resetWrongPinAttempts();
      }
    });
  }

  void _onNumPressed(String num) {
    if (_isLocked || _hasError) return;
    setState(() {
      _errorMsg = '';
      if (_pin.length < 4) _pin += num;
      if (_pin.length == 4) {
        _verify();
      }
    });
  }

  void _onBackspace() {
    if (_isLocked || _hasError) return;
    setState(() {
      _errorMsg = '';
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  bool _isVerifying = false;

  Future<void> _verify() async {
    if (_isLocked || _isVerifying) return;
    
    setState(() {
      _isVerifying = true;
    });

    final authProvider = context.read<AuthProvider>();
    final isCorrect = await authProvider.verifyParentPin(_pin);
    
    if (!mounted) return;

    if (isCorrect) {
      await authProvider.resetWrongPinAttempts();
      if (mounted) {
        Navigator.pop(context); // Close dialog
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
          );
        }
      }
    } else {
      await authProvider.incrementWrongPinAttempts();
      final attempts = await authProvider.getWrongPinAttempts();
      
      if (!mounted) return;

      // Shake animation trigger
      _shakeController.forward(from: 0.0);

      if (attempts >= 5) {
        final lockExpiration = DateTime.now().add(const Duration(seconds: 60));
        await authProvider.setPinLockExpiration(lockExpiration);
        setState(() {
          _isLocked = true;
          _lockSeconds = 60;
          _hasError = true;
          _errorMsg = '❌ Nhập sai quá nhiều lần!';
        });
        _startTimer();
        
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            setState(() {
              _pin = '';
              _hasError = false;
              _isVerifying = false;
            });
          }
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMsg = '❌ Wrong code! Try again.';
        });
        
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            setState(() {
              _pin = '';
              _hasError = false;
              _errorMsg = '';
              _isVerifying = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security_rounded, size: 52, color: Color(0xFF0EA5E9)),
            const SizedBox(height: 16),
            Text(
              _isLocked ? 'Locked Out' : 'Parent Gate',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: _isLocked ? Colors.red : const Color(0xFF1E3A8A)
              ),
            ),
            const SizedBox(height: 24),
            
            // Shaking Dots Row
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: _buildDots(_pin),
            ),
            
            const SizedBox(height: 12),
            if (_hasError)
              Text(
                _errorMsg,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              )
            else if (_isLocked)
              Text(
                'Please try again in $_lockSeconds seconds',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              )
            else
              const Text(
                '🔑 Demo code: 1 2 3 4',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Verify Code Button matching Figma specs
            _buildVerifyCodeButton(),

            const SizedBox(height: 24),
            Opacity(
              opacity: _isLocked ? 0.3 : 1.0,
              child: IgnorePointer(
                ignoring: _isLocked,
                child: _Numpad(onNumber: _onNumPressed, onBackspace: _onBackspace),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showForgotPinDialog(context);
              },
              child: const Text(
                'Forgot PIN?',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0EA5E9)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyCodeButton() {
    final isEnabled = _pin.length == 4 && !_isLocked && !_isVerifying;
    return SizedBox(
      width: double.infinity,
      child: isEnabled
          ? _AnimatedVerifyButton(
              text: 'Verify Code',
              onPressed: _verify,
              baseColor: const Color(0xFFFF2E93),
              shadowColor: const Color(0xFFB8154E),
            )
          : Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Verify Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildDots(String currentInput) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < currentInput.length;
        Color dotColor = Colors.grey.shade300;
        if (_hasError) {
          dotColor = Colors.redAccent;
        } else if (isFilled) {
          dotColor = const Color(0xFFFF2E93); // Pink dots
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            border: Border.all(
              color: _hasError
                  ? Colors.red
                  : isFilled
                      ? const Color(0xFFFF2E93)
                      : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

// Local 3D button widget to avoid circular imports
class _AnimatedVerifyButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color baseColor;
  final Color shadowColor;

  const _AnimatedVerifyButton({
    required this.text,
    required this.onPressed,
    required this.baseColor,
    required this.shadowColor,
  });

  @override
  State<_AnimatedVerifyButton> createState() => _AnimatedVerifyButtonState();
}

class _AnimatedVerifyButtonState extends State<_AnimatedVerifyButton> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isTapped ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 48,
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Dialog Quên PIN ---
void _showForgotPinDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _ForgotPinDialog(),
  );
}

class _ForgotPinDialog extends StatefulWidget {
  const _ForgotPinDialog();

  @override
  State<_ForgotPinDialog> createState() => _ForgotPinDialogState();
}

class _ForgotPinDialogState extends State<_ForgotPinDialog> {
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  String _errorMsg = '';

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _verifyPassword() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final authProvider = context.read<AuthProvider>();

    // Sử dụng API verify-password từ Backend
    final success = await authProvider.verifyPassword(password);
    
    if (success) {
      await authProvider.deleteParentPin(); // Xóa PIN cũ
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.show(context, 
          'Xác thực thành công. Mã PIN cũ đã bị xoá.');
        ParentPinDialogs.showCreatePinDialog(context); // Yêu cầu tạo lại PIN
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = authProvider.errorMessage ?? 'Mật khẩu không chính xác';
      });
    }
  }

  Future<void> _verifyBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Thiết bị không hỗ trợ Sinh trắc học/Mật khẩu thiết bị';
        });
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Xác thực để đặt lại Mã PIN Phụ huynh',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        if (!mounted) return;
        final authProvider = context.read<AuthProvider>();
        await authProvider.deleteParentPin(); // Xóa PIN cũ
        if (mounted) {
          Navigator.pop(context);
          CustomSnackBar.show(context, 
            'Xác thực thành công. Mã PIN cũ đã bị xoá.');
          ParentPinDialogs.showCreatePinDialog(context); // Yêu cầu tạo lại PIN
        }
      } else {
        setState(() {
          _isLoading = false;
          // User cancelled
        });
      }
    } on PlatformException catch (_) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Vui lòng cài đặt Khóa màn hình (Mật khẩu/Vân tay) trong Cài đặt của máy!';
      });
    } catch (e) {
      if (e.toString().contains('noCredentialsSet') || e.toString().contains('NotEnrolled')) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Vui lòng cài đặt Khóa màn hình (Mật khẩu/Vân tay) trong Cài đặt của máy!';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Lỗi kết nối bảo mật: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final email = authProvider.currentUser?.email ?? 'Tài khoản của bạn';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.help_outline, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Xác thực lại tài khoản',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 12),
              Text(
                'Vui lòng nhập mật khẩu của $email để đặt lại mã PIN phụ huynh.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton(
                  onPressed: _verifyPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('XÁC NHẬN MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Hoặc', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
                OutlinedButton.icon(
                  onPressed: _verifyBiometrics,
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text('Xác thực bằng thiết bị'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


