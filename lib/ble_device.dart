import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'package:testing_flutter_reactive_ble/ble_consts.dart';

class BLEDevice {
  StreamSubscription<ConnectionStateUpdate>? _connection;
  List<Service> services = [];
  StreamSubscription<List<int>>? _readSubscription;
  ValueNotifier<bool> isReadyNotifier = ValueNotifier<bool>(false);

  List<int> X = [];
  List<int> Y = [];
  List<int> Z = [];
  List<int> time = [];

  var reconnectCounter = 0;

  dynamic _dataCharacteristic;
  dynamic _configCharacteristic;

  final FlutterReactiveBle _ble;
  final DiscoveredDevice targetDevice;

  BLEDevice(this._ble, this.targetDevice);

  connectToDevice() {
    _connection = _ble
        .connectToDevice(
      id: targetDevice.id,
      connectionTimeout: const Duration(seconds: 2),
    )
        .listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        if(kDebugMode) print('Connected');
        await Future.delayed(const Duration(seconds: 1));
        getCharacteristics();
      }
      if (state.connectionState == DeviceConnectionState.disconnected) {
        isReadyNotifier.value = false;
        if (reconnectCounter < reconnectAttempts) {
          if(kDebugMode) print('Reconnecting...');
          reconnectCounter++;
          connectToDevice();
        }
      }
    }, onError: (e) {
      if (kDebugMode) {
        print(e);
      }
    });
  }

  getCharacteristics() async {
    await _ble.discoverAllServices(targetDevice.id);
    services = await _ble.getDiscoveredServices(targetDevice.id);
    for (var service in services) {
      if (kDebugMode) print(service);
      for (var characteristic in service.characteristics) {
        if (kDebugMode) print(characteristic);
        if (characteristic.id.toString() == sensorDataUUID) {
          _dataCharacteristic = characteristic;
        }
        if (characteristic.id.toString() == sensorConfigUUID) {
          _configCharacteristic = characteristic;
        }
      }
    }
    isReadyNotifier.value =
        _dataCharacteristic != null && _configCharacteristic != null;
  }

  //calibration takes 2.5 seconds on the board...
  Future<void> beginCalibration() async {
    await _configCharacteristic.write([0x01]);
  }

  static const int max = 32767;
  static const int sub = 65536;

  int convert(int data) {
    if (data > max) {
      return data - sub;
    }
    return data;
  }

  Future<void> beginReading() async {
    _readSubscription = _dataCharacteristic.subscribe().listen((event) {
      final correctEvent = [
        event[1],
        event[0],
        event[3],
        event[2],
        event[5],
        event[4],
        event[7],
        event[6],
        event[9],
        event[8],
        event[11],
        event[10],
        event[15],
        event[14],
        event[13],
        event[12]
      ];

      int gyroX = convert(correctEvent[0] << 8 | correctEvent[1]);
      int gyroY = convert(correctEvent[2] << 8 | correctEvent[3]);
      int gyroZ = convert(correctEvent[4] << 8 | correctEvent[5]);
      // int accelX = convert(correctEvent[6] << 8 | correctEvent[7]);
      // int accelY = convert(correctEvent[8] << 8 | correctEvent[9]);
      // int accelZ = convert(correctEvent[10] << 8 | correctEvent[11]);

      int timestamp = correctEvent[15] |
          (correctEvent[14] << 8) |
          (correctEvent[13] << 16) |
          (correctEvent[12] << 24);

      X.add(gyroX);
      Y.add(gyroY);
      Z.add(gyroZ);
      time.add(timestamp);
    });
  }

  Future<void> endReading() async {
    if (_readSubscription != null) {
      await _readSubscription!.cancel();
      _readSubscription = null;
    }
  }

  List<List<int>> getData() {
    return [X, Y, Z, time];
  }

  Future<void> disconnect() async {
    try {
      await _connection?.cancel();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
