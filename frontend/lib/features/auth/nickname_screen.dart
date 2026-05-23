import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/api_client.dart';
import 'package:buta_app/shared/auth_state.dart';
import 'package:buta_app/shared/theme.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 10) {
      setState(() { _errorMessage = 'ニックネームは2〜10文字で入力してください'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final api = ref.read(apiClientProvider);
      await api.authPost('/users/profile', data: {'nickname': nickname});

      // ニックネーム設定成功 → アバター作成
      await ref.read(authStateProvider.notifier).createInitialAvatar();

      if (mounted) context.go('/');
    } catch (e) {
      setState(() { _errorMessage = 'このニックネームは既に使用されています'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ニックネーム設定')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('あなたのニックネームを決めてください',
              style: TextStyle(fontSize: 14, color: ButaColors.textOnDark),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('nickname-input'),
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'ニックネーム（2〜10文字）',
                hintText: 'ぶたまる',
              ),
              maxLength: 10,
              style: const TextStyle(fontFamily: 'DotGothic16', color: ButaColors.textPrimary),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: ButaColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('nickname-submit-button'),
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: ButaColors.textPrimary)
                  : const Text('▶ 決定'),
            ),
          ],
        ),
      ),
    );
  }
}
