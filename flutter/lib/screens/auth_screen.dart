import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app;
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../widgets/loading_spinner.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<app.AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success;
    if (_isLogin) {
      success = await authProvider.signIn(email, password);
    } else {
      success = await authProvider.signUp(email, password);
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app.AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? t('auth.signIn') : t('auth.signUp')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Amber',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: t('auth.email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t('auth.emailRequired');
                  }
                  if (!value.contains('@')) {
                    return t('auth.emailInvalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: t('auth.password'),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t('auth.passwordRequired');
                  }
                  if (value.length < 6) {
                    return t('auth.passwordTooShort');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    child: Text(t('auth.forgotPassword')),
                  ),
                ),
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    authProvider.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: authProvider.isLoading ? null : _submit,
                child: authProvider.isLoading
                    ? const LoadingSpinner()
                    : Text(_isLogin ? t('auth.signIn') : t('auth.signUp')),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    authProvider.clearError();
                  });
                },
                child: Text(
                  _isLogin
                      ? t('auth.noAccount')
                      : t('auth.hasAccount'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
