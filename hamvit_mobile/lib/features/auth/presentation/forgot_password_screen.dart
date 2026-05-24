import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_components.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String _feedback = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(authStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text('Recuperar senha'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 90,
            width: double.infinity,
            child: Image.asset(
              'assets/branding/hamvit_hoje_exata.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
          ),
          const SizedBox(height: 8),
          HamvitButton(
            label: 'Enviar link',
            onPressed: () async {
              final email = _emailCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) return;
              await notifier.sendRecoveryEmail(email);
              if (!mounted) return;
              setState(() {
                _feedback = 'Se o e-mail existir, você recebera um link de recuperacao.';
              });
            },
          ),
          if (_feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_feedback),
          ],
        ],
      ),
    );
  }
}
