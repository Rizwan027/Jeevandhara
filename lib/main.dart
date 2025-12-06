import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'widgets/main_navigation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');

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
      ],
      home: const LanguageSelectionScreen(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/main': (context) => const MainNavigation(),
      },
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
      {'name': 'Telugu', 'nativeName': 'తెలుగు'},
      {'name': 'Tamil', 'nativeName': 'தமிழ்'},
      {'name': 'Bengali', 'nativeName': 'বাংলা'},
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        width: 150, // Adjust size as needed
                        height: 150, // Adjust size as needed
                      ),
                      const SizedBox(height: 16),
                      // App Name
                      const Text(
                        'SmartAgri Advisor',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  languages[index]['nativeName']!,
                                  style: TextStyle(
                                    fontSize: languages[index]['name'] == 'Bengali' ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                    fontFamily: languages[index]['name'] == 'Bengali' 
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
                                final newLocale = _getLocale(languages[index]['name']!);
                                MyApp.of(context).setLocale(newLocale);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OnboardingScreen(
                                      selectedLanguage: languages[index]['name']!,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Voice Tutorial
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volume_up,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Voice Tutorial Available',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 14,
                              ),
                            ),
                          ],
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
