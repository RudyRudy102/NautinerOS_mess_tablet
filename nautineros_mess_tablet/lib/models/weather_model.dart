import 'package:flutter/material.dart';

class WeatherModel {
  final double temperature;
  final double waterTemperature;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String description;
  final String condition;

  WeatherModel({
    required this.temperature,
    required this.waterTemperature,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.description,
    required this.condition,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['main']['temp'] as num).toDouble(),
      waterTemperature:
          18.3, // Przykładowa wartość, należy dostosować źródło danych
      humidity: json['main']['humidity'] as int,
      pressure: json['main']['pressure'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      condition: json['weather'][0]['main'].toString().toLowerCase(),
    );
  }

  IconData getWeatherIcon() {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      default:
        return Icons.wb_sunny;
    }
  }

  Color getIconColor() {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.yellow;
      case 'cloudy':
        return Colors.grey;
      case 'rain':
        return Colors.blue;
      default:
        return Colors.yellow;
    }
  }

  String getWindSpeedInKmh() {
    return (windSpeed * 3.6).round().toString();
  }

  String getWindSpeedInBft() {
    final double speedKmh = windSpeed * 3.6;
    if (speedKmh < 1) return '0 Bft';
    if (speedKmh < 5) return '1 Bft';
    if (speedKmh < 11) return '2 Bft';
    if (speedKmh < 19) return '3 Bft';
    if (speedKmh < 28) return '4 Bft';
    if (speedKmh < 38) return '5 Bft';
    if (speedKmh < 49) return '6 Bft';
    if (speedKmh < 61) return '7 Bft';
    if (speedKmh < 74) return '8 Bft';
    if (speedKmh < 88) return '9 Bft';
    if (speedKmh < 102) return '10 Bft';
    if (speedKmh < 117) return '11 Bft';
    return '12 Bft';
  }
}
