import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class MyDevice {
  StreamSubscription<ConnectionStateUpdate>? _connection;
  List<Service> services = [];
  StreamSubscription<List<int>>? _readSubscription;
  ValueNotifier<bool> isReadyNotifier = ValueNotifier<bool>(false);

  static const String serviceUUID = '0000fff0-0000-1000-8000-00805f9b34fb';

  static const String notifyCharacteristicUUID =
      '0000fff1-0000-1000-8000-00805f9b34fb';
  static const String calibrateCharacteristicUUID =
      '0000fff2-0000-1000-8000-00805f9b34fb';
  static const String readCharacteristicUUID =
      '0000fff3-0000-1000-8000-00805f9b34fb';

  dynamic _notifyCharacteristic;
  dynamic _calibrateCharacteristic;
  dynamic _readCharacteristic;

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
    _calibrateCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(calibrateCharacteristicUUID),
        serviceId: Uuid.parse(serviceUUID),
        deviceId: targetDevice.id);
    _notifyCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(notifyCharacteristicUUID),
        serviceId: Uuid.parse(serviceUUID),
        deviceId: targetDevice.id);
    _readCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(readCharacteristicUUID),
        serviceId: Uuid.parse(serviceUUID),
        deviceId: targetDevice.id);
    isReadyNotifier.value = true;
  }

  Future<void> beginCalibration() async {
    await _ble.writeCharacteristicWithoutResponse(
      _calibrateCharacteristic,
      value: [0x01],
    );
  }

  Future<void> endCalibration() async {
    await _ble.writeCharacteristicWithoutResponse(
      _calibrateCharacteristic,
      value: [0x00],
    );
  }

  Future<void> enableNotifications() async {
    await _ble.writeCharacteristicWithoutResponse(
      _notifyCharacteristic,
      value: [0x01],
    );
  }

  Future<void> disableNotifications() async {
    await _ble.writeCharacteristicWithoutResponse(
      _notifyCharacteristic,
      value: [0x00],
    );
  }

  Future<void> beginReading() async {
    _readSubscription =
        _ble.subscribeToCharacteristic(_readCharacteristic).listen((data) {
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
