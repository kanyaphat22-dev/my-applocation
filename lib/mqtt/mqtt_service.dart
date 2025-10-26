import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient client;

  // 🧩 ข้อมูล HiveMQ Cloud ของคุณ (แก้ตรงนี้ให้ตรงจริง)
  final String broker = '320fab5f88aa45e1992872353264e8fa.s1.eu.hivemq.cloud'; // ✅ เอา "<" และ ">" ออก
  final int port = 8883; // ✅ SSL Port
  final String topic = 'mqtt/location';
  final String username = 'kanyaphat';
  final String password = 'Kanyaphat22';

  Position? _lastPosition;
  StreamSubscription<Position>? _gpsSub;

  // ==============================
  // ✅ เริ่มเชื่อมต่อ HiveMQ Cloud
  // ==============================
  Future<void> connect(String userId) async {
    client = MqttServerClient.withPort(broker, 'flutter_$userId', port);
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    client.onConnected = () => print('✅ Connected to HiveMQ Cloud');
    client.onDisconnected = () => print('❌ Disconnected from HiveMQ Cloud');
    client.onSubscribed = (t) => print('📩 Subscribed to topic: $t');

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client_$userId')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMess;

    try {
      print('🔗 Connecting to $broker:$port ...');
      await client.connect(username, password);
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('📡 HiveMQ Connected Successfully ✅');
        _startLocationStream(userId);
      } else {
        print('⚠️ HiveMQ Connection failed: ${client.connectionStatus}');
      }
    } catch (e) {
      print('❌ HiveMQ Error: $e');
      client.disconnect();
    }
  }

  // ==============================================
  // 🚶 ส่งพิกัดเฉพาะเมื่อเคลื่อนไหวเกิน 15 เมตร
  // ==============================================
  void _startLocationStream(String userId) {
    _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (_lastPosition == null) {
        _lastPosition = pos;
        _send(userId, pos);
      } else {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );

        if (distance >= 15) {
          _lastPosition = pos;
          _send(userId, pos);
        } else {
          print('🕸️ Movement <15m (${distance.toStringAsFixed(1)}m) — skip');
        }
      }
    });
  }

  // ==========================
  // 📤 ส่งข้อมูลไปยัง HiveMQ
  // ==========================
  void _send(String userId, Position pos) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('⚠️ MQTT not connected, skipping send');
      return;
    }

    final payload = jsonEncode({
      'user_id': userId,
      'lat': pos.latitude,
      'lon': pos.longitude,
      'acc': pos.accuracy,
      'time': DateTime.now().toIso8601String(),
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    try {
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 Sent to MQTT: $payload');
    } catch (e) {
      print('❌ Publish error: $e');
    }
  }

  void disconnect() {
    _gpsSub?.cancel();
    client.disconnect();
    print('🛑 MQTT disconnected');
  }
}
