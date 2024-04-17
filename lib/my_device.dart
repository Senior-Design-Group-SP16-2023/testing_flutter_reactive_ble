import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class MyDevice {
  StreamSubscription<ConnectionStateUpdate>? _connection;
  List<Service> services = [];
  StreamSubscription<List<int>>? _readSubscription;
  ValueNotifier<bool> isReadyNotifier = ValueNotifier<bool>(false);

  List<int> X = [];
  List<int> Y = [];
  List<int> Z = [];
  List<int> time = [];

  static const String sensorServiceUUID =
      '7147ac18-c824-438e-8506-60829fbd96a3';

  static const String sensorDataUUID = 'bd148149-4469-479a-856f-497ea5e785e5';

  static const String sensorConfigUUID = '95f61667-ffd9-7d9e-fe41-9aed7794ef2f';

  //6 bytes gyro, 6 bytes accel, 4 bytes timestamp 32 bit int

  dynamic _dataCharacteristic;
  dynamic _configCharacteristic;

  final FlutterReactiveBle _ble;
  DiscoveredDevice targetDevice;

  MyDevice(this._ble, this.targetDevice);

  connectToDevice() {
    _connection = _ble
        .connectToDevice(
      id: targetDevice.id,
      connectionTimeout: const Duration(seconds: 2),
    )
        .listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        await Future.delayed(const Duration(seconds: 1));
        getCharacteristics();
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
    //print all the services
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
    // _dataCharacteristic = QualifiedCharacteristic(
    //     characteristicId: Uuid.parse(sensorDataUUID),
    //     serviceId: Uuid.parse(sensorServiceUUID),
    //     deviceId: targetDevice.id);
    // _configCharacteristic = QualifiedCharacteristic(
    //     characteristicId: Uuid.parse(sensorConfigUUID),
    //     serviceId: Uuid.parse(sensorServiceUUID),
    //     deviceId: targetDevice.id);
    isReadyNotifier.value = true;
  }

  Future<void> beginCalibration() async {
    await _configCharacteristic.write([0x01]);
  }

  Future<void> endCalibration() async {
    await _configCharacteristic.write([0x00]);
  }

  //data format
  //x y z are 2 bytes each, time is 4 bytes

  Future<void> beginReading() async {
    _readSubscription = _dataCharacteristic.subscribe().listen((event) {
      if (kDebugMode) {
        //byte string, 16 bytes long, first 2 are x
        //signed int 16
        print(event);


        int gyroX = event[0] + (event[1] << 8);
        int gyroY = event[2] + (event[3] << 8);
        int gyroZ = event[4] + (event[5] << 8);
        int accelX = event[6] + (event[7] << 8);
        int accelY = event[8] + (event[9] << 8);
        int accelZ = event[10] + (event[11] << 8);
        int timestamp = event[12] + (event[13] << 8) + (event[14] << 16) + (event[15] << 24);
        print('gyroX: $gyroX, gyroY: $gyroY, gyroZ: $gyroZ, accelX: $accelX, accelY: $accelY, accelZ: $accelZ, timestamp: $timestamp');



      }
    });
  }

  Future<void> endReading() async {
    if (_readSubscription != null) {
      await _readSubscription!.cancel();
      _readSubscription = null;
    }
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
