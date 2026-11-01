import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final auth = FirebaseAuth.instance;

      if (_isLogin) {
        developer.log('[AUTH] sign-in started', name: 'Auth');
        await auth
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 20));
        developer.log('[AUTH] Firebase sign-in succeeded', name: 'Auth');
        if (mounted) setState(() => _isLoading = false);
      } else {
        developer.log('[AUTH] sign-up started', name: 'Auth');
        final credential = await auth
            .createUserWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 20));
        developer.log('[AUTH] Firebase sign-up succeeded', name: 'Auth');
        var profileSaved = true;
        try {
          developer.log('[AUTH] profile provisioning started', name: 'Auth');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({
                'name': _nameController.text.trim(),
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
              })
              .timeout(const Duration(seconds: 15));
          developer.log('[AUTH] profile provisioning succeeded', name: 'Auth');
        } on TimeoutException catch (error) {
          developer.log(
            '[AUTH] profile provisioning failed: $error',
            error: error,
            name: 'Auth',
          );
          profileSaved = false;
        } on FirebaseException {
          developer.log('[AUTH] profile provisioning failed', name: 'Auth');
          profileSaved = false;
        }

        var verificationSent = true;
        try {
          await credential.user!.sendEmailVerification().timeout(
            const Duration(seconds: 15),
          );
          developer.log('[AUTH] verification setup succeeded', name: 'Auth');
        } on TimeoutException catch (error) {
          developer.log(
            '[AUTH] verification setup failed: $error',
            error: error,
            name: 'Auth',
          );
          verificationSent = false;
        } on FirebaseAuthException {
          developer.log('[AUTH] verification setup failed', name: 'Auth');
          verificationSent = false;
        }

        if (!mounted) return;
        if (!profileSaved || !verificationSent) {
          final localization = AppLocalizations.of(context)!;
          final pendingTasks = [
            if (!profileSaved) localization.getText('auth_profile_setup'),
            if (!verificationSent)
              localization.getText('auth_verification_email'),
          ].join(' ${localization.getText('auth_and')} ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localization
                    .getText('auth_account_created_tasks')
                    .replaceAll('{tasks}', pendingTasks),
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authErrorMessage(error, AppLocalizations.of(context)!),
          ),
        ),
      );
      developer.log(
        '[AUTH] Firebase auth failed: ${error.code}',
        error: error,
        name: 'Auth',
      );
    } on TimeoutException {
      developer.log('[AUTH] auth operation timed out', name: 'Auth');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.getText('auth_timeout')),
        ),
      );
    } on FirebaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.getText('auth_save_profile_failed'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.getText('auth_sign_in_failed'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(
    FirebaseAuthException error,
    AppLocalizations localization,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return localization.getText('auth_email_exists');
      case 'invalid-email':
        return localization.getText('auth_invalid_email_error');
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return localization.getText('auth_credentials_invalid');
      case 'operation-not-allowed':
        return localization.getText('auth_sign_in_disabled');
      case 'user-disabled':
        return localization.getText('auth_account_disabled');
      case 'too-many-requests':
        return localization.getText('auth_too_many_attempts');
      case 'network-request-failed':
        return localization.getText('auth_network_failed');
      case 'weak-password':
        return localization.getText('auth_weak_password');
      default:
        return localization.getText('auth_failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final green = const Color(0xFF4CAF50);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.eco, size: 72, color: green),
                    const SizedBox(height: 16),
                    Text(
                      localization.getText(
                        _isLogin ? 'auth_welcome_back' : 'auth_create_account',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? localization.getText('auth_sign_in_subtitle')
                          : localization.getText('auth_sign_up_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 32),
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: localization.getText('auth_name_label'),
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? localization.getText('auth_enter_name')
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: localization.getText('auth_email_label'),
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.getText('auth_enter_email');
                        }
                        final emailPattern = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );
                        if (!emailPattern.hasMatch(value.trim())) {
                          return localization.getText('auth_invalid_email');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: localization.getText('auth_password_label'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? localization.getText('auth_show_password')
                              : localization.getText('auth_hide_password'),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localization.getText('auth_enter_password');
                        }
                        if (!_isLogin && value.length < 6) {
                          return localization.getText(
                            'auth_password_min_length',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                localization.getText(
                                  _isLogin ? 'auth_sign_in' : 'auth_sign_up',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLogin)
                      TextButton(
                        onPressed: _isLoading ? null : _sendPasswordReset,
                        child: Text(
                          localization.getText('auth_forgot_password'),
                        ),
                      ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? localization.getText('auth_no_account')
                            : localization.getText('auth_have_account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final localization = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.getText('auth_password_reset_enter_email'),
          ),
        ),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.getText('auth_password_reset_sent')),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(error, localization))),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
