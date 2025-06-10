import 'dart:convert';
import 'package:http/http.dart' as http;

class VolumioService {
  static const String defaultHost =
      '192.168.1.165'; // Domyślny adres IP Volumio, zastąp swoim
  static const int defaultPort = 3000; // Domyślny port Volumio

  String _host;
  final int port;

  VolumioService({
    String host = defaultHost,
    this.port = defaultPort,
  }) : _host = host;

  String get host => _host;

  void updateHost(String newHost) {
    _host = newHost;
  }

  /// Pobiera aktualny stan odtwarzacza
  Future<Map<String, dynamic>> getPlayerState() async {
    try {
      final response = await http
          .get(
            Uri.http('$_host:$port', '/api/v1/getState'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get player state: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting player state: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Ustawia głośność
  Future<Map<String, dynamic>> setVolume(int volume) async {
    try {
      final response = await http
          .get(
            Uri.http('$_host:$port', '/api/v1/commands',
                {'cmd': 'volume', 'volume': volume.toString()}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to set volume: ${response.statusCode}');
      }
    } catch (e) {
      print('Error setting volume: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Play / Pause
  Future<Map<String, dynamic>> togglePlay() async {
    try {
      final state = await getPlayerState();
      final String command = state['status'] == 'play' ? 'pause' : 'play';

      final response = await http
          .get(
            Uri.http('$_host:$port', '/api/v1/commands', {'cmd': command}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to toggle play: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling play: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Przejście do poprzedniego utworu
  Future<Map<String, dynamic>> previous() async {
    try {
      final response = await http
          .get(
            Uri.http('$_host:$port', '/api/v1/commands', {'cmd': 'prev'}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to go to previous track: ${response.statusCode}');
      }
    } catch (e) {
      print('Error going to previous track: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Przejście do następnego utworu
  Future<Map<String, dynamic>> next() async {
    try {
      final response = await http
          .get(
            Uri.http('$_host:$port', '/api/v1/commands', {'cmd': 'next'}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to go to next track: ${response.statusCode}');
      }
    } catch (e) {
      print('Error going to next track: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Pobiera informacje o aktualnie odtwarzanym utworu
  Future<Map<String, dynamic>> getCurrentTrack() async {
    try {
      final state = await getPlayerState();

      // Poprawa obsługi okładki albumu
      String albumart = '';
      if (state.containsKey('albumart')) {
        albumart = state['albumart'] ?? '';
      }

      if (state.containsKey('title') && state.containsKey('artist')) {
        return {
          'title': state['title'] ?? 'Nieznany tytuł',
          'artist': state['artist'] ?? 'Nieznany artysta',
          'album': state['album'] ?? '',
          'albumart': albumart,
          'duration': state['duration'] ?? 0,
          'seek': state['seek'] ?? 0,
          'status': state['status'] ?? 'stop',
          'volume': state['volume'] ?? 0,
        };
      } else {
        return {
          'title': 'Media OFF',
          'artist': '',
          'status': state['status'] ?? 'stop',
          'volume': state['volume'] ?? 0,
          'albumart': albumart,
        };
      }
    } catch (e) {
      print('Error getting current track: $e');
      return {
        'title': 'Błąd pobierania',
        'artist': 'Sprawdź połączenie',
        'status': 'error',
        'volume': 0,
        'albumart': '',
      };
    }
  }
}
