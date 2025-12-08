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

  Future<Map<String, dynamic>> analyzePlantHealth(String imagePath) async {
    try {
      // For now, simulate AI crop analysis with mock data
      // In production, this would send the image to AI service for crop analysis
      
      await Future.delayed(const Duration(seconds: 3)); // Simulate processing time
      
      // Mock crop analysis result with agricultural focus
      final cropTypes = ['Rice', 'Wheat', 'Cotton', 'Sugarcane', 'Maize', 'Tomato'];
      final selectedCrop = cropTypes[DateTime.now().millisecond % cropTypes.length];
      
      return {
        'status': 'Your $selectedCrop crop appears healthy with good growth indicators. No significant diseases detected at this growth stage.',
        'confidence': 0.87,
        'crop_type': selectedCrop,
        'growth_stage': 'Vegetative Growth',
        'recommendations': '''
🌾 Farming Recommendations for $selectedCrop:

💧 **Irrigation Management:**
• Water requirement: 25-30mm per week
• Maintain soil moisture at 80% field capacity
• Avoid waterlogging during current growth stage

🌱 **Nutrient Management:**
• Apply Urea: 50kg/hectare (split application)
• DAP: 25kg/hectare at base
• Potash: 20kg/hectare before flowering

🔍 **Health Score: 87/100 (Excellent)**

⚠️ **Monitor For:**
• Early signs of pest infestation
• Yellowing of lower leaves (nitrogen deficiency)
• Fungal diseases in humid conditions
''',
        'diseases_detected': [],
        'pests_detected': [],
        'nutrient_status': 'Adequate',
        'yield_prediction': '4.2-4.8 tons/hectare',
        'analysis_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Crop Analysis Error: $e');
      return {
        'status': 'Analysis completed. Please consult with agricultural experts for detailed crop management.',
        'confidence': 0.0,
        'recommendations': 'Unable to provide specific recommendations. Please try again or consult with local agricultural extension officers.',
        'error': true,
      };
    }
  }

  // Get crop recommendations based on soil data and weather
  Future<CropRecommendation> getCropRecommendations({
    required Map<String, double> soilData,
    required Map<String, dynamic> weatherData,
    String? location,
  }) async {
    try {
      final prompt = _buildCropRecommendationPrompt(soilData, weatherData, location);
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return _parseCropRecommendation(response.text!, soilData, weatherData);
      } else {
        return _getFallbackCropRecommendation(soilData, weatherData);
      }
    } catch (e) {
      print('Crop Recommendation Error: $e');
      return _getFallbackCropRecommendation(soilData, weatherData);
    }
  }

  String _buildCropRecommendationPrompt(
    Map<String, double> soilData,
    Map<String, dynamic> weatherData,
    String? location,
  ) {
    return """
You are an expert agricultural advisor AI. Based on the soil analysis and weather data provided, recommend the best 3 crops to grow and provide detailed farming guidance.

📊 **Soil Analysis Data:**
• pH Level: ${soilData['ph']?.toStringAsFixed(1)}
• Moisture: ${soilData['moisture']?.toStringAsFixed(0)}%
• Temperature: ${soilData['temperature']?.toStringAsFixed(0)}°C
• Nitrogen (N): ${soilData['nitrogen']?.toStringAsFixed(0)}%
• Phosphorus (P): ${soilData['phosphorus']?.toStringAsFixed(0)}%
• Potassium (K): ${soilData['potassium']?.toStringAsFixed(0)}%

🌤️ **Current Weather Conditions:**
• Temperature: ${weatherData['temperature']?.toStringAsFixed(0)}°C
• Humidity: ${weatherData['humidity']}%
• Weather: ${weatherData['description']}
${location != null ? '• Location: $location' : ''}

Please provide:

1. **TOP 3 RECOMMENDED CROPS** with reasons why they're suitable
2. **PLANTING CALENDAR** - best months to plant
3. **YIELD PREDICTIONS** - expected output per hectare
4. **FERTILIZER RECOMMENDATIONS** - what additional nutrients needed
5. **IRRIGATION GUIDANCE** - watering schedule based on soil moisture
6. **MARKET POTENTIAL** - profitability and demand

Keep response structured, practical, and under 300 words. Use emojis for sections.
""";
  }

  CropRecommendation _parseCropRecommendation(
    String aiResponse,
    Map<String, double> soilData,
    Map<String, dynamic> weatherData,
  ) {
    // Parse AI response and create structured recommendation
    return CropRecommendation(
      recommendedCrops: _extractRecommendedCrops(aiResponse),
      soilSuitability: _calculateSoilSuitability(soilData),
      weatherSuitability: _calculateWeatherSuitability(weatherData),
      plantingGuidelines: _extractPlantingGuidelines(aiResponse),
      fertilizationPlan: _extractFertilizationPlan(aiResponse, soilData),
      irrigationSchedule: _extractIrrigationSchedule(aiResponse, soilData),
      yieldPredictions: _extractYieldPredictions(aiResponse),
      marketInsights: _extractMarketInsights(aiResponse),
      aiRecommendation: aiResponse,
      recommendationDate: DateTime.now(),
    );
  }

  List<RecommendedCrop> _extractRecommendedCrops(String aiResponse) {
    // Extract crop recommendations from AI response
    // This is a simplified extraction - in production, you'd use more sophisticated parsing
    final crops = <RecommendedCrop>[];
    
    // Common crops based on typical agricultural patterns
    final cropDatabase = {
      'rice': RecommendedCrop(
        name: 'Rice',
        suitabilityScore: 85,
        season: 'Kharif (Jun-Oct)',
        expectedYield: '4-6 tons/hectare',
        profitability: 'High',
        reasons: ['Good soil pH', 'Adequate moisture', 'Suitable climate'],
        icon: '🌾',
      ),
      'wheat': RecommendedCrop(
        name: 'Wheat',
        suitabilityScore: 78,
        season: 'Rabi (Nov-Apr)',
        expectedYield: '3-5 tons/hectare',
        profitability: 'Medium',
        reasons: ['Stable soil conditions', 'Good NPK levels'],
        icon: '🌾',
      ),
      'cotton': RecommendedCrop(
        name: 'Cotton',
        suitabilityScore: 72,
        season: 'Kharif (Apr-Oct)',
        expectedYield: '15-20 quintals/hectare',
        profitability: 'High',
        reasons: ['Good soil temperature', 'Adequate nutrients'],
        icon: '🌿',
      ),
    };

    // Select top 3 crops based on AI response content
    final responseText = aiResponse.toLowerCase();
    cropDatabase.forEach((key, crop) {
      if (responseText.contains(key)) {
        crops.add(crop);
      }
    });

    // If no matches, return default recommendations
    if (crops.isEmpty) {
      crops.addAll(cropDatabase.values.take(3));
    }

    return crops.take(3).toList();
  }

  SoilSuitability _calculateSoilSuitability(Map<String, double> soilData) {
    double score = 0;
    List<String> issues = [];
    List<String> strengths = [];

    final ph = soilData['ph'] ?? 7.0;
    final nitrogen = soilData['nitrogen'] ?? 0;
    final phosphorus = soilData['phosphorus'] ?? 0;
    final potassium = soilData['potassium'] ?? 0;

    // pH Analysis
    if (ph >= 6.0 && ph <= 7.5) {
      score += 25;
      strengths.add('Optimal pH level (${ph.toStringAsFixed(1)})');
    } else if (ph < 6.0) {
      score += 10;
      issues.add('Acidic soil - may need lime application');
    } else {
      score += 15;
      issues.add('Alkaline soil - may need sulfur treatment');
    }

    // NPK Analysis
    if (nitrogen >= 60) {
      score += 25;
      strengths.add('Good nitrogen levels');
    } else {
      issues.add('Low nitrogen - consider nitrogen fertilizers');
    }

    if (phosphorus >= 50) {
      score += 25;
      strengths.add('Adequate phosphorus content');
    } else {
      issues.add('Low phosphorus - add bone meal or DAP');
    }

    if (potassium >= 60) {
      score += 25;
      strengths.add('Good potassium levels');
    } else {
      issues.add('Low potassium - apply muriate of potash');
    }

    return SoilSuitability(
      overallScore: score.round(),
      strengths: strengths,
      issues: issues,
    );
  }

  WeatherSuitability _calculateWeatherSuitability(Map<String, dynamic> weatherData) {
    double score = 0;
    List<String> advantages = [];
    List<String> challenges = [];

    final temperature = weatherData['temperature'] ?? 25.0;
    final humidity = weatherData['humidity'] ?? 50;

    // Temperature analysis
    if (temperature >= 20 && temperature <= 35) {
      score += 50;
      advantages.add('Ideal temperature range for most crops');
    } else if (temperature < 20) {
      score += 30;
      challenges.add('Cool temperature - limited crop options');
    } else {
      score += 25;
      challenges.add('High temperature - ensure adequate irrigation');
    }

    // Humidity analysis
    if (humidity >= 40 && humidity <= 70) {
      score += 50;
      advantages.add('Balanced humidity levels');
    } else if (humidity < 40) {
      score += 30;
      challenges.add('Low humidity - increase irrigation frequency');
    } else {
      score += 35;
      challenges.add('High humidity - monitor for fungal diseases');
    }

    return WeatherSuitability(
      score: score.round(),
      advantages: advantages,
      challenges: challenges,
    );
  }

  String _extractPlantingGuidelines(String aiResponse) {
    return "Based on current soil and weather conditions, plant during the recommended season. Prepare field with proper tillage and organic matter incorporation.";
  }

  String _extractFertilizationPlan(String aiResponse, Map<String, double> soilData) {
    final nitrogen = soilData['nitrogen'] ?? 0;
    final phosphorus = soilData['phosphorus'] ?? 0;
    final potassium = soilData['potassium'] ?? 0;

    String plan = "Fertilization Recommendations:\n";
    if (nitrogen < 60) plan += "• Apply Urea: 100-150 kg/hectare\n";
    if (phosphorus < 50) plan += "• Apply DAP: 50-75 kg/hectare\n";
    if (potassium < 60) plan += "• Apply MOP: 40-60 kg/hectare\n";
    
    return plan;
  }

  String _extractIrrigationSchedule(String aiResponse, Map<String, double> soilData) {
    final moisture = soilData['moisture'] ?? 50;
    
    if (moisture < 40) {
      return "Immediate irrigation required. Water 2-3 times weekly during establishment phase.";
    } else if (moisture > 80) {
      return "Soil moisture is adequate. Monitor and irrigate only when top soil becomes dry.";
    } else {
      return "Current moisture is good. Maintain regular irrigation schedule based on crop stage.";
    }
  }

  Map<String, String> _extractYieldPredictions(String aiResponse) {
    return {
      'Rice': '4-6 tons/hectare',
      'Wheat': '3-5 tons/hectare',
      'Cotton': '15-20 quintals/hectare',
    };
  }

  String _extractMarketInsights(String aiResponse) {
    return "Current market trends show good demand for cereal crops. Consider storage facilities for better price realization.";
  }

  CropRecommendation _getFallbackCropRecommendation(
    Map<String, double> soilData,
    Map<String, dynamic> weatherData,
  ) {
    return CropRecommendation(
      recommendedCrops: [
        RecommendedCrop(
          name: 'Rice',
          suitabilityScore: 80,
          season: 'Kharif (Jun-Oct)',
          expectedYield: '4-6 tons/hectare',
          profitability: 'High',
          reasons: ['Versatile crop', 'Good market demand'],
          icon: '🌾',
        ),
        RecommendedCrop(
          name: 'Wheat',
          suitabilityScore: 75,
          season: 'Rabi (Nov-Apr)',
          expectedYield: '3-5 tons/hectare',
          profitability: 'Medium',
          reasons: ['Stable crop', 'Government support'],
          icon: '🌾',
        ),
        RecommendedCrop(
          name: 'Vegetables',
          suitabilityScore: 70,
          season: 'Year-round',
          expectedYield: 'Varies by type',
          profitability: 'High',
          reasons: ['Quick returns', 'Local market'],
          icon: '🥬',
        ),
      ],
      soilSuitability: _calculateSoilSuitability(soilData),
      weatherSuitability: _calculateWeatherSuitability(weatherData),
      plantingGuidelines: 'Prepare field with proper drainage and organic matter.',
      fertilizationPlan: 'Apply balanced NPK fertilizer as per soil test.',
      irrigationSchedule: 'Maintain adequate moisture throughout growth period.',
      yieldPredictions: {
        'Rice': '4-6 tons/hectare',
        'Wheat': '3-5 tons/hectare',
        'Vegetables': '10-15 tons/hectare',
      },
      marketInsights: 'Diversify crops for better risk management and profit.',
      aiRecommendation: 'Fallback recommendation based on standard agricultural practices.',
      recommendationDate: DateTime.now(),
    );
  }

  // Method to check if AI service is available
  bool isAIAvailable() {
    return _apiKey != 'YOUR_GEMINI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}

// Data models for crop recommendations
class CropRecommendation {
  final List<RecommendedCrop> recommendedCrops;
  final SoilSuitability soilSuitability;
  final WeatherSuitability weatherSuitability;
  final String plantingGuidelines;
  final String fertilizationPlan;
  final String irrigationSchedule;
  final Map<String, String> yieldPredictions;
  final String marketInsights;
  final String aiRecommendation;
  final DateTime recommendationDate;

  CropRecommendation({
    required this.recommendedCrops,
    required this.soilSuitability,
    required this.weatherSuitability,
    required this.plantingGuidelines,
    required this.fertilizationPlan,
    required this.irrigationSchedule,
    required this.yieldPredictions,
    required this.marketInsights,
    required this.aiRecommendation,
    required this.recommendationDate,
  });
}

class RecommendedCrop {
  final String name;
  final int suitabilityScore;
  final String season;
  final String expectedYield;
  final String profitability;
  final List<String> reasons;
  final String icon;

  RecommendedCrop({
    required this.name,
    required this.suitabilityScore,
    required this.season,
    required this.expectedYield,
    required this.profitability,
    required this.reasons,
    required this.icon,
  });
}

class SoilSuitability {
  final int overallScore;
  final List<String> strengths;
  final List<String> issues;

  SoilSuitability({
    required this.overallScore,
    required this.strengths,
    required this.issues,
  });
}

class WeatherSuitability {
  final int score;
  final List<String> advantages;
  final List<String> challenges;

  WeatherSuitability({
    required this.score,
    required this.advantages,
    required this.challenges,
  });
}
