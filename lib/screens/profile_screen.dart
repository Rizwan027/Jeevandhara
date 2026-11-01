import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFF8FFFE);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _streamKey = 0;

  Future<void> _editName(
    BuildContext context,
    User user,
    String currentName,
  ) async {
    final localization = AppLocalizations.of(context)!;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: currentName),
    );

    if (name == null || name == currentName || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(localization.getText('profile_updating_name')),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
      }, SetOptions(merge: true));
      await user.updateDisplayName(name);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.getText('profile_name_updated'),
          ),
        ),
      );
    } on FirebaseException {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.getText('profile_name_update_failed'),
          ),
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.getText('profile_sign_out_title'),
        ),
        content: Text(
          AppLocalizations.of(context)!.getText('profile_sign_out_body'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.getText('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.getText('sign_out')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.getText('profile_verification_sent'),
          ),
        ),
      );
    } on FirebaseAuthException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.getText('profile_verification_failed'),
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context, User user) async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(dialogContext)!.getText('profile_delete_title'),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(
              dialogContext,
            )!.getText('profile_confirm_password'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.getText('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, passwordController.text),
            child: Text(
              AppLocalizations.of(dialogContext)!.getText('delete_account'),
            ),
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
                ? AppLocalizations.of(
                    context,
                  )!.getText('profile_reauth_required')
                : AppLocalizations.of(
                    context,
                  )!.getText('profile_delete_account_failed'),
          ),
        ),
      );
    } on FirebaseException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.getText('profile_delete_profile_failed'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(localization.getText('profile_no_signed_in_account')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ProfileScreen._lightGreen,
      appBar: AppBar(
        title: Text(localization.getText('profile')),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: ProfileScreen._green,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        key: ValueKey(_streamKey),
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      localization.getText('profile_unable_load'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _streamKey++;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(localization.getText('retry')),
                      style: FilledButton.styleFrom(
                        backgroundColor: ProfileScreen._green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data();
          final name = (data?['name'] as String?)?.trim().isNotEmpty == true
              ? (data?['name'] as String).trim()
              : user.displayName ?? localization.getText('profile_farmer');
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
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: ProfileScreen._green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ProfileScreen._green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? localization.getText('profile_no_email'),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ProfileAction(
                icon: Icons.edit_outlined,
                title: localization.getText('edit_name'),
                subtitle: localization.getText('profile_edit_name_subtitle'),
                onTap: () => _editName(context, user, name),
              ),
              _ProfileAction(
                icon: Icons.email_outlined,
                title: localization.getText('email_address'),
                subtitle:
                    user.email ?? localization.getText('profile_no_email'),
              ),
              _ProfileAction(
                icon: Icons.settings_outlined,
                title: localization.getText('settings'),
                subtitle: localization.getText('profile_settings_subtitle'),
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              _ProfileAction(
                icon: Icons.verified_user_outlined,
                title: localization.getText('account_status'),
                subtitle: user.emailVerified
                    ? localization.getText('profile_email_verified')
                    : localization.getText('profile_email_not_verified'),
                onTap: user.emailVerified
                    ? null
                    : () => _sendVerification(context, user),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: Text(localization.getText('sign_out')),
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
                label: Text(localization.getText('delete_account')),
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
    final localization = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localization.getText('edit_name')),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: localization.getText('auth_name_label'),
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? localization.getText('auth_enter_name')
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localization.getText('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(localization.getText('save')),
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
