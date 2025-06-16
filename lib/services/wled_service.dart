import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class WLEDService {
  String _ip;
  String _secondaryIp;
  final int _port;

  WLEDService(
      {required String ip, String secondaryIp = '192.168.1.133', int port = 80})
      : _ip = ip,
        _secondaryIp = secondaryIp,
        _port = port;

  String get ip => _ip;
  String get secondaryIp => _secondaryIp;
  int get port => _port;

  void updateIp(String newIp) {
    _ip = newIp;
  }

  void updateSecondaryIp(String newIp) {
    _secondaryIp = newIp;
  }

  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.http('$_ip:$_port', '/json/state'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error testing WLED connection: $e');
      return false;
    }
  }

  Future<bool> testSecondaryConnection() async {
    if (_secondaryIp.isEmpty) return false;
    try {
      final response =
          await http.get(Uri.http('$_secondaryIp:$_port', '/json/state'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error testing secondary WLED connection: $e');
      return false;
    }
  }

  Future<void> setPower(bool on) async {
    final Map<String, dynamic> data = {'on': on};

    // Ustaw stan głównego urządzenia WLED
    await _sendCommand(ip: _ip, data: data);

    // Jeśli skonfigurowano drugie urządzenie, ustaw je tak samo
    if (_secondaryIp.isNotEmpty) {
      await _sendCommand(ip: _secondaryIp, data: data);
    }
  }

  Future<void> setColor(Color color, {int? brightness}) async {
    final Map<String, dynamic> data = {
      'on': true,
      'bri': brightness ?? 255,
      'seg': [
        {
          'col': [
            [color.red, color.green, color.blue]
          ]
        }
      ]
    };

    // Ustaw kolor dla głównego urządzenia WLED
    await _sendCommand(ip: _ip, data: data);

    // Jeśli skonfigurowano drugie urządzenie, ustaw je tak samo
    if (_secondaryIp.isNotEmpty) {
      await _sendCommand(ip: _secondaryIp, data: data);
    }
  }

  Future<void> setWhiteTemperature(int kelvin, {int? brightness}) async {
    // Konwersja temperatury Kelvina na wartości RGB
    final rgb = _kelvinToRGB(kelvin);
    final Map<String, dynamic> data = {
      'on': true,
      'bri': brightness ?? 255,
      'seg': [
        {
          'col': [
            [rgb.red, rgb.green, rgb.blue]
          ]
        }
      ]
    };

    // Ustaw temperaturę dla głównego urządzenia WLED
    await _sendCommand(ip: _ip, data: data);

    // Jeśli skonfigurowano drugie urządzenie, ustaw je tak samo
    if (_secondaryIp.isNotEmpty) {
      await _sendCommand(ip: _secondaryIp, data: data);
    }
  }

  Future<void> _sendCommand(
      {required String ip, required Map<String, dynamic> data}) async {
    try {
      await http.post(
        Uri.http('$ip:$_port', '/json/state'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error sending command to WLED at $ip: $e');
    }
  }

  Future<Map<String, dynamic>> getState() async {
    try {
      final response = await http.get(Uri.http('$_ip:$_port', '/json/state'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get WLED state');
    } catch (e) {
      print('Error getting WLED state: $e');
      return {};
    }
  }

  Color _kelvinToRGB(int kelvin) {
    // Implementacja konwersji temperatury barwowej na RGB
    // Uproszczona wersja algorytmu
    double temp = kelvin / 100.0;
    int red, green, blue;

    if (temp <= 66) {
      red = 255;
      green = (99.4708025861 * log(temp) - 161.1195681661).round();
      if (temp <= 19) {
        blue = 0;
      } else {
        blue = (138.5177312231 * log(temp - 10) - 305.0447927307).round();
      }
    } else {
      red = (329.698727446 * pow((temp - 60), -0.1332047592)).round();
      green = (288.1221695283 * pow((temp - 60), -0.0755148492)).round();
      blue = 255;
    }

    return Color.fromARGB(
        255, // Alpha (nieprzezroczystość)
        max(0, min(255, red)),
        max(0, min(255, green)),
        max(0, min(255, blue)));
  }
}
