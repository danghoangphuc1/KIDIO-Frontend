import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/glassmorphic_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
      );

      if (success) {
        if (mounted) {
          CustomSnackBar.show(context, 'Đổi mật khẩu thành công!');
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(context, authProvider.errorMessage ?? 'Có lỗi xảy ra', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Thay đổi mật khẩu',
          style: TextStyle(fontFamily: 'FredokaOne', fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
        ),
        backgroundColor: Colors.white.withOpacity(0.4),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PlayfulBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.shield_outlined, size: 80, color: Color(0xFF3B82F6)),
                  const SizedBox(height: 24),
                  const Text(
                    'Để bảo mật, vui lòng nhập mật khẩu hiện tại trước khi đặt mật khẩu mới.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  
                  GlassTextField(
                    controller: _oldPasswordController,
                    hintText: 'Mật khẩu hiện tại',
                    obscureText: _obscureOld,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF1E3A8A)),
                      onPressed: () => setState(() => _obscureOld = !_obscureOld),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  GlassTextField(
                    controller: _newPasswordController,
                    hintText: 'Mật khẩu mới',
                    obscureText: _obscureNew,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF1E3A8A)),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu mới' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  GlassTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Xác nhận mật khẩu mới',
                    obscureText: _obscureConfirm,
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF1E3A8A)),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                      if (value != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  authProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GlassButton(
                          onPressed: _handleSubmit,
                          borderRadius: 20,
                          baseColor: const Color(0xFF3B82F6).withOpacity(0.8),
                          highlightColor: const Color(0xFF2563EB).withOpacity(0.9),
                          height: 54,
                          child: const Text(
                            'CẬP NHẬT MẬT KHẨU',
                            style: TextStyle(fontFamily: 'FredokaOne', fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
