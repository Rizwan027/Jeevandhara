import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey =
      'AIzaSyDn1tGER3e7laK3XpgOiUOve8nsEEHB7q8'; // You'll need to add your API key
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 512,
      ),
    );
  }

  Future<String> getAgriculturalAdvice(String userQuestion) async {
    try {
      // Enhanced prompt with agricultural context
      final prompt =
          """
You are an expert agricultural advisor AI assistant helping farmers in India. 
Provide brief, practical farming advice.

Guidelines:
- Keep responses SHORT (max 100-150 words)
- Focus on 2-3 most important points only
- Use bullet points for clarity
- Include specific costs in ₹ when relevant
- Use 1-2 emojis for key points
- Give direct answers, avoid long explanations
- Prioritize immediate actionable steps

Farmer's Question: $userQuestion

Provide a concise, practical response:
""";

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return _getFallbackResponse(userQuestion);
      }
    } catch (e) {
      print('AI Service Error: $e');
      return _getFallbackResponse(userQuestion);
    }
  }

  String _getFallbackResponse(String userQuestion) {
    final lowerQuestion = userQuestion.toLowerCase();

    // Fallback to predefined responses if AI fails
    if (lowerQuestion.contains('rice')) {
      return """🌾 Rice Farming Guide:

✅ **Best Practices:**
• Soil pH: 5.5-7.0
• Water depth: 2-5cm constantly  
• Spacing: 15x15cm or 20x20cm
• Fertilizer: 120:60:40 NPK kg/hectare

📊 **Expected Returns:**
• Yield: 4-6 tons/hectare
• Cost: ₹25,000/hectare
• Profit: ₹35,000-50,000/hectare

🌱 Need specific advice about varieties, diseases, or market prices?""";
    } else if (lowerQuestion.contains('price') ||
        lowerQuestion.contains('market')) {
      return """💰 Current Market Prices (Per Quintal):

• Rice: ₹2,850 (↑8%) 🔥
• Wheat: ₹2,100 (↓2%)
• Cotton: ₹6,200 (↑12%) 🔥
• Sugarcane: ₹350 (→)
• Pulses: ₹5,500 (↑15%) 🔥

📈 **Market Trends:**
• Export demand increasing
• Festive season boost expected
• Storage facilities recommended

🎯 **Selling Strategy:** Rice & Cotton prices are at peak - good time to sell!""";
    } else if (lowerQuestion.contains('disease') ||
        lowerQuestion.contains('pest')) {
      return """🔬 Plant Disease Management:

📸 **For Accurate Diagnosis:**
• Take clear photos of affected parts
• Note when symptoms started
• Check multiple plants

⚡ **Common Treatments:**
• Blast disease: Tricyclazole spray
• Bacterial blight: Copper fungicide  
• Stem borer: Chlorpyrifos application

🩺 **Prevention:** Use resistant varieties, proper spacing, and avoid excess nitrogen.

💡 Use our Plant Scanner for instant AI diagnosis!""";
    } else {
      return """🤖 I'm here to help with your farming questions!

💬 **You can ask me about:**
🌾 Crop varieties and cultivation
🦠 Disease and pest management  
💰 Market prices and trends
🌧️ Weather and irrigation
🌱 Soil health and fertilizers
🏛️ Government schemes

💡 **Try asking:**
• "Best rice variety for my region"
• "How to increase wheat yield"
• "Current market prices"
• "Treatment for plant diseases"

What would you like to know?""";
    }
  }

  // Method to check if AI service is available
  bool isAIAvailable() {
    return _apiKey != 'YOUR_GEMINI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}
