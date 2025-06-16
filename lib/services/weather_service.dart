import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey =
      '4d8fb5b93d4af21d66a2948710284366'; // Przykładowy klucz API
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Zmienna przechowująca ostatnią pozycję (cache)
  static Position? _lastKnownPosition;

  // Metoda do sprawdzania i żądania uprawnień lokalizacji
  static Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Sprawdź czy usługi lokalizacji są włączone
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Usługi lokalizacji są wyłączone.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Uprawnienia lokalizacji zostały odrzucone');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
          'Uprawnienia lokalizacji zostały trwale odrzucone, nie można żądać uprawnień.');
      return false;
    }

    return true;
  }

  // Metoda do pobierania aktualnej pozycji
  static Future<Position?> _getCurrentPosition() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        return _lastKnownPosition; // Zwróć ostatnią znaną pozycję jeśli brak uprawnień
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy
            .low, // Niższa dokładność dla szybszego uzyskania pozycji
        timeLimit: const Duration(seconds: 10), // Timeout po 10 sekundach
      );

      _lastKnownPosition = position; // Zapisz jako cache
      return position;
    } catch (e) {
      print('Błąd podczas pobierania pozycji: $e');
      return _lastKnownPosition; // Zwróć ostatnią znaną pozycję w przypadku błędu
    }
  }

  // Metoda do pobierania danych pogodowych na podstawie lokalizacji urządzenia
  static Future<WeatherModel> getWeatherData({
    double? waterTemperature,
  }) async {
    Position? position = await _getCurrentPosition();

    Uri url;

    if (position != null) {
      // Użyj współrzędnych GPS
      url = Uri.parse(
          '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey&lang=pl');
      print(
          'Pobieranie pogody dla współrzędnych: ${position.latitude}, ${position.longitude}');
    } else {
      // Fallback do Warszawy jeśli nie można uzyskać lokalizacji
      url = Uri.parse(
          '$_baseUrl/weather?q=Warsaw,pl&units=metric&appid=$_apiKey&lang=pl');
      print('Pobieranie pogody dla lokalizacji domyślnej: Warszawa');
    }

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherModel.fromJson(data, waterTemperature: waterTemperature);
      } else {
        throw Exception(
            'Błąd pobierania danych pogodowych: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd połączenia: $e');
    }
  }
}
