import 'package:flutter/material.dart';

class WeatherModel {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconCode;
  final DateTime timestamp;
  final int pressure; // Dodane ciśnienie atmosferyczne
  final double waterTemperature; // Dodana temperatura wody

  WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.timestamp,
    required this.pressure,
    required this.waterTemperature,
  });

  // Metoda do konwersji z JSON
  factory WeatherModel.fromJson(Map<String, dynamic> json,
      {double? waterTemperature}) {
    return WeatherModel(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      iconCode: json['weather'][0]['icon'] as String,
      timestamp: DateTime.now(),
      pressure: json['main']['pressure'] as int, // Dodane ciśnienie
      waterTemperature:
          waterTemperature ?? 15.0, // Użyj przekazanej wartości lub domyślną
    );
  }

  // Metoda do pobierania ikony na podstawie kodu
  IconData getWeatherIcon() {
    // Kody ikon z API OpenWeatherMap
    switch (iconCode.substring(0, 2)) {
      case '01': // Czyste niebo
        return Icons.wb_sunny_rounded;
      case '02': // Lekkie zachmurzenie
        return Icons.cloud_circle_rounded;
      case '03': // Rozproszone chmury
      case '04': // Zachmurzenie
        return Icons.cloud_rounded;
      case '09': // Przelotny deszcz
        return Icons.grain_rounded;
      case '10': // Deszcz
        return Icons.umbrella;
      case '11': // Burza
        return Icons.flash_on_rounded;
      case '13': // Śnieg
        return Icons.ac_unit_rounded;
      case '50': // Mgła
        return Icons.cloud_queue_rounded;
      default:
        return Icons.wb_sunny;
    }
  }

  // Metoda do pobierania koloru ikony
  Color getIconColor() {
    switch (iconCode.substring(0, 2)) {
      case '01': // Czyste niebo
        return Colors.yellow;
      case '02': // Lekkie zachmurzenie
      case '03': // Rozproszone chmury
      case '04': // Zachmurzenie
        return Colors.grey;
      case '09': // Przelotny deszcz
      case '10': // Deszcz
        return Colors.lightBlue;
      case '11': // Burza
        return Colors.deepPurple;
      case '13': // Śnieg
        return Colors.white;
      case '50': // Mgła
        return Colors.blueGrey;
      default:
        return Colors.yellow;
    }
  }

  // Metoda do konwersji prędkości wiatru na km/h
  String getWindSpeedInKmh() {
    // W API OpenWeatherMap prędkość wiatru jest w m/s
    return (windSpeed * 3.6).toStringAsFixed(1); // konwersja na km/h
  }

  // Nowa metoda do konwersji prędkości wiatru na skalę Beauforta
  String getWindSpeedInBft() {
    // Konwersja z m/s na bft
    int bft;
    if (windSpeed < 0.3)
      bft = 0;
    else if (windSpeed < 1.6)
      bft = 1;
    else if (windSpeed < 3.4)
      bft = 2;
    else if (windSpeed < 5.5)
      bft = 3;
    else if (windSpeed < 8.0)
      bft = 4;
    else if (windSpeed < 10.8)
      bft = 5;
    else if (windSpeed < 13.9)
      bft = 6;
    else if (windSpeed < 17.2)
      bft = 7;
    else if (windSpeed < 20.8)
      bft = 8;
    else if (windSpeed < 24.5)
      bft = 9;
    else if (windSpeed < 28.5)
      bft = 10;
    else if (windSpeed < 32.7)
      bft = 11;
    else
      bft = 12;

    return '$bft B';
  }
}
