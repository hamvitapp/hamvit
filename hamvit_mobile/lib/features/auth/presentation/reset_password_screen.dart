import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_components.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _error = '';

  static final _passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(authStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Redefinir senha')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HamvitHeader(title: 'Nova senha', subtitle: 'Use uma senha forte para proteger sua conta.'),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
          ),
          const SizedBox(height: 12),
          HamvitButton(
            label: 'Salvar nova senha',
            onPressed: () async {
              final password = _passwordCtrl.text.trim();
              final confirm = _confirmCtrl.text.trim();
              if (!_passwordRegex.hasMatch(password)) {
                setState(() => _error = 'Senha inválida para a política atual.');
                return;
              }
              if (password != confirm) {
                setState(() => _error = 'As senhas não conferem.');
                return;
              }
              await notifier.updatePassword(password);
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }
}
