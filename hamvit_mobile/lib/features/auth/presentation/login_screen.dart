import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_components.dart';
import '../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStateModel>(authStateProvider, (previous, next) {
      final becameAuthenticated =
          previous?.status != AuthStatus.authenticated &&
              next.status == AuthStatus.authenticated;
      if (!becameAuthenticated) return;
      if (!context.mounted) return;
      context.go('/welcome');
    });

    final auth = ref.watch(authStateProvider);
    final notifier = ref.read(authStateProvider.notifier);
    final loading = auth.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Image.asset(
              'assets/branding/hamvit_hoje_exata.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Informe seu e-mail.';
                      if (!value.contains('@')) return 'E-mail invalido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe sua senha.' : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HamvitButton(
              label: loading ? 'Entrando...' : 'Entrar',
              onPressed: loading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      await notifier.login(
                        email: _emailCtrl.text.trim(),
                        password: _passwordCtrl.text,
                      );
                    },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/forgot-password'),
            child: const Text('Esqueci minha senha'),
          ),
          TextButton(
            onPressed: () => context.push('/register'),
            child: const Text('Criar conta'),
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              auth.errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}
