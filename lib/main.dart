import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/input_data/input_data_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/main_navigation.dart';

const Map<String, String> appLanguages = {
  'en': 'English',
  'hi': 'हिंदी',
  'mr': 'मराठी',
};

const String selectedLanguagePreferenceKey = 'selected_language';

Future<void> showLanguageSelector(BuildContext context) async {
  final localization = AppLocalizations.of(context)!;
  final selectedCode = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              localization.getText('choose_language'),
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
          ),
          ...appLanguages.entries.map((language) {
            final isSelected =
                MyApp.of(context).locale.languageCode == language.key;
            return ListTile(
              title: Text(language.value),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                  : null,
              selected: isSelected,
              onTap: () => Navigator.pop(sheetContext, language.key),
            );
          }),
        ],
      ),
    ),
  );
  if (selectedCode == null || !context.mounted) return;

  try {
    await MyApp.of(context).setLocale(Locale(selectedCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.getText('language_updated'),
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not save language preference.')),
    );
    developer.log(
      'Could not save selected language.',
      error: error,
      name: 'Localization',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Development can run without a local key; AIService will use its fallback.
  }
  Object? firebaseError;
  try {
    await Firebase.initializeApp();
  } catch (error) {
    firebaseError = error;
  }
  runApp(MyApp(firebaseError: firebaseError));
}

class MyApp extends StatefulWidget {
  final Object? firebaseError;

  const MyApp({super.key, this.firebaseError});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');

  Locale get locale => _locale;

  @override
  void initState() {
    super.initState();
    _restoreLanguage();
  }

  Future<void> _restoreLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLanguage = prefs.getString(selectedLanguagePreferenceKey);
    if (storedLanguage == null) return;
    final restoredLocale = _localeForPreference(storedLanguage);
    if (storedLanguage != restoredLocale.languageCode) {
      await prefs.setString(
        selectedLanguagePreferenceKey,
        restoredLocale.languageCode,
      );
    }
    if (!mounted) return;
    setState(() {
      _locale = restoredLocale;
    });
  }

  Locale _localeForPreference(String language) {
    switch (language.trim().toLowerCase()) {
      case 'hi':
      case 'hindi':
        return const Locale('hi');
      case 'mr':
      case 'marathi':
        return const Locale('mr');
      case 'en':
      case 'english':
      case 'te':
      case 'telugu':
      case 'ta':
      case 'tamil':
      case 'bn':
      case 'bengali':
      default:
        return const Locale('en');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    final locale = _localeForPreference(newLocale.languageCode);
    final previousLocale = _locale;
    setState(() {
      _locale = locale;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(selectedLanguagePreferenceKey, locale.languageCode);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locale = previousLocale;
        });
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAgri Advisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        scaffoldBackgroundColor: const Color(0xFFF5F9F5),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('hi', ''), // Hindi
        Locale('mr', ''), // Marathi
      ],
      home: AuthGate(firebaseError: widget.firebaseError),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/main': (context) => const MainNavigation(),
        '/input_data': (context) => const InputDataScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final Object? firebaseError;

  const AuthGate({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    if (firebaseError != null) {
      return FirebaseFailureScreen(error: firebaseError!);
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        developer.log(
          '[AUTH] auth state changed: ${snapshot.connectionState}, user=${snapshot.data?.uid}',
          name: 'Auth',
        );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return Stack(
            children: [
              const Positioned.fill(child: AuthScreen()),
              Positioned(
                top: 4,
                right: 8,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    tooltip: AppLocalizations.of(
                      context,
                    )!.getText('choose_language'),
                    onPressed: () => showLanguageSelector(context),
                    icon: const Icon(Icons.language),
                  ),
                ),
              ),
            ],
          );
        }
        final user = snapshot.data!;
        developer.log(
          '[AUTH] profile loading started for ${user.uid}',
          name: 'Auth',
        );
        SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 10))
            .then((prefs) => prefs.setString('active_user_id', user.uid))
            .catchError((error) {
              developer.log(
                '[AUTH] profile loading failed: $error',
                error: error,
                name: 'Auth',
              );
              return false;
            });
        return FutureBuilder<bool>(
          future: SharedPreferences.getInstance()
              .then(
                (prefs) =>
                    prefs.getBool('onboarding_complete_${user.uid}') ?? false,
              )
              .timeout(const Duration(seconds: 10))
              .catchError((error) {
                developer.log(
                  '[AUTH] profile loading failed; using onboarding default: $error',
                  error: error,
                  name: 'Auth',
                );
                return false;
              }),
          builder: (context, onboardingSnapshot) {
            if (!onboardingSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final destination = onboardingSnapshot.data!
                ? 'authenticated shell'
                : 'language selection';
            developer.log(
              '[AUTH] AuthGate transition: $destination',
              name: 'Auth',
            );
            return onboardingSnapshot.data!
                ? const MainNavigation()
                : const LanguageSelectionScreen();
          },
        );
      },
    );
  }
}

class FirebaseFailureScreen extends StatelessWidget {
  final Object error;

  const FirebaseFailureScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Jeevandhara could not start',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Firebase configuration or connectivity is unavailable. Check your connection and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => main(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              Text(
                error.runtimeType.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: 150, // Adjust size as needed
                        height: 150, // Adjust size as needed
                      ),
                      const SizedBox(height: 24),
                      // Subtitle
                      Text(
                        AppLocalizations.of(context)!.getText('selectLanguage'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Language List
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: appLanguages.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFE0E0E0),
                            indent: 20,
                            endIndent: 20,
                          ),
                          itemBuilder: (context, index) {
                            final language = appLanguages.entries.elementAt(
                              index,
                            );
                            final isSelected =
                                MyApp.of(context).locale.languageCode ==
                                language.key;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              title: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  language.value,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              subtitle: Text(
                                language.key.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.arrow_forward_ios,
                                size: 16,
                                color: const Color(0xFF4CAF50),
                              ),
                              onTap: () async {
                                try {
                                  await MyApp.of(
                                    context,
                                  ).setLocale(Locale(language.key));
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not save language preference.',
                                      ),
                                    ),
                                  );
                                  developer.log(
                                    'Could not save selected language.',
                                    error: error,
                                    name: 'Localization',
                                  );
                                  return;
                                }
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OnboardingScreen(
                                      selectedLanguage: language.key,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
