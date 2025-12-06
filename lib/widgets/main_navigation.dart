import 'package:flutter/material.dart';
import 'package:jeevandhara/screens/home/home_screen.dart';
import 'package:jeevandhara/screens/scan/scan_screen.dart';
import 'package:jeevandhara/screens/chat/chat_screen.dart';
import 'package:jeevandhara/screens/advice/advice_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

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
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          HomeScreenContent(),
          ScanScreenContent(),
          ChatScreenContent(),
          AdviceScreenContent(),
          ProfileScreenPlaceholder(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: 'Scan Crop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Advice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
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

class ProfileScreenPlaceholder extends StatelessWidget {
  const ProfileScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(height: 16),
            Text(
              'Profile Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}