import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey =
      '4d8fb5b93d4af21d66a2948710284366'; // Przykładowy klucz API
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Metoda do pobierania danych pogodowych dla Warszawy (można dostosować lokalizację)
  static Future<WeatherModel> getWeatherData({
    String city = 'Warsaw',
    String countryCode = 'pl',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/weather?q=$city,$countryCode&units=metric&appid=$_apiKey&lang=pl',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        throw Exception(
          'Błąd pobierania danych pogodowych: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Błąd połączenia: $e');
    }
  }

  static Future<WeatherModel> getMockWeatherData() async {
    // Tutaj dodasz później właściwą implementację pobierania danych
    await Future.delayed(const Duration(seconds: 1)); // Symulacja opóźnienia
    return WeatherModel(
      temperature: 22.5,
      waterTemperature: 18.3,
      humidity: 65,
      pressure: 1013,
      windSpeed: 5.2,
      description: 'Słonecznie',
      condition: 'clear',
    );
  }
}
