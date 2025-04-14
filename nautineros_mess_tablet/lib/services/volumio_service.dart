import 'dart:convert';
import 'package:http/http.dart' as http;

class VolumioService {
  final String host = 'localhost';
  final int port = 3000;

  Future<Map<String, dynamic>> getCurrentTrack() async {
    // Tutaj dodasz później właściwą implementację
    return {
      'title': 'Sample Track',
      'artist': 'Sample Artist',
      'albumart': '',
      'status': 'play',
      'volume': 50,
    };
  }

  Future<void> setVolume(int volume) async {
    final uri = Uri.parse(
      'http://$host:$port/api/v1/commands/?cmd=volume&volume=$volume',
    );
    try {
      await http.get(uri);
    } catch (e) {
      throw Exception('Błąd podczas ustawiania głośności: $e');
    }
  }

  Future<void> togglePlay() async {
    final uri = Uri.parse('http://$host:$port/api/v1/commands/?cmd=toggle');
    try {
      await http.get(uri);
    } catch (e) {
      throw Exception('Błąd podczas przełączania odtwarzania: $e');
    }
  }

  Future<void> next() async {
    final uri = Uri.parse('http://$host:$port/api/v1/commands/?cmd=next');
    try {
      await http.get(uri);
    } catch (e) {
      throw Exception('Błąd podczas przechodzenia do następnego utworu: $e');
    }
  }

  Future<void> previous() async {
    final uri = Uri.parse('http://$host:$port/api/v1/commands/?cmd=prev');
    try {
      await http.get(uri);
    } catch (e) {
      throw Exception('Błąd podczas przechodzenia do poprzedniego utworu: $e');
    }
  }
}
