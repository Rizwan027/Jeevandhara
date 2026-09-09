import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'onboarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _languages = {
    'English': Locale('en'),
    'Hindi': Locale('hi'),
    'Marathi': Locale('mr'),
    'Telugu': Locale('te'),
    'Tamil': Locale('ta'),
    'Bengali': Locale('bn'),
  };

  Future<void> _changeLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose language'),
        children: _languages.keys
            .map(
              (name) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, name),
                child: Text(name),
              ),
            )
            .toList(),
      ),
    );
    if (!mounted || selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', selected);
    if (!mounted) return;
    MyApp.of(context).setLocale(_languages[selected]!);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Language updated.')));
  }

  Future<void> _restartOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await prefs.remove('onboarding_complete_$userId');
    }
    if (!mounted) return;
    final selectedLanguage = prefs.getString('selected_language') ?? 'English';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(selectedLanguage: selectedLanguage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('Change the app language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('View onboarding again'),
            subtitle: const Text('Review the Jeevandhara introduction'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _restartOnboarding,
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Jeevandhara',
            applicationVersion: '1.0.0',
            applicationLegalese: 'Agricultural guidance prototype',
          ),
        ],
      ),
    );
  }
}
