import 'package:flutter/material.dart';

class WeatherData {
  final double temperature;
  final double waterTemperature;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String description;
  final String condition;

  WeatherData({
    required this.temperature,
    required this.waterTemperature,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.description,
    required this.condition,
  });

  IconData getWeatherIcon() {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
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
      case 'clouds':
        return Colors.grey;
      case 'rain':
        return Colors.blue;
      default:
        return Colors.yellow;
    }
  }

  String getWindSpeedInKmh() {
    return (windSpeed * 3.6).toStringAsFixed(1);
  }

  String getWindSpeedInBft() {
    double speed = windSpeed;
    if (speed < 0.3) return '0 Bft';
    if (speed < 1.6) return '1 Bft';
    if (speed < 3.4) return '2 Bft';
    if (speed < 5.5) return '3 Bft';
    if (speed < 8.0) return '4 Bft';
    if (speed < 10.8) return '5 Bft';
    if (speed < 13.9) return '6 Bft';
    if (speed < 17.2) return '7 Bft';
    if (speed < 20.8) return '8 Bft';
    if (speed < 24.5) return '9 Bft';
    if (speed < 28.5) return '10 Bft';
    if (speed < 32.7) return '11 Bft';
    return '12 Bft';
  }
}
