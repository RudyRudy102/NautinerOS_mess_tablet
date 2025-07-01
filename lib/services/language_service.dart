import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translations.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static String _currentLanguage = 'pl';
  static final _languageController = StreamController<String>.broadcast();

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'tanks': 'Tanks',
      'clean_water': 'Clean water',
      'grey_water': 'Grey water',
      'black_water': 'Black water',
      'fuel': 'Fuel',
      'tank_topics': 'Tank Topics',
      'clean_water_topic': 'Clean water topic',
      'grey_water_topic': 'Grey water topic',
      'black_water_topic': 'Black water topic',
      'fuel_topic': 'Fuel topic',
      'system_settings': 'System Settings',
      'auto_startup': 'Auto Startup',
      'kiosk_mode': 'Kiosk Mode',
      'auto_startup_enabled': 'Auto-start enabled',
      'auto_startup_disabled': 'Auto-start disabled',
      'kiosk_mode_enabled': 'Kiosk mode enabled',
      'kiosk_mode_disabled': 'Kiosk mode disabled',
    },
    'pl': {
      'tanks': 'Zbiorniki',
      'clean_water': 'Woda czysta',
      'grey_water': 'Woda szara',
      'black_water': 'Fekalia',
      'fuel': 'Paliwo',
      'tank_topics': 'Tematy zbiorników',
      'clean_water_topic': 'Temat wody czystej',
      'grey_water_topic': 'Temat wody szarej',
      'black_water_topic': 'Temat fekaliów',
      'fuel_topic': 'Temat paliwa',
      'system_settings': 'Ustawienia systemu',
      'auto_startup': 'Automatyczne uruchamianie',
      'kiosk_mode': 'Tryb kiosk',
      'auto_startup_enabled': 'Auto-start włączony',
      'auto_startup_disabled': 'Auto-start wyłączony',
      'kiosk_mode_enabled': 'Tryb kiosk włączony',
      'kiosk_mode_disabled': 'Tryb kiosk wyłączony',
    },
  };

  static Stream<String> get languageStream => _languageController.stream;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'pl';
    _languageController.add(_currentLanguage);
  }

  static Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    _languageController.add(languageCode);
  }

  static String get currentLanguage => _currentLanguage;

  static String translate(String key) {
    if (Translations.translations.containsKey(_currentLanguage) &&
        Translations.translations[_currentLanguage]!.containsKey(key)) {
      return Translations.translations[_currentLanguage]![key]!;
    }

    if (Translations.translations['en']!.containsKey(key)) {
      return Translations.translations['en']![key]!;
    }

    return key;
  }

  static void dispose() {
    _languageController.close();
  }
}
