import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class WLEDService {
  final String host;
  final int port;
  final String apiPath;

  WLEDService({
    this.host = '192.168.4.1', // Domyślny host WLED
    this.port = 80, // Domyślny port HTTP
    this.apiPath = '/json',
  });

  // Pobranie aktualnego stanu WLED
  Future<Map<String, dynamic>> getState() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://$host:$port$apiPath/state'),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Błąd pobierania stanu WLED: ${response.statusCode}');
      }
    } catch (e) {
      print('Błąd komunikacji z WLED: $e');
      throw Exception('Błąd komunikacji z WLED: $e');
    }
  }

  // Ustawienie koloru RGB
  Future<bool> setColor(Color color,
      {int? segment, int brightness = 255}) async {
    try {
      // Przygotowanie danych JSON
      final Map<String, dynamic> data = {
        'on': true,
        'bri': brightness,
        'seg': [
          {
            'id': segment ?? 0,
            'col': [
              [color.red, color.green, color.blue]
            ],
          }
        ],
      };

      final response = await http
          .post(
            Uri.parse('http://$host:$port$apiPath/state'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print('Błąd ustawiania koloru WLED: $e');
      return false;
    }
  }

  // Ustawienie barwy białego światła (temperatura koloru)
  Future<bool> setWhiteTemperature(int kelvin,
      {int? segment, int brightness = 255}) async {
    try {
      // Konwersja temperatury Kelwina na RGB
      final Color color = _colorTemperatureToRGB(kelvin);

      // Przygotowanie danych JSON
      final Map<String, dynamic> data = {
        'on': true,
        'bri': brightness,
        'seg': [
          {
            'id': segment ?? 0,
            'col': [
              [color.red, color.green, color.blue]
            ],
          }
        ],
      };

      final response = await http
          .post(
            Uri.parse('http://$host:$port$apiPath/state'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print('Błąd ustawiania temperatury barwowej WLED: $e');
      return false;
    }
  }

  // Włączenie/wyłączenie WLED
  Future<bool> setPower(bool on) async {
    try {
      final Map<String, dynamic> data = {'on': on};

      final response = await http
          .post(
            Uri.parse('http://$host:$port$apiPath/state'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print('Błąd włączania/wyłączania WLED: $e');
      return false;
    }
  }

  // Konwersja temperatury koloru na RGB
  Color _colorTemperatureToRGB(int kelvin) {
    // Ograniczenie zakresu temperatury
    kelvin = kelvin.clamp(1000, 40000);

    // Algorytm konwersji temperatury Kelwina na RGB
    double tmpKelvin = kelvin / 100.0;
    int r;
    double g;
    int b;

    // Czerwony
    if (tmpKelvin <= 66) {
      r = 255;
    } else {
      double rTemp = tmpKelvin - 60;
      r = (329.698727446 * pow(rTemp, -0.1332047592)).round();
      r = r.clamp(0, 255);
    }

    // Zielony
    if (tmpKelvin <= 66) {
      g = tmpKelvin;
      g = 99.4708025861 * log(g) - 161.1195681661;
    } else {
      g = tmpKelvin - 60;
      g = 288.1221695283 * pow(g, -0.0755148492);
    }
    g = g.clamp(0, 255);
    int gInt = g.round();
    // Niebieski
    if (tmpKelvin >= 66) {
      b = 255;
    } else if (tmpKelvin <= 19) {
      b = 0;
    } else {
      double bTemp = tmpKelvin - 10;
      b = (138.5177312231 * log(bTemp) - 305.0447927307).round();
      b = b.clamp(0, 255);
    }

    return Color.fromARGB(255, r, gInt, b);
  }

  // Pomocnicza funkcja logarytmu naturalnego
  double log(double x) {
    return math.log(x);
  }

  double pow(double x, double exponent) {
    return math.pow(x, exponent).toDouble();
  }
}
