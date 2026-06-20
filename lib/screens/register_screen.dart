import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'verify_email_screen.dart';
import '../widgets/glassmorphic_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final success = await authProvider.register(
        email: email,
        password: password,
        confirmPassword: _confirmPasswordController.text,
        displayName: _nameController.text.trim(),
      );
      
      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(
              initialEmail: email,
              password: password,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            context.read<AuthProvider>().clearError();
            Navigator.pop(context);
          },
        ),
      ),
      body: PlayfulBackground(
        backgroundColors: const [Color(0xFF3EA5FF), Color(0xFF8ED8FF), Color(0xFFC4F0FF)],
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: GlassCard(
                  borderRadius: BorderRadius.circular(32),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  fillColor: Colors.white.withOpacity(0.25),
                  borderColor: Colors.white.withOpacity(0.45),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          'KIDIO',
                          style: TextStyle(
                            fontFamily: 'Fredoka One',
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(color: Color(0xFF0566C5), offset: Offset(0, 4), blurRadius: 0),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Create Your Account ✨',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102D54),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (authProvider.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
                        decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập tên';
                          if (value.length < 2) return 'Tên phải có ít nhất 2 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
                        decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) return 'Định dạng email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
                        decoration: _buildInputDecoration('Password', Icons.lock_outline, suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9AB0C8)),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        )),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
                          if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Cần ít nhất 1 chữ hoa';
                          if (!RegExp(r'[a-z]').hasMatch(value)) return 'Cần ít nhất 1 chữ thường';
                          if (!RegExp(r'[0-9]').hasMatch(value)) return 'Cần ít nhất 1 chữ số';
                          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\\^$*\[\]/_~`]').hasMatch(value)) return 'Cần ít nhất 1 ký tự đặc biệt';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102D54)),
                        decoration: _buildInputDecoration('Confirm Password', Icons.lock_reset, suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9AB0C8)),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        )),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập lại mật khẩu';
                          if (value != _passwordController.text) return 'Mật khẩu không khớp';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5C9F)))
                          : SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => _handleRegister(authProvider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5C9F),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  shadowColor: const Color(0xFFFF5C9F).withOpacity(0.3),
                                ),
                                child: const Text(
                                  '🚀 Let\'s Register!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Fredoka One',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
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
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AB0C8), fontWeight: FontWeight.w500, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2.5),
      ),
    );
  }
}
