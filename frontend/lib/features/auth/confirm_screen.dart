import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/auth_state.dart';
import 'package:buta_app/shared/theme.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  final String email;
  const ConfirmScreen({super.key, required this.email});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    final success = await ref.read(authStateProvider.notifier).confirmSignup(
      widget.email,
      _codeController.text.trim(),
    );

    setState(() { _isLoading = false; });

    if (success && mounted) {
      context.go('/login');
    } else if (mounted) {
      setState(() { _errorMessage = '確認コードが正しくありません'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メール確認')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.email} に確認コードを送信しました',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: ButaColors.textOnDark),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('confirm-code-input'),
              controller: _codeController,
              decoration: const InputDecoration(labelText: '6桁の確認コード'),
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(fontFamily: kFontDotGothic16, color: ButaColors.textPrimary),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: ButaColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('confirm-submit-button'),
              onPressed: _isLoading ? null : _handleConfirm,
              child: _isLoading
                  ? const CircularProgressIndicator(color: ButaColors.textPrimary)
                  : const Text('▶ 確認'),
            ),
          ],
        ),
      ),
    );
  }
}
