import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../widgets/main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  final String selectedLanguage;

  const OnboardingScreen({super.key, required this.selectedLanguage});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> _getPages(BuildContext context) {
    return [
      {
        'icon': Icons.eco,
        'title': AppLocalizations.of(context)!.getText('onboarding1_title'),
        'description': AppLocalizations.of(context)!.getText('onboarding1_desc'),
      },
      {
        'icon': Icons.analytics,
        'title': AppLocalizations.of(context)!.getText('onboarding2_title'),
        'description': AppLocalizations.of(context)!.getText('onboarding2_desc'),
      },
      {
        'icon': Icons.notifications_active,
        'title': AppLocalizations.of(context)!.getText('onboarding3_title'),
        'description': AppLocalizations.of(context)!.getText('onboarding3_desc'),
      },
    ];
  }

  void _onNext() {
    final pages = _getPages(context);
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Skip button (only show if not on last page)
              if (_currentPage < pages.length - 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Skip to last page
                      _pageController.animateToPage(
                        pages.length - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.getText('skip'),
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(pages[index]);
                  },
                ),
              ),
              
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),
              const SizedBox(height: 32),
              
              // Next/Get Started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == pages.length - 1 
                        ? AppLocalizations.of(context)!.getText('getStarted')
                        : AppLocalizations.of(context)!.getText('next'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Back button (only show if not on first page)
              if (_currentPage > 0)
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.getText('back'),
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 16,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.getText('changeLanguage'),
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            page['icon'] as IconData? ?? Icons.eco,
            size: 60,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 32),
        // Title
        Text(
          page['title'] as String? ?? '',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          page['description'] as String? ?? '',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4CAF50) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force rebuild when language changes
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
