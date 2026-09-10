import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/input_data/input_data_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _restoreLanguage();
  }

  Future<void> _restoreLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('selected_language');
    if (!mounted || language == null) return;
    setLocale(_localeForLanguage(language));
  }

  Locale _localeForLanguage(String language) {
    const locales = {
      'Hindi': Locale('hi'),
      'Telugu': Locale('te'),
      'Tamil': Locale('ta'),
      'Bengali': Locale('bn'),
      'Marathi': Locale('mr'),
      'English': Locale('en'),
    };
    return locales[language] ?? const Locale('en');
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
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
        Locale('te', ''), // Telugu
        Locale('ta', ''), // Tamil
        Locale('bn', ''), // Bengali
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
        if (!snapshot.hasData) return const AuthScreen();
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

  Locale _getLocale(String languageName) {
    switch (languageName) {
      case 'Hindi':
        return const Locale('hi', '');
      case 'Telugu':
        return const Locale('te', '');
      case 'Tamil':
        return const Locale('ta', '');
      case 'Bengali':
        return const Locale('bn', '');
      case 'Marathi':
        return const Locale('mr', '');
      case 'English':
      default:
        return const Locale('en', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> languages = [
      {'name': 'English', 'nativeName': 'English'},
      {'name': 'Hindi', 'nativeName': 'हिंदी'},
      {'name': 'Marathi', 'nativeName': 'मराठी'},
      {'name': 'Telugu', 'nativeName': 'తెలుగు'},
      {'name': 'Tamil', 'nativeName': 'தமிழ்'},
      {'name': 'Bengali', 'nativeName': 'বাংলা'},
    ];

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
                      const Text(
                        'Select your preferred language',
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
                          itemCount: languages.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFE0E0E0),
                            indent: 20,
                            endIndent: 20,
                          ),
                          itemBuilder: (context, index) {
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
                                  languages[index]['nativeName']!,
                                  style: TextStyle(
                                    fontSize:
                                        languages[index]['name'] == 'Bengali'
                                        ? 14
                                        : 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    fontFamily:
                                        languages[index]['name'] == 'Bengali'
                                        ? 'Roboto'
                                        : null,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              subtitle: Text(
                                languages[index]['name']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFF4CAF50),
                              ),
                              onTap: () {
                                final newLocale = _getLocale(
                                  languages[index]['name']!,
                                );
                                MyApp.of(context).setLocale(newLocale);
                                SharedPreferences.getInstance().then(
                                  (prefs) => prefs.setString(
                                    'selected_language',
                                    languages[index]['name']!,
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OnboardingScreen(
                                      selectedLanguage:
                                          languages[index]['name']!,
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
