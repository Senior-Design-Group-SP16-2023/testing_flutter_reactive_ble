import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class MyDevice {
  StreamSubscription<ConnectionStateUpdate>? _connection;
  List<Service> services = [];
  StreamSubscription<List<int>>? _readSubscription;
  ValueNotifier<bool> isReadyNotifier = ValueNotifier<bool>(false);

  static const String sensorServiceUUID = '0x7147ac18-c824-438e-8506-60829fbd96a3';

  static const String sensorDataUUID = '0xbd148149-4469-479a-856f-497ea5e785e5';

  static const String sensorConfigUUID = '0x95f61667-ffd9-7d9e-fe41-9aed7794ef2f';

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
    _dataCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(sensorDataUUID),
        serviceId: Uuid.parse(sensorServiceUUID),
        deviceId: targetDevice.id);
    _configCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(sensorConfigUUID),
        serviceId: Uuid.parse(sensorServiceUUID),
        deviceId: targetDevice.id);
    isReadyNotifier.value = true;
  }

  Future<void> beginCalibration() async {
    await _ble.writeCharacteristicWithoutResponse(
      _configCharacteristic,
      value: [0x01],
    );
  }

  Future<void> endCalibration() async {
    await _ble.writeCharacteristicWithoutResponse(
      _configCharacteristic,
      value: [0x00],
    );
  }

  Future<void> beginReading() async {
    _readSubscription =
        _ble.subscribeToCharacteristic(_dataCharacteristic).listen((data) {
      if (kDebugMode) {
        print(data);
      }
      if (data.isNotEmpty) {

        //unsure if it is easier to parse data here or elsewhere
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
