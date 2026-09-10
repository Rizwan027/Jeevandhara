import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          final pendingTasks = [
            if (!profileSaved) 'profile setup',
            if (!verificationSent) 'verification email',
          ].join(' and ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account created. Complete $pendingTasks later from your profile.',
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authErrorMessage(error))));
      developer.log(
        '[AUTH] Firebase auth failed: ${error.code}',
        error: error,
        name: 'Auth',
      );
    } on TimeoutException {
      developer.log('[AUTH] auth operation timed out', name: 'Auth');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign-in timed out. Check your connection and try again.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Unable to save your profile.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign in. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email or password is incorrect.';
      case 'operation-not-allowed':
        return 'Email sign-in is disabled for this Firebase project. Enable Email/Password in Firebase Console.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network connection failed. Check your internet connection and try again.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _isLogin ? 'Welcome back' : 'Create your account',
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
                          ? 'Sign in to continue to Jeevandhara'
                          : 'Join Jeevandhara to get personalized farming advice',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 32),
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        final emailPattern = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );
                        if (!emailPattern.hasMatch(value.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
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
                          return 'Enter your password';
                        }
                        if (!_isLogin && value.length < 6) {
                          return 'Use at least 6 characters';
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
                            : Text(_isLogin ? 'Sign in' : 'Sign up'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLogin)
                      TextButton(
                        onPressed: _isLoading ? null : _sendPasswordReset,
                        child: const Text('Forgot password?'),
                      ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Don’t have an account? Sign up'
                            : 'Already have an account? Sign in',
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
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter your email first.')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authErrorMessage(error))));
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
