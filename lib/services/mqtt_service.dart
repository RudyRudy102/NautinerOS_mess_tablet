import 'dart:async';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  String _broker = '192.168.68.65';
  int _port = 1883;
  String _username = 'mqtt';
  String _password = 'mqtt';

  // Konfigurowalne tematy MQTT dla każdej lampy
  String cabinLightTopic = 'home/livingroom/light';
  String nightLightTopic = 'home/bedroom/light';
  String ambientLightTopic = 'home/ambient/light';
  String button4Topic = 'home/button4/light';
  String button5Topic = 'home/button5/light';
  String button6Topic = 'home/button6/light';

  String get host => _broker;
  int get port => _port;
  String get username => _username;
  String get password => _password;

  void updateHost(String newHost) {
    _broker = newHost;
    // Rozłącz obecne połączenie
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
    }
  }

  void updatePort(int newPort) {
    _port = newPort;
    // Rozłącz obecne połączenie
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
    }
  }

  void updateCredentials(String username, String password) {
    _username = username;
    _password = password;
    // Rozłącz obecne połączenie
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
    }
  }

  void updateTopics({
    String? cabinLight,
    String? nightLight,
    String? ambientLight,
    String? button4,
    String? button5,
    String? button6,
  }) {
    if (cabinLight != null) cabinLightTopic = cabinLight;
    if (nightLight != null) nightLightTopic = nightLight;
    if (ambientLight != null) ambientLightTopic = ambientLight;
    if (button4 != null) button4Topic = button4;
    if (button5 != null) button5Topic = button5;
    if (button6 != null) button6Topic = button6;
  }

  // Generowanie losowego identyfikatora klienta
  String _generateRandomClientId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(10, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Inicjalizacja klienta odkłada się do momentu connect()
  late MqttServerClient client;
  final _stateController = StreamController<Map<String, bool>>.broadcast();
  bool _isConnecting = false;

  Stream<Map<String, bool>> get stateStream => _stateController.stream;

  // Dodaj mapę callbacków
  final Map<String, Function(String, String)> _topicCallbacks = {};

  Future<bool> connect() async {
    if (_isConnecting) {
      print('Already attempting to connect to MQTT broker');
      return false;
    }

    _isConnecting = true;

    // Tworzenie nowego klienta z losowym identyfikatorem przy każdym połączeniu
    final clientId = _generateRandomClientId();
    client = MqttServerClient(_broker, clientId);
    print('Connecting with client ID: $clientId');

    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.pongCallback = _pong;
    client.port = _port;

    // Zwiększenie timeoutu połączenia
    client.connectTimeoutPeriod = 10000; // 10 sekund

    // Konfiguracja komunikatu połączenia
    final connMessage = MqttConnectMessage()
        .withWillQos(MqttQos.atLeastOnce)
        .withClientIdentifier(clientId) // Ustawienie wygenerowanego ID
        .startClean() // Rozpocznij czyste połączenie
        .authenticateAs(_username, _password);

    client.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker at $_broker:$_port...');
      await client.connect();

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('Connected to MQTT broker successfully');

        // Subscribe to light state topics after connection
        client.subscribe('$cabinLightTopic/state', MqttQos.atLeastOnce);
        client.subscribe('$nightLightTopic/state', MqttQos.atLeastOnce);
        client.subscribe('$ambientLightTopic/state', MqttQos.atLeastOnce);
        client.subscribe('$button4Topic/state', MqttQos.atLeastOnce);
        client.subscribe('$button5Topic/state', MqttQos.atLeastOnce);
        client.subscribe('$button6Topic/state', MqttQos.atLeastOnce);
        print('Subscribed to light state topics');

        // Listen to updates
        client.updates
            ?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
          _onMessageReceived(messages);
        });

        _isConnecting = false;
        return true;
      } else {
        print(
            'Failed to connect to MQTT broker: ${client.connectionStatus!.state}, reason: ${client.connectionStatus!.returnCode}');
        client.disconnect();
        _isConnecting = false;
        return false;
      }
    } catch (e) {
      print('Exception during MQTT connection: $e');
      _isConnecting = false;
      return false;
    }
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    final MqttPublishMessage message =
        messages[0].payload as MqttPublishMessage;
    final String topic = messages[0].topic;
    final String payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

    print('Received message from topic: $topic with payload: $payload');

    // Sprawdź czy mamy callback dla tego tematu
    if (_topicCallbacks.containsKey(topic)) {
      _topicCallbacks[topic]!(topic, payload);
    }

    // Identify which light is updated
    String? lightType;
    if (topic.startsWith(cabinLightTopic)) {
      lightType = 'cabinLight';
    } else if (topic.startsWith(nightLightTopic)) {
      lightType = 'nightLight';
    } else if (topic.startsWith(ambientLightTopic)) {
      lightType = 'ambientLight';
    } else if (topic.startsWith(button4Topic)) {
      lightType = 'button4';
    } else if (topic.startsWith(button5Topic)) {
      lightType = 'button5';
    } else if (topic.startsWith(button6Topic)) {
      lightType = 'button6';
    }

    if (lightType != null && topic.endsWith('/state')) {
      final state = payload == '1';
      print('Updating $lightType state to $state');
      _stateController.add({lightType: state});
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void _pong() {
    print('Ping response received');
  }

  Future<bool> sendCommand(int deviceId, int state) async {
    if (client.connectionStatus == null ||
        client.connectionStatus!.state != MqttConnectionState.connected) {
      print('MQTT not connected. Attempting to reconnect...');
      final connected = await connect();
      if (!connected) {
        print('Failed to reconnect to MQTT broker');
        return false;
      }
    }

    String topic;
    switch (deviceId) {
      case 1:
        topic = '$cabinLightTopic/set';
        break;
      case 2:
        topic = '$nightLightTopic/set';
        break;
      case 3:
        topic = '$ambientLightTopic/set';
        break;
      case 4:
        topic = '$button4Topic/set';
        break;
      case 5:
        topic = '$button5Topic/set';
        break;
      case 6:
        topic = '$button6Topic/set';
        break;
      default:
        print('Invalid device ID: $deviceId');
        return false;
    }

    if (state != 1 && state != 0) {
      print('Invalid state: $state. Only 1 or 0 are allowed.');
      return false;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(state.toString());

      print('Sending MQTT command to $topic: $state');

      // Użycie QoS 1 (at least once) dla pewności dostarczenia
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!,
          retain: true // Zachowaj ostatnią wartość
          );

      // Oczekiwanie na potwierdzenie wysłania
      await Future.delayed(const Duration(milliseconds: 500));

      // Sprawdzenie czy wiadomość została dostarczona
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        print('Lost connection to MQTT broker after sending command');
        return false;
      }

      print('Command sent successfully to $topic: $state');
      return true;
    } catch (e) {
      print('Error sending command to topic $topic: $e');
      return false;
    }
  }

  // Dodaj metodę do subskrybowania tematów z callback
  void subscribeToTopic(
      String topic, Function(String topic, String message) callback) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe(topic, MqttQos.atLeastOnce);

      // Jeśli to nowy temat, ustaw callback
      _topicCallbacks[topic] = callback;
    }
  }

  void unsubscribeFromTopic(String topic) {
    try {
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('Unsubscribing from topic: $topic');
        client.unsubscribe(topic);
        _topicCallbacks.remove(topic);
      }
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  void dispose() {
    try {
      _stateController.close();
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        client.disconnect();
      }
    } catch (e) {
      print('Error disposing MQTT service: $e');
    }
  }
}
