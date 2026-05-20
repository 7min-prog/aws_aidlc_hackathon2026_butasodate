import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/auth_state.dart';
import 'package:buta_app/shared/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    final success = await ref.read(authStateProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() { _isLoading = false; });

    if (!success && mounted) {
      setState(() { _errorMessage = 'メールアドレスまたはパスワードが正しくありません'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🐷', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text('ぶたそだて',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ButaColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              // JRPG風ダイアログ枠
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ButaColors.surface,
                  border: Border.all(color: ButaColors.border, width: 4),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Column(
                  children: [
                    TextField(
                      key: const Key('login-email-input'),
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'メールアドレス'),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontFamily: 'DotGothic16', color: ButaColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('login-password-input'),
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'パスワード'),
                      obscureText: true,
                      style: const TextStyle(fontFamily: 'DotGothic16', color: ButaColors.textPrimary),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: ButaColors.error, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('login-submit-button'),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: ButaColors.textPrimary)
                    : const Text('▶ ログイン'),
              ),
              const SizedBox(height: 16),
              TextButton(
                key: const Key('login-to-signup-button'),
                onPressed: () => context.go('/signup'),
                child: const Text('▶ アカウントを作成する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
