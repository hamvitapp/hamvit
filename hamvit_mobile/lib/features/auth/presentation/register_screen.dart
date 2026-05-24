import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_components.dart';
import '../domain/auth_state.dart';
import '../providers/auth_provider.dart';
import 'terms_of_use_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _acceptedTerms = false;

  static final _passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStateModel>(authStateProvider, (previous, next) {
      final becameAuthenticated = previous?.status != AuthStatus.authenticated && next.status == AuthStatus.authenticated;
      if (!becameAuthenticated) return;
      if (!context.mounted) return;
      context.go('/welcome');
    });

    final auth = ref.watch(authStateProvider);
    final notifier = ref.read(authStateProvider.notifier);
    final loading = auth.status == AuthStatus.loading;

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
        title: const Text('Criar conta'),
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatorio.' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'E-mail obrigatorio.';
                      if (!value.contains('@')) return 'E-mail invalido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (!_passwordRegex.hasMatch(value)) {
                        return 'Senha: 8+ chars, 1 maiuscula, 1 numero e 1 especial.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirmar senha'),
                    validator: (v) {
                      if ((v ?? '').trim() != _passwordCtrl.text.trim()) {
                        return 'As senhas não conferem.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    const Text('Aceito os'),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                        );
                      },
                      child: const Text(
                        'termos de uso',
                        style: TextStyle(
                          color: Color(0xFF2D9CFF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text('.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HamvitButton(
            label: loading ? 'Montando perfil...' : 'Montar Perfil',
            onPressed: loading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (!_acceptedTerms) return;
                    await notifier.register(
                      name: _nameCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      password: _passwordCtrl.text.trim(),
                    );
                  },
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ja tenho conta'),
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(auth.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }
}
