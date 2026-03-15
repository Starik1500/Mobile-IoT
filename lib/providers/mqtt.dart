import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MqttProvider with ChangeNotifier {
  MqttServerClient? _client;

  String _electricityValue = "0";
  String _gasValue = "0";
  String _waterValue = "0";
  bool _isConnected = false;

  String get electricityValue => _electricityValue;
  String get gasValue => _gasValue;
  String get waterValue => _waterValue;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    final server = dotenv.env['MQTT_SERVER'] ?? '';
    final user = dotenv.env['MQTT_USER'] ?? '';
    final pass = dotenv.env['MQTT_PASS'] ?? '';

    final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(server, clientId);
    _client!.port = 8883;
    _client!.secure = true;
    _client!.setProtocolV311();
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(user, pass)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      debugPrint('Помилка MQTT: $e');
      _client!.disconnect();
      return;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      _isConnected = true;

      _client!.subscribe('tbw_iot/#', MqttQos.atMostOnce);

      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final recMess = messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final topic = messages[0].topic;

        if (topic == 'tbw_iot/electricity') {
          _electricityValue = payload;
        } else if (topic == 'tbw_iot/gas') {
          _gasValue = payload;
        } else if (topic == 'tbw_iot/water') {
          _waterValue = payload;
        }

        notifyListeners();
      });
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    notifyListeners();
  }

  void disconnect() {
    _client?.disconnect();
  }
}