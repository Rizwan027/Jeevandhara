import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeevandhara/screens/advice/advice_screen.dart';
import 'package:jeevandhara/screens/home/home_screen.dart';
import 'package:jeevandhara/screens/scan/scan_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commonQuestions = [
      'What crop should I plant?',
      'How to treat plant disease?',
      'Current market prices?',
      'Weather forecast',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFF8),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF0FFF4),
              Colors.white.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacing (no app bar in the mock)
              const SizedBox(height: 8),

              // Common Questions chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Common Questions',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: commonQuestions
                      .map(
                        (q) => _QuestionChip(label: q),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Chat area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _AssistantMessageBubble(),
                  ),
                ),
              ),

              // Input bar
              _ChatInputBar(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    const currentIndex = 3; // Chat tab

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == currentIndex) return;

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdviceScreen()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
        } else if (index == 4) {
          // TODO: Implement Settings screen navigation
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lightbulb),
          label: 'Advice',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _QuestionChip extends StatelessWidget {
  final String label;

  const _QuestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB2DFDB)),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 13,
          color: const Color(0xFF1B5E20),
        ),
      ),
    );
  }
}

class _AssistantMessageBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon on the left
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            // Message bubble
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB2DFDB)),
                ),
                padding: const EdgeInsets.all(14),
                child: Text(
                  "Hello! I'm your SmartAgri assistant.\nHow can I help you with your farming today?",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Row(
            children: [
              Text(
                '18:05',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.volume_up,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FFF8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB2DFDB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type your question...',
                        hintStyle: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.mic_none,
                    size: 20,
                    color: Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}


