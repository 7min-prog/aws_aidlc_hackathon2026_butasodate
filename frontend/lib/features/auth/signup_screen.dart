import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/auth_state.dart';
import 'package:buta_app/shared/theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() { _errorMessage = 'パスワードが一致しません'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final success = await ref.read(authStateProvider.notifier).signup(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() { _isLoading = false; });

    if (success && mounted) {
      context.go('/confirm', extra: _emailController.text.trim());
    } else if (mounted) {
      setState(() { _errorMessage = 'サインアップに失敗しました'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント作成')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: const Key('signup-email-input'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup-password-input'),
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'パスワード（8文字以上、大小英数字+記号）'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('signup-confirm-password-input'),
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'パスワード（確認）'),
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: ButaColors.error)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('signup-submit-button'),
              onPressed: _isLoading ? null : _handleSignup,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('アカウント作成'),
            ),
            const SizedBox(height: 16),
            TextButton(
              key: const Key('signup-to-login-button'),
              onPressed: () => context.go('/login'),
              child: const Text('ログインに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
