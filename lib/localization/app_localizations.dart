import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, Map<String, String>> _localizedValues;

  AppLocalizations(this.locale, this._localizedValues);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String getText(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'te', 'ta', 'bn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final Map<String, Map<String, String>> localizedValues = {
      'en': {
        'appTitle': 'SmartAgri Advisor',
        'selectLanguage': 'Select your preferred language',
        'next': 'Next',
        'back': 'Back',
        'skip': 'Skip',
        'getStarted': 'Get Started',
        'changeLanguage': 'Change Language',
        'voiceTutorial': 'Voice Tutorial Available',
        
        // Onboarding screens
        'onboarding1_title': 'Smart Crop Recommendations',
        'onboarding1_desc': 'Get AI-powered suggestions for the best crops based on your soil and climate.',
        'onboarding2_title': 'Real-time Analytics',
        'onboarding2_desc': 'Monitor your farm\'s performance with real-time data and analytics.',
        'onboarding3_title': 'Smart Alerts',
        'onboarding3_desc': 'Get instant notifications about weather changes and crop health.',
      },
      'hi': {
        'appTitle': 'स्मार्टएग्री सलाहकार',
        'selectLanguage': 'अपनी पसंदीदा भाषा चुनें',
        'next': 'अगला',
        'back': 'पीछे',
        'skip': 'छोड़ें',
        'getStarted': 'शुरू करें',
        'changeLanguage': 'भाषा बदलें',
        'voiceTutorial': 'वॉइस ट्यूटोरियल उपलब्ध',
        'onboarding1_title': 'स्मार्ट फसल सिफारिशें',
        'onboarding1_desc': 'अपनी मिट्टी और जलवायु के आधार पर सर्वोत्तम फसलों के लिए एआई-संचालित सुझाव प्राप्त करें।',
        'onboarding2_title': 'रीयल-टाइम विश्लेषण',
        'onboarding2_desc': 'रीयल-टाइम डेटा और विश्लेषण के साथ अपने खेत के प्रदर्शन की निगरानी करें।',
        'onboarding3_title': 'स्मार्ट अलर्ट',
        'onboarding3_desc': 'मौसम परिवर्तन और फसल स्वास्थ्य के बारे में त्वरित सूचनाएं प्राप्त करें।',
      },
      'bn': {
        'appTitle': 'স্মার্টএগ্রি উপদেষ্টা',
        'selectLanguage': 'আপনার পছন্দের ভাষা নির্বাচন করুন',
        'next': 'পরবর্তী',
        'back': 'পিছনে',
        'skip': 'এড়িয়ে যান',
        'getStarted': 'শুরু করুন',
        'changeLanguage': 'ভাষা পরিবর্তন করুন',
        'voiceTutorial': 'ভয়েস টিউটোরিয়াল উপলব্ধ',
        'onboarding1_title': 'স্মার্ট ফসলের সুপারিশ',
        'onboarding1_desc': 'আপনার মাটি এবং জলবায়ু ভিত্তি করে সেরা ফসলের জন্য AI-চালিত পরামর্শ পান।',
        'onboarding2_title': 'রিয়েল-টাইম বিশ্লেষণ',
        'onboarding2_desc': 'রিয়েল-টাইম ডেটা এবং বিশ্লেষণ দিয়ে আপনার খামারের কর্মক্ষমতা নিরীক্ষণ করুন।',
        'onboarding3_title': 'স্মার্ট সতর্কতা',
        'onboarding3_desc': 'আবহাওয়া পরিবর্তন এবং ফসলের স্বাস্থ্য সম্পর্কে তাত্ক্ষণিক বিজ্ঞপ্তি পান।',
      },
      'te': {
        'appTitle': 'స్మార్ట్ అగ్రీ సలహాదారు',
        'selectLanguage': 'మీకు నచ్చిన భాషను ఎంచుకోండి',
        'next': 'తర్వాత',
        'back': 'వెనుకకు',
        'skip': 'దాటవేయి',
        'getStarted': 'ప్రారంభించండి',
        'changeLanguage': 'భాష మార్చు',
        'voiceTutorial': 'వాయిస్ ట్యుటోరియల్ అందుబాటులో ఉంది',
        'onboarding1_title': 'స్మార్ట్ పంట సిఫార్సులు',
        'onboarding1_desc': 'మీ నేల మరియు వాతావరణం ఆధారంగా ఉత్తమ పంటల కోసం AI-ఆధారిత సూచనలను పొందండి.',
        'onboarding2_title': 'రియల్-టైమ్ విశ్లేషణ',
        'onboarding2_desc': 'రియల్-టైమ్ డేటా మరియు విశ్లేషణతో మీ వ్యవసాయ భూమి పనితీరును పర్యవేక్షించండి.',
        'onboarding3_title': 'స్మార్ట్ అలెర్ట్లు',
        'onboarding3_desc': 'వాతావరణ మార్పులు మరియు పంట ఆరోగ్యం గురించి తక్షణ నోటిఫికేషన్లను పొందండి.',
      },
      'ta': {
        'appTitle': 'ஸ்மார்ட் அக்ரி ஆலோசகர்',
        'selectLanguage': 'உங்கள் விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
        'next': 'அடுத்து',
        'back': 'பின்னால்',
        'skip': 'தவிர்க்கவும்',
        'getStarted': 'தொடங்கவும்',
        'changeLanguage': 'மொழியை மாற்றவும்',
        'voiceTutorial': 'குரல் பயிற்சி கிடைக்கிறது',
        'onboarding1_title': 'ஸ்மார்ட் பயிர் பரிந்துரைகள்',
        'onboarding1_desc': 'உங்கள் மண் மற்றும் காலநிலையின் அடிப்படையில் சிறந்த பயிர்களுக்கான AI-இயக்கப்பட்ட பரிந்துரைகளைப் பெறவும்.',
        'onboarding2_title': 'நிகழ் நேர பகுப்பாய்வு',
        'onboarding2_desc': 'நிகழ்நேர தரவு மற்றும் பகுப்பாய்வுகளுடன் உங்கள் பண்ணையின் செயல்திறனை கண்காணிக்கவும்.',
        'onboarding3_title': 'ஸ்மார்ட் அலாரங்கள்',
        'onboarding3_desc': 'வானிலை மாற்றங்கள் மற்றும் பயிர் ஆரோக்கியம் குறித்த உடனடி அறிவிப்புகளைப் பெறவும்.',
      },
    };

    return AppLocalizations(locale, localizedValues);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
