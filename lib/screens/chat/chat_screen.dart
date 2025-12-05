import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jeevandhara/screens/advice/advice_screen.dart';
import 'package:jeevandhara/screens/home/home_screen.dart';
import 'package:jeevandhara/screens/scan/scan_screen.dart';
import 'package:jeevandhara/services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  List<ChatMessage> messages = [];
  bool _isTyping = false;
  late AIService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    // Add welcome message
    _addMessage(
      'Hello! I\'m your Smart Agriculture Assistant. 🌾\n\nI can help you with:\n🌱 **Crop Management:** Rice, Wheat, Cotton, Sugarcane varieties\n🔬 **Disease & Pest Control:** AI-powered diagnosis & treatment\n💰 **Market Intelligence:** Live prices & selling strategies\n🌧️ **Weather & Irrigation:** Smart farming recommendations\n🌿 **Soil Health:** pH testing, fertilizers, organic farming\n🏛️ **Government Schemes:** Subsidies, loans, insurance\n\n💡 **Try asking:** "Rice farming guide" or "Current market prices"\n\nHow can I help you today?',
      isUser: false,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    
    _addMessage(text, isUser: true);
    _messageController.clear();
    
    // Show typing indicator
    setState(() => _isTyping = true);
    
    // Get AI response
    _getAIResponse(text);
  }

  Future<void> _getAIResponse(String userMessage) async {
    try {
      // Try to get AI response first
      String response;
      if (_aiService.isAIAvailable()) {
        response = await _aiService.getAgriculturalAdvice(userMessage);
      } else {
        response = _getFallbackResponse(userMessage);
      }
      
      // Add AI response
      setState(() => _isTyping = false);
      _addMessage(response, isUser: false);
    } catch (e) {
      // Fallback to predefined response on error
      setState(() => _isTyping = false);
      _addMessage(_getFallbackResponse(userMessage), isUser: false);
    }
  }

  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Use existing predefined response logic as fallback
    if (lowerMessage.contains('rice')) {
      return _getRiceAdvice(lowerMessage);
    } else if (lowerMessage.contains('wheat')) {
      return _getWheatAdvice(lowerMessage);
    } else if (lowerMessage.contains('cotton')) {
      return _getCottonAdvice(lowerMessage);
    } else if (lowerMessage.contains('sugarcane')) {
      return _getSugarcaneAdvice(lowerMessage);
    } else if (lowerMessage.contains('disease') || lowerMessage.contains('pest')) {
      return _getDiseaseAdvice(lowerMessage);
    } else if (lowerMessage.contains('price') || lowerMessage.contains('market')) {
      return _getMarketAdvice(lowerMessage);
    } else if (lowerMessage.contains('weather') || lowerMessage.contains('rain')) {
      return _getWeatherAdvice(lowerMessage);
    } else if (lowerMessage.contains('soil') || lowerMessage.contains('fertilizer')) {
      return _getSoilAdvice(lowerMessage);
    } else if (lowerMessage.contains('scheme') || lowerMessage.contains('subsidy')) {
      return _getGovernmentSchemeAdvice();
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! 👋 I\'m your Smart Agriculture Assistant.\n\nI can help you with:\n🌾 Crop recommendations\n🔍 Disease identification\n💰 Market prices\n🌧️ Weather updates\n🚜 Farming techniques\n💡 Government schemes\n\nWhat would you like to know about farming today?';
    } else {
      return _getDefaultResponse();
    }
  }


  String _getRiceAdvice(String message) {
    if (message.contains('variety') || message.contains('type')) {
      return '🌾 Best Rice Varieties for Your Region:\n\n🏆 **High Yield Varieties:**\n• IR-64: 5-6 tons/hectare, 120 days\n• Pusa Basmati: Premium quality, ₹4000/quintal\n• Sona Masuri: Short grain, market favorite\n\n💧 **Water Requirements:**\n• Transplanted: 1200-1500mm\n• Direct seeded: 800-1200mm\n\n📅 **Best Planting Time:**\n• Kharif: June-July\n• Rabi: November-December\n\nWhich variety interests you most?';
    } else if (message.contains('price')) {
      return '💰 Rice Market Update:\n\n📈 **Current Prices:**\n• Common Rice: ₹2,850/quintal (↑8%)\n• Basmati: ₹4,200/quintal (↑12%)\n• Parboiled: ₹3,100/quintal (↑5%)\n\n🔮 **Price Forecast:**\n• Expected to rise by 10-15% this month\n• High demand from export markets\n• Good time to sell if you have stock!\n\n📱 Set price alerts for ₹3,000/quintal?';
    } else if (message.contains('disease')) {
      return '🦠 Common Rice Diseases:\n\n⚠️ **Major Threats:**\n• **Blast Disease**: Brown spots on leaves\n  Treatment: Tricyclazole spray\n• **Sheath Blight**: Diamond-shaped lesions\n  Treatment: Propiconazole 25EC\n• **Bacterial Leaf Blight**: Yellow strips\n  Treatment: Copper fungicide\n\n🛡️ **Prevention:**\n• Use certified seeds\n• Proper spacing (15x15 cm)\n• Avoid excess nitrogen\n\nNeed specific treatment for your crop?';
    }
    return '🌾 Rice Farming Complete Guide:\n\n✅ **Best Practices:**\n• Soil pH: 5.5-7.0\n• Water depth: 2-5cm constantly\n• Spacing: 15x15cm or 20x20cm\n• Fertilizer: 120:60:40 NPK kg/hectare\n\n📊 **Expected Returns:**\n• Yield: 4-6 tons/hectare\n• Cost: ₹25,000/hectare\n• Profit: ₹35,000-50,000/hectare\n\n🌱 Want specific advice about planting, diseases, or varieties?';
  }

  String _getWheatAdvice(String message) {
    if (message.contains('variety')) {
      return '🌾 Top Wheat Varieties:\n\n🥇 **High Yielding:**\n• HD-2967: 4.5-5.5 tons/hectare\n• PBW-343: Disease resistant\n• WH-542: Drought tolerant\n\n🌡️ **Climate Needs:**\n• Temperature: 15-25°C\n• Rainfall: 75-100cm annually\n\n📅 **Sowing Time:**\n• October 15 - November 30\n• Late sowing reduces yield by 1% per day\n\nWhich region are you farming in?';
    }
    return '🌾 Wheat Cultivation Guide:\n\n✅ **Optimal Conditions:**\n• Sowing: October-November\n• Soil: Well-drained loamy\n• Seed rate: 100-125 kg/hectare\n\n💰 **Economics:**\n• Current price: ₹2,100/quintal\n• Production cost: ₹20,000/hectare\n• Expected profit: ₹25,000/hectare\n\n🔍 Need help with specific aspect?';
  }

  String _getCottonAdvice(String message) {
    return '🌱 Cotton Farming Insights:\n\n🎯 **High-Value Crop:**\n• **Bt Cotton**: Pest resistant varieties\n• **Yield**: 15-20 quintals/hectare\n• **Current Price**: ₹6,200/quintal (↑12%)\n\n⚠️ **Key Challenges:**\n• Pink bollworm management\n• Water requirement: 700-1300mm\n• Market price volatility\n\n💡 **Success Tips:**\n• Integrated pest management\n• Drip irrigation system\n• Quality seed selection\n\nNeed specific pest management advice?';
  }

  String _getSugarcaneAdvice(String message) {
    return '🌿 Sugarcane Cultivation:\n\n💰 **Highly Profitable:**\n• Yield: 80-100 tons/hectare\n• Duration: 12-18 months\n• Current Price: ₹350/quintal\n\n🌱 **Best Varieties:**\n• Co-86032: High sugar content\n• Co-238: Disease resistant\n• Co-0238: Early maturing\n\n💧 **Water Management:**\n• Critical stages: Germination, tillering\n• Irrigation: Every 7-10 days\n• Annual requirement: 1800-2500mm\n\nInterested in drip irrigation setup?';
  }

  String _getDiseaseAdvice(String message) {
    if (message.contains('rice') || message.contains('paddy')) {
      return '🦠 Rice Disease Management:\n\n🔍 **Common Symptoms:**\n• **Brown spots**: Likely blast disease\n• **Yellow stripes**: Bacterial blight\n• **Diamond lesions**: Sheath blight\n\n💊 **Treatment Protocol:**\n• Tricyclazole for blast\n• Copper fungicide for blight\n• Propiconazole for sheath blight\n\n📱 Use our Plant Scanner for instant diagnosis!\nTap the scan button in the home screen.';
    }
    return '🔬 Plant Disease Diagnosis:\n\n📸 **For Accurate Diagnosis:**\n• Take clear photos of affected parts\n• Note when symptoms started\n• Check multiple plants\n\n⚡ **Quick Actions:**\n• Use our AI scanner for instant results\n• Common treatments available\n• Local expert consultation\n\n🩺 **Prevention Better than Cure:**\n• Crop rotation\n• Resistant varieties\n• Proper spacing\n\nShall I help you scan your crop?';
  }

  String _getWeatherAdvice(String message) {
    if (message.contains('rain')) {
      return '🌧️ Weather & Rain Advisory:\n\n📊 **7-Day Forecast:**\n• Today: 28°C, 60% humidity\n• Tomorrow: Light rain expected\n• This week: 25-40mm rainfall\n\n🌾 **Farming Actions:**\n• ✅ Good for transplanting\n• ⚠️ Postpone spraying\n• 🚜 Prepare drainage channels\n\n📱 **Weather Alerts:**\n• Heavy rain warning for Thursday\n• Hailstorm alert for weekend\n\nNeed location-specific forecast?';
    }
    return '🌤️ Weather & Irrigation Guide:\n\n📈 **Current Conditions:**\n• Temperature: 26°C (Optimal for crops)\n• Humidity: 65% (Good moisture)\n• Wind: 12 km/h (Light breeze)\n\n💧 **Irrigation Schedule:**\n• Morning: 6-8 AM (Best time)\n• Evening: 5-7 PM (Secondary)\n• Avoid: 10 AM - 4 PM\n\n🎯 **Smart Farming:**\n• Drip irrigation saves 40% water\n• Soil moisture sensors available\n\nWant irrigation system recommendations?';
  }

  String _getMarketAdvice(String message) {
    return '📈 Market Intelligence:\n\n💰 **Today\'s Prices (Per Quintal):**\n• Rice: ₹2,850 (↑8%) 🔥\n• Wheat: ₹2,100 (↓2%)\n• Cotton: ₹6,200 (↑12%) 🔥\n• Sugarcane: ₹350 (→)\n• Pulses: ₹5,500 (↑15%) 🔥\n\n📊 **Market Trends:**\n• Export demand increasing\n• Festive season boost expected\n• Storage facilities recommended\n\n🎯 **Selling Strategy:**\n• Rice: Sell now, prices peak\n• Cotton: Hold for 2 weeks\n• Pulses: Excellent time to sell\n\nSet price alerts for your crops?';
  }

  String _getSoilAdvice(String message) {
    if (message.contains('ph') || message.contains('test')) {
      return '🧪 Soil Testing & pH Management:\n\n📊 **Optimal pH Ranges:**\n• Rice: 5.5-7.0 (Slightly acidic)\n• Wheat: 6.0-7.5 (Neutral)\n• Cotton: 5.8-8.0 (Wide range)\n\n🔬 **Testing Available:**\n• Free soil testing at Krishi Kendras\n• Home test kits: ₹200-500\n• Results in 24-48 hours\n\n⚗️ **pH Correction:**\n• High pH: Add sulfur\n• Low pH: Add lime\n• Organic matter always helps\n\nNeed help finding nearest testing center?';
    }
    return '🌱 Soil Health Management:\n\n✅ **Your Current Status:**\n• pH Level: 6.5 (Optimal)\n• Organic Matter: Good\n• Nitrogen: Moderate\n• Phosphorus: Adequate\n\n🌿 **Improvement Tips:**\n• Add compost 2-3 tons/hectare\n• Green manuring with dhaincha\n• Crop rotation with legumes\n\n📱 **Fertilizer Calculator:**\n• NPK: 120:60:40 for rice\n• Apply in 3 split doses\n• Soil test every 2 years\n\nWant customized fertilizer plan?';
  }

  String _getPlantingAdvice(String message) {
    return '🌱 Planting & Harvesting Calendar:\n\n📅 **Current Season (December):**\n\n🌾 **Rabi Crops (Plant Now):**\n• Wheat: Plant by Dec 15\n• Mustard: Plant by Dec 10\n• Gram: Plant by Nov 30\n• Barley: Plant by Dec 20\n\n⏰ **Timing Critical:**\n• Every day delay = 1% yield loss\n• Weather window closing soon\n• Seed availability good\n\n🎯 **Next Steps:**\n1. Prepare seedbed\n2. Check seed quality\n3. Plan irrigation\n\nWhich crop are you planning?';
  }

  String _getGovernmentSchemeAdvice() {
    return '🏛️ Government Schemes 2024:\n\n💰 **Financial Support:**\n• **PM-KISAN**: ₹6,000/year direct transfer\n• **Crop Insurance**: Up to ₹2 lakh coverage\n• **KCC Loans**: 4% interest rate\n\n🚜 **Equipment Subsidies:**\n• Tractors: 25-50% subsidy\n• Drip irrigation: 55% subsidy\n• Solar pumps: 60% subsidy\n\n📋 **Application Process:**\n• Online portal: pmkisan.gov.in\n• Required: Aadhaar, bank account\n• Processing time: 30-45 days\n\n📱 Need help with specific application?';
  }

  String _getGeneralFarmingAdvice() {
    return '🚜 Smart Farming Tips:\n\n🎯 **Modern Techniques:**\n• Precision agriculture with GPS\n• Drone monitoring for large fields\n• IoT sensors for real-time data\n\n📈 **Increase Profitability:**\n• Crop diversification\n• Value-added processing\n• Direct marketing to consumers\n\n🌍 **Sustainable Practices:**\n• Organic farming certification\n• Water conservation techniques\n• Integrated pest management\n\n💡 **Success Mantra:**\n"Right crop + Right time + Right technique = Maximum profit"\n\nWhat aspect interests you most?';
  }

  String _getDefaultResponse() {
    return '🤖 I\'m here to help with your farming questions!\n\n💬 **You can ask me about:**\n🌾 Crop varieties and cultivation\n🦠 Disease and pest management\n💰 Market prices and trends\n🌧️ Weather and irrigation\n🌱 Soil health and fertilizers\n🏛️ Government schemes\n\n💡 **Try asking:**\n• "What rice variety should I grow?"\n• "Current market prices?"\n• "How to treat rice blast disease?"\n• "When to plant wheat?"\n\nWhat would you like to know?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FFFE),
      body: Column(
        children: [
          // Modern App Bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF81C784).withOpacity(0.05),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.robot,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Farm Assistant',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            'Online • Always ready to help',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
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


          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),

          // Input Area
          _buildModernInputArea(),
        ],
      ),
    );
  }


  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const FaIcon(
                FontAwesomeIcons.robot,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFF4CAF50)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isUser 
                ? Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20),
                        height: 1.4,
                      ),
                      strong: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      em: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      h1: GoogleFonts.poppins(
                        fontSize: 18,
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                      h2: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                      h3: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                      ),
                      listBullet: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF4CAF50),
                      ),
                      code: GoogleFonts.robotoMono(
                        fontSize: 13,
                        color: const Color(0xFF2E7D32),
                        backgroundColor: const Color(0xFFF1F8E9),
                      ),
                    ),
                  ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const FaIcon(
              FontAwesomeIcons.robot,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: (math.sin((value * math.pi * 2) + (index * 0.5)) * 0.3) + 0.7,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything about farming...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _sendMessage,
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
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

// Data model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}


