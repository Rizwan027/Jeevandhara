import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../screens/home/home_screen.dart';
import '../screens/scan/scan_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/advice/advice_screen.dart';
import '../screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: 5,
        itemBuilder: (context, index) {
          switch (index) {
            case 1:
              return const ScanScreenContent();
            case 2:
              return const ChatScreenContent();
            case 3:
              return const AdviceScreenContent();
            case 4:
              return const ProfileScreen();
            default:
              return const HomeScreenContent();
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: const ValueKey('main-navigation'),
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        backgroundColor: Colors.white,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        iconSize: 22,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: localization.getText('home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: localization.getText('scan'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: localization.getText('chat'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: localization.getText('advice'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: localization.getText('profile'),
          ),
        ],
      ),
    );
  }
}

// Wrapper widgets for each screen without their individual navigation bars
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen(showBottomNav: false);
  }
}

class ScanScreenContent extends StatelessWidget {
  const ScanScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScanScreen(showBottomNav: false);
  }
}

class ChatScreenContent extends StatelessWidget {
  const ChatScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatScreen(showBottomNav: false);
  }
}

class AdviceScreenContent extends StatelessWidget {
  const AdviceScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdviceScreen(showBottomNav: false);
  }
}
