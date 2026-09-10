import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFF8FFFE);

  Future<void> _editName(
    BuildContext context,
    User user,
    String currentName,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: currentName),
    );

    if (name == null || name == currentName) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
      }, SetOptions(merge: true));
      await user.updateDisplayName(name);
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not update your name.')),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _sendVerification(BuildContext context, User user) async {
    try {
      await user.sendEmailVerification();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent.')));
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not send verification email.'),
        ),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context, User user) async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password to confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, passwordController.text),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    if (password == null || password.isEmpty || user.email == null) return;
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'requires-recent-login'
                ? 'Please sign in again before deleting your account.'
                : error.message ?? 'Could not delete your account.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not delete your profile.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No signed-in account.')));
    }

    return Scaffold(
      backgroundColor: _lightGreen,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: _green,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load profile: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data();
          final name = (data?['name'] as String?)?.trim().isNotEmpty == true
              ? (data?['name'] as String).trim()
              : user.displayName ?? 'Farmer';
          final initial = name.isEmpty
              ? '?'
              : name.characters.first.toUpperCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? 'No email available',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ProfileAction(
                icon: Icons.edit_outlined,
                title: 'Edit name',
                subtitle: 'Update the name shown on your profile',
                onTap: () => _editName(context, user, name),
              ),
              _ProfileAction(
                icon: Icons.email_outlined,
                title: 'Email address',
                subtitle: user.email ?? 'No email available',
              ),
              _ProfileAction(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Language and onboarding preferences',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              _ProfileAction(
                icon: Icons.verified_user_outlined,
                title: 'Account status',
                subtitle: user.emailVerified
                    ? 'Email verified'
                    : 'Email not verified',
                onTap: user.emailVerified
                    ? null
                    : () => _sendVerification(context, user),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[200]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _deleteAccount(context, user),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account'),
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  final String initialName;

  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter your name' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4CAF50)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
