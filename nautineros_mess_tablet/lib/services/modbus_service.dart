import 'dart:async';

class ModbusService {
  static const String defaultHost = '192.168.68.72';
  static const int defaultUnitId = 0x2; // Unit ID 16#2 (hex: 0x2)
  static const int defaultPort = 502; // Standardowy port Modbus TCP

  // Adresy coil dla różnych lampek
  static const int cabinLightCoil = 28;
  static const int nightLightCoil = 29;
  static const int ambientLightCoil = 30;

  final String host;
  final int unitId;
  final int port;

  bool _isConnected = false;
  final StreamController<Map<String, bool>> _stateStreamController =
      StreamController<Map<String, bool>>.broadcast();

  Timer? _refreshTimer;

  // Stan lampek (symulowane)
  bool _cabinLightState = false;
  bool _nightLightState = false;
  bool _ambientLightState = false;

  // Dodanie stanu połączenia z Volumio
  bool _volumioConnected = false;

  ModbusService({
    this.host = defaultHost,
    this.unitId = defaultUnitId,
    this.port = defaultPort,
  });

  Stream<Map<String, bool>> get stateStream => _stateStreamController.stream;

  // Gettery dla stanu lampek
  bool get cabinLightState => _cabinLightState;
  bool get nightLightState => _nightLightState;
  bool get ambientLightState => _ambientLightState;

  // Getter dla stanu połączenia Volumio
  bool get isVolumioConnected => _volumioConnected;

  // Symulowane połączenie
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // Symulacja połączenia
      await Future.delayed(const Duration(milliseconds: 500));
      _isConnected = true;

      print('Simulated connection to device at $host:$port, Unit ID: $unitId');

      // Rozpocznij cykliczne odświeżanie stanu
      _startRefreshTimer();
    } catch (e) {
      print('Simulated connection error: $e');
      _isConnected = false;
      rethrow;
    }
  }

  // Zamknięcie połączenia
  Future<void> disconnect() async {
    _stopRefreshTimer();
    _isConnected = false;
    print('Simulated disconnection from device');
  }

  // Rozpoczęcie timera odświeżającego stan
  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      refreshState();
    });
  }

  // Zatrzymanie timera
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Odświeżenie stanu wszystkich lampek (symulowane)
  Future<void> refreshState() async {
    if (!_isConnected) {
      try {
        await connect();
      } catch (e) {
        print('Failed to reconnect: $e');
        return;
      }
    }

    // Emisja obecnego stanu wraz ze stanem połączenia Volumio
    _stateStreamController.add({
      'cabinLight': _cabinLightState,
      'nightLight': _nightLightState,
      'ambientLight': _ambientLightState,
      'volumioConnected': _volumioConnected, // Dodanie stanu Volumio
    });
  }

  // Ustawienie stanu oświetlenia kabiny
  Future<bool> setCabinLight(bool state) async {
    _cabinLightState = state;
    await refreshState();
    return true;
  }

  // Ustawienie stanu lampki nocnej
  Future<bool> setNightLight(bool state) async {
    _nightLightState = state;
    await refreshState();
    return true;
  }

  // Ustawienie stanu oświetlenia ambiente
  Future<bool> setAmbientLight(bool state) async {
    _ambientLightState = state;
    await refreshState();
    return true;
  }

  // Metoda do ustawienia stanu połączenia Volumio
  void setVolumioConnectionState(bool connected) {
    _volumioConnected = connected;
    // Emisja obecnego stanu zawierającego również stan Volumio
    refreshState();
  }

  // Zwolnienie zasobów
  void dispose() {
    _stopRefreshTimer();
    disconnect();
    _stateStreamController.close();
  }
}
