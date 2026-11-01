import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../localization/app_localizations.dart';
import '../../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  final bool showBottomNav;

  const ChatScreen({super.key, this.showBottomNav = true});

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

    // Add welcome message with quick action suggestions
    _addMessage(
      'Hello! I\'m your Smart Agriculture Assistant. 🌾\n\nI can help you with:\n🌱 **Crop Management:** Rice, Wheat, Cotton, Sugarcane varieties\n🔬 **Disease & Pest Control:** AI-powered diagnosis & treatment\n💰 **Market Intelligence:** Live prices & selling strategies\n🌧️ **Weather & Irrigation:** Smart farming recommendations\n🌿 **Soil Health:** pH testing, fertilizers, organic farming\n🏛️ **Government Schemes:** Subsidies, loans, insurance\n\n💡 **Quick Start:** Tap the buttons below or ask me anything!',
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

  void _addMessage(
    String text, {
    required bool isUser,
    bool isError = false,
    String? originalUserPrompt,
  }) {
    if (!mounted) return;
    setState(() {
      messages.add(
        ChatMessage(
          text: text,
          isUser: isUser,
          timestamp: DateTime.now(),
          isError: isError,
          originalUserPrompt: originalUserPrompt,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isTyping) return;

    _addMessage(text, isUser: true);
    _messageController.clear();

    // Show typing indicator
    setState(() => _isTyping = true);

    // Get AI response
    _getAIResponse(text);
  }

  Future<void> _getAIResponse(String userMessage) async {
    String response;
    String? localizedErrorKey;
    bool hasError = false;
    try {
      response = await _aiService.getAgriculturalAdvice(userMessage);
    } on AIServiceException catch (error) {
      response = error.message;
      localizedErrorKey = _getChatErrorKey(error.message);
      hasError = true;
    } catch (_) {
      response = '';
      localizedErrorKey = 'chat_error_generic';
      hasError = true;
    }

    if (!mounted) return;
    if (localizedErrorKey != null) {
      response = AppLocalizations.of(context)!.getText(localizedErrorKey);
    }
    setState(() => _isTyping = false);
    _addMessage(
      response,
      isUser: false,
      isError: hasError,
      originalUserPrompt: hasError ? userMessage : null,
    );
  }

  String? _getChatErrorKey(String message) => switch (message) {
    'Please enter a message of 1-4,000 characters.' =>
      'chat_error_invalid_input',
    'AI service is unavailable. Add GEMINI_API_KEY to your .env file.' =>
      'chat_error_unavailable',
    'The AI service returned an empty response.' => 'chat_error_empty_response',
    'The AI service took too long to respond. Please try again.' =>
      'chat_error_timeout',
    'The AI model is currently unavailable. Please try again later.' =>
      'chat_error_model_unavailable',
    'The AI service is not authorized. Please check its configuration.' =>
      'chat_error_unauthorized',
    'The AI service is busy. Please try again shortly.' => 'chat_error_busy',
    'Unable to generate a reply. Please try again.' => 'chat_error_generic',
    _ => null,
  };

  void _retryMessage(ChatMessage message) {
    if (_isTyping || message.originalUserPrompt == null) return;
    setState(() {
      messages.remove(message);
      _isTyping = true;
    });
    _getAIResponse(message.originalUserPrompt!);
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
    } else if (lowerMessage.contains('disease') ||
        lowerMessage.contains('pest')) {
      return _getDiseaseAdvice(lowerMessage);
    } else if (lowerMessage.contains('price') ||
        lowerMessage.contains('market')) {
      return _getMarketAdvice(lowerMessage);
    } else if (lowerMessage.contains('weather') ||
        lowerMessage.contains('rain')) {
      return _getWeatherAdvice(lowerMessage);
    } else if (lowerMessage.contains('soil') ||
        lowerMessage.contains('fertilizer')) {
      return _getSoilAdvice(lowerMessage);
    } else if (lowerMessage.contains('scheme') ||
        lowerMessage.contains('subsidy')) {
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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FFFE),
      body: Column(
        children: [
          // Chat header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFE8F5E9), const Color(0xFFF4FAF3)],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (widget.showBottomNav)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: localizations.getText('back'),
                        style: IconButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          minimumSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: 44),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.getText('chat_title'),
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B5E20),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _aiService.isAvailable
                                      ? const Color(0xFF388E3C)
                                      : const Color(0xFF9E9E9E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _aiService.isAvailable
                                      ? localizations.getText(
                                          'chat_status_online',
                                        )
                                      : localizations.getText(
                                          'chat_status_offline',
                                        ),
                                  softWrap: true,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _aiService.isAvailable
                                        ? const Color(0xFF388E3C)
                                        : Colors.grey[700],
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chat Messages and Quick Actions
          Expanded(
            child: Column(
              children: [
                // Quick Action Buttons (shown when no messages or after welcome)
                if (messages.length <= 1) _buildQuickActions(),

                // Chat Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(
                        messages[index],
                        isWelcome: index == 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Input Area
          _buildModernInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {bool isWelcome = false}) {
    final localizations = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isWelcome ? 8 : 6,
                horizontal: 4,
              ),
              child: Row(
                mainAxisAlignment: message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!message.isUser) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: message.isError
                            ? const LinearGradient(
                                colors: [Color(0xFFE57373), Color(0xFFEF5350)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                              ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (message.isError
                                        ? const Color(0xFFEF5350)
                                        : const Color(0xFF2E7D32))
                                    .withValues(alpha: 0.2),
                            blurRadius: 7,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        message.isError
                            ? Icons.error_outline
                            : Icons.agriculture_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isWelcome ? 18 : 16,
                        vertical: isWelcome ? 16 : 13,
                      ),
                      decoration: BoxDecoration(
                        gradient: message.isUser
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                              )
                            : isWelcome
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Color(0xFFF4F9F1)],
                              )
                            : null,
                        color: message.isUser || isWelcome
                            ? null
                            : message.isError
                            ? const Color(0xFFFFF5F4)
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(message.isUser ? 20 : 7),
                          bottomRight: Radius.circular(message.isUser ? 7 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: message.isUser
                                ? const Color(
                                    0xFF2E7D32,
                                  ).withValues(alpha: 0.18)
                                : message.isError
                                ? const Color(
                                    0xFFC62828,
                                  ).withValues(alpha: 0.08)
                                : const Color(
                                    0xFF183B1D,
                                  ).withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: !message.isUser
                            ? Border.all(
                                color: message.isError
                                    ? const Color(0xFFE57373)
                                    : isWelcome
                                    ? const Color(0xFFCEE2CB)
                                    : const Color(0xFFE2EEE2),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isWelcome) ...[
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    size: 17,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          message.isUser
                              ? Text(
                                  message.text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                )
                              : MarkdownBody(
                                  data: isWelcome
                                      ? localizations.getText('chat_welcome')
                                      : message.text,
                                  styleSheet: MarkdownStyleSheet(
                                    p: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: message.isError
                                          ? const Color(0xFFC62828)
                                          : const Color(0xFF1B5E20),
                                      height: 1.5,
                                    ),
                                    pPadding: EdgeInsets.only(
                                      bottom: isWelcome ? 12 : 10,
                                    ),
                                    strong: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                    ),
                                    em: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: message.isError
                                          ? const Color(0xFF9F2D2A)
                                          : const Color(0xFF2E5B35),
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                    h1: GoogleFonts.poppins(
                                      fontSize: 20,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                    h1Padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    h2: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                    h2Padding: const EdgeInsets.only(
                                      top: 7,
                                      bottom: 6,
                                    ),
                                    h3: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF245A2A),
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                    h3Padding: const EdgeInsets.only(
                                      top: 6,
                                      bottom: 5,
                                    ),
                                    h4: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF245A2A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    h5: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF245A2A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    h6: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF245A2A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    listIndent: 20,
                                    listBulletPadding: const EdgeInsets.only(
                                      right: 8,
                                    ),
                                    listBullet: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: message.isError
                                          ? const Color(0xFFC62828)
                                          : const Color(0xFF388E3C),
                                    ),
                                    code: GoogleFonts.robotoMono(
                                      fontSize: 12.5,
                                      color: message.isError
                                          ? const Color(0xFF8E2424)
                                          : const Color(0xFF245A2A),
                                      backgroundColor: message.isError
                                          ? const Color(0xFFFCE5E3)
                                          : const Color(0xFFEAF4E9),
                                    ),
                                    codeblockPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                    codeblockDecoration: BoxDecoration(
                                      color: message.isError
                                          ? const Color(0xFFFCE5E3)
                                          : const Color(0xFFF1F6EF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: message.isError
                                            ? const Color(
                                                0xFFE57373,
                                              ).withValues(alpha: 0.45)
                                            : const Color(0xFFDCE9D9),
                                      ),
                                    ),
                                    blockquotePadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                    blockquoteDecoration: BoxDecoration(
                                      color: message.isError
                                          ? const Color(0xFFFCE5E3)
                                          : const Color(0xFFF3F8F1),
                                      border: const Border(
                                        left: BorderSide(
                                          color: Color(0xFF66BB6A),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    blockSpacing: 8,
                                  ),
                                ),
                          if (message.isError &&
                              message.originalUserPrompt != null) ...[
                            const SizedBox(height: 10),
                            Tooltip(
                              message: localizations.getText(
                                'chat_retry_tooltip',
                              ),
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: _isTyping
                                      ? null
                                      : () => _retryMessage(message),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 44,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFC62828,
                                        ).withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.refresh_rounded,
                                          size: 17,
                                          color: Color(0xFFB3261E),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          localizations.getText('retry'),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFB3261E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            _formatTime(message.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: message.isUser
                                  ? Colors.white.withValues(alpha: 0.76)
                                  : message.isError
                                  ? const Color(0xFFB75D58)
                                  : Colors.grey[500],
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (message.isUser) ...[
                    const SizedBox(width: 9),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF2E7D32),
                        size: 17,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF183B1D).withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2EEE2)),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final localizations = AppLocalizations.of(context)!;
    final quickActions = <({String text, String query, IconData icon})>[
      (
        text: localizations.getText('chat_action_plant_disease'),
        query: 'Help with plant disease diagnosis',
        icon: Icons.health_and_safety_rounded,
      ),
      (
        text: localizations.getText('chat_action_weather_tips'),
        query: 'Weather and irrigation advice',
        icon: Icons.cloud_rounded,
      ),
      (
        text: localizations.getText('chat_action_soil_health'),
        query: 'Soil testing and fertilizer advice',
        icon: Icons.grass_rounded,
      ),
      (
        text: localizations.getText('chat_action_market_prices'),
        query: 'What are current market prices?',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: Color(0xFF388E3C),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  localizations.getText('chat_quick_actions'),
                  softWrap: true,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 280 ? 1 : 2;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickActions
                    .map(
                      (action) => SizedBox(
                        width: cardWidth,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _sendMessage(action.query),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 62),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF2E7D32,
                                  ).withValues(alpha: 0.14),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF183B1D,
                                    ).withValues(alpha: 0.035),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      action.icon,
                                      size: 19,
                                      color: const Color(0xFF388E3C),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      action.text,
                                      softWrap: true,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        height: 1.3,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildModernInputArea() {
    final localizations = AppLocalizations.of(context)!;
    final canSend = _messageController.text.trim().isNotEmpty && !_isTyping;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFEFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick suggestions (shown when text field is focused)
            if (_messageController.text.isEmpty && messages.length > 1)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickSuggestion(
                        '🌾',
                        localizations.getText('chat_suggestion_crop'),
                        promptText: 'Crop advice',
                      ),
                      const SizedBox(width: 8),
                      _buildQuickSuggestion(
                        '💰',
                        localizations.getText('chat_suggestion_market'),
                        promptText: 'Market prices',
                      ),
                      const SizedBox(width: 8),
                      _buildQuickSuggestion(
                        '🦠',
                        localizations.getText('chat_suggestion_disease'),
                        promptText: 'Disease help',
                      ),
                      const SizedBox(width: 8),
                      _buildQuickSuggestion(
                        '🌧️',
                        localizations.getText('chat_suggestion_weather'),
                        promptText: 'Weather info',
                      ),
                    ],
                  ),
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 2),
                  child: Tooltip(
                    message: localizations.getText('chat_attachment_tooltip'),
                    child: Material(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _showAttachmentOptions,
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.paperclip,
                              size: 17,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Text input field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F3),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20),
                      ),
                      minLines: 1,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: localizations.getText('chat_input_hint'),
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        suffixIcon: _messageController.text.isNotEmpty
                            ? IconButton(
                                tooltip: localizations.getText(
                                  'chat_clear_input_tooltip',
                                ),
                                onPressed: () {
                                  _messageController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                                iconSize: 18,
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                      ),
                      onChanged: (value) => setState(() {}),
                      onSubmitted: _sendMessage,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                Semantics(
                  button: true,
                  enabled: canSend,
                  label: localizations.getText('chat_send_tooltip'),
                  child: Tooltip(
                    message: localizations.getText('chat_send_tooltip'),
                    child: GestureDetector(
                      onTap: () => _sendMessage(_messageController.text),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: canSend
                              ? const Color(0xFF388E3C)
                              : const Color(0xFFB0BDB0),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: canSend
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.22),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white.withValues(
                            alpha: canSend ? 1 : 0.75,
                          ),
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestion(
    String emoji,
    String text, {
    required String promptText,
  }) {
    return Material(
      color: const Color(0xFFF4F9F1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _messageController.text = 'Tell me about $promptText';
          setState(() {});
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF1B5E20),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localizations.getText('chat_attachment_title'),
                textAlign: TextAlign.center,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildAttachmentOption(
                      FontAwesomeIcons.camera,
                      localizations.getText('chat_attachment_camera'),
                      localizations.getText('chat_attachment_camera_subtitle'),
                      () {
                        Navigator.pop(context);
                        // Implement camera functionality
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildAttachmentOption(
                      FontAwesomeIcons.images,
                      localizations.getText('chat_attachment_gallery'),
                      localizations.getText('chat_attachment_gallery_subtitle'),
                      () {
                        Navigator.pop(context);
                        // Implement gallery functionality
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildAttachmentOption(
                      FontAwesomeIcons.locationDot,
                      localizations.getText('chat_attachment_location'),
                      localizations.getText(
                        'chat_attachment_location_subtitle',
                      ),
                      () {
                        Navigator.pop(context);
                        // Implement location sharing
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FaIcon(icon, color: const Color(0xFF4CAF50), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              softWrap: true,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              softWrap: true,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
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
        style: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF1B5E20)),
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
              const Icon(Icons.volume_up, size: 16, color: Color(0xFF4CAF50)),
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
            child: const Icon(Icons.send, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context)!.getText('chat_typing_label'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 5),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final phase = (_controller.value + index / 3) % 1;
                final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
                return Transform.scale(
                  scale: 0.72 + pulse * 0.28,
                  child: Opacity(opacity: 0.5 + pulse * 0.5, child: child),
                );
              },
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF388E3C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Data model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? originalUserPrompt;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.originalUserPrompt,
  });
}
