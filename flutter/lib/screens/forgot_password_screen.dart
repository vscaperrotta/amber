import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_colors.dart';
import '../utils/i18n.dart';
import '../widgets/loading_spinner.dart';
import '../theme/cool_icons.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      await auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapFirebaseError(e.code);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ForgotPassword] sendPasswordResetEmail error: $e');
      setState(() {
        _errorMessage = t('auth.errorUnexpected');
        _isLoading = false;
      });
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return t('auth.errorUserNotFound');
      case 'invalid-email':
        return t('auth.errorInvalidEmail');
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'internal-error':
        return 'Firebase error. Check your internet connection.';
      default:
        return t('auth.errorGeneric', {'code': code});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('auth.resetPassword')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _emailSent
            ? _buildSuccessScreen()
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final c = context.colors;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(
            CoolIcons.lock,
            size: 80,
            color: c.accent,
          ),
          const SizedBox(height: 24),
          Text(
            t('auth.resetPasswordMessage'),
            textAlign: TextAlign.center,
            style: AppFonts.body(
              fontSize: 14,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: t('auth.email'),
              prefixIcon: const Icon(CoolIcons.email),
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
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            child: _isLoading ? const LoadingSpinner() : Text(t('auth.sendResetLink')),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 64),
        Icon(
          CoolIcons.emailRead,
          size: 80,
          color: c.accent,
        ),
        const SizedBox(height: 24),
        Text(
          t('auth.resetSent'),
          textAlign: TextAlign.center,
          style: AppFonts.body(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text,
          textAlign: TextAlign.center,
          style: AppFonts.body(
            fontSize: 14,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 48),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('auth.backToSignIn')),
        ),
      ],
    );
  }
}
