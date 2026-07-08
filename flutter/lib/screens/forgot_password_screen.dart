import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/void_colors.dart';
import '../utils/i18n.dart';

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
      await FirebaseAuth.instance.sendPasswordResetEmail(
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.lock_reset,
            size: 80,
            color: VoidColors.darkAccent,
          ),
          const SizedBox(height: 24),
          Text(
            t('auth.resetPasswordMessage'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: VoidColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
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
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VoidColors.accentOnPrimary,
                    ),
                  )
                : Text(t('auth.sendResetLink')),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 64),
        Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: VoidColors.darkAccent,
        ),
        const SizedBox(height: 24),
        Text(
          t('auth.resetSent'),
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: VoidColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: VoidColors.darkTextSecondary,
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
