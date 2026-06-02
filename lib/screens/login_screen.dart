import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Sử dụng Client ID khớp với dự án Google bạn đang quản lý (374569...)
    serverClientId: '374569495508-vuonlvgep7ike3cps4f8n1bsv88v2kgm.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'KIDIO',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Learn English with Fun!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),
                
                if (authProvider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              // Reset sign in to allow account re-selection
                              await _googleSignIn.signOut();
                              final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
                              if (googleUser == null) return;

                              final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                              final idToken = googleAuth.idToken;

                              if (idToken != null) {
                                await authProvider.loginWithGoogle(idToken);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Error: No ID Token received.')),
                                  );
                                }
                              }
                            } catch (error) {
                              if (mounted) {
                                // Clear error to avoid confusion
                                debugPrint("Detailed Error: $error");
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Google Sign-In Error'),
                                    content: Text('Code 10 usually means SHA-1 mismatch.\n\n$error'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.login, size: 24),
                          label: const Text('SIGN IN WITH GOOGLE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
  }
}
