import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

/**
 * References:
 * https://github.com/JimTompkins/happy_feet_app/blob/d9c497f47d0ca0a1a9cfd205edfe94427a28881a/lib/ble.dart
 */

class BLEService extends ChangeNotifier {
  static FlutterReactiveBle _ble = FlutterReactiveBle();

  bool isReady = false;
  bool serviceDiscoveryComplete = true;
  bool isConnected = false;

  StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  final _devices = <DiscoveredDevice>[];
  DiscoveredDevice? targetDevice;
  List<Service> services = [];
  StreamSubscription<List<int>>? _readSubscription;


  //TODO: use real values for the UUIDs
  //unsure if they will all have the same serviceId... very easy to change if so
  static const String serviceUUID = '0000fff0-0000-1000-8000-00805f9b34fb';

  static const String notifyCharacteristicUUID =
      '0000fff1-0000-1000-8000-00805f9b34fb';
  static const String calibrateCharacteristicUUID =
      '0000fff2-0000-1000-8000-00805f9b34fb';
  static const String readCharacteristicUUID =
      '0000fff3-0000-1000-8000-00805f9b34fb';

  var _notifyCharacteristic;
  var _calibrateCharacteristic;
  var _readCharacteristic;

  String name = '';

  BLEService(this.name) {
    isReady = false;
    isConnected = false;
    notifyListeners();
    _ble.logLevel = LogLevel.verbose;
    _ble.statusStream.listen((status) {
      if (status == BleStatus.ready) {
        isReady = true;
        notifyListeners();
      }
    });
  }

  startScan() {
    disconnect();
    if (!isReady) {
      return;
    }
    _devices.clear();
    _subscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    ).listen(
      (device) {
        if (device.name == name) {
          stopScan();
          targetDevice = device;
          connectToDevice();
        }
      },
      onError: (e) {
        if (kDebugMode) {
          print(e);
        }
      },
      onDone: _onDoneScan(),
    );
  }

  _onDoneScan() {
    stopScan();
  }

  connectToDevice() async {
    if (targetDevice == null) {
      return;
    }
    _connection = _ble
        .connectToDevice(
      id: targetDevice!.id,
      connectionTimeout: Duration(seconds: 2),
    )
        .listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        isConnected = true;
        notifyListeners();
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
    if (targetDevice == null) {
      return;
    }
    await _ble.discoverAllServices(targetDevice!.id);
    services = await _ble.getDiscoveredServices(targetDevice!.id);
    _calibrateCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(calibrateCharacteristicUUID),
        serviceId: Uuid.parse(serviceUUID),
        deviceId: targetDevice!.id);
    _notifyCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(notifyCharacteristicUUID),
        serviceId: Uuid.parse(serviceUUID),
        deviceId: targetDevice!.id);
    _readCharacteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse(readCharacteristicUUID),
        serviceId: Uuid.parse(serviceUUID),
        deviceId: targetDevice!.id);
    serviceDiscoveryComplete = true;
    notifyListeners();
  }

  Future<void> startCalibration() async {
    if (targetDevice == null) {
      return;
    }
    //TODO: with or without response, that is the question
    await _ble.writeCharacteristicWithoutResponse(
      _calibrateCharacteristic,
      value: [0x01],
    );
  }

  Future<void> stopCalibration() async {
    if (targetDevice == null) {
      return;
    }
    await _ble.writeCharacteristicWithoutResponse(
      _calibrateCharacteristic,
      value: [0x00],
    );
  }

  Future<void> enableNotifications() async {
    if (targetDevice == null) {
      return;
    }
    await _ble.writeCharacteristicWithoutResponse(
      _notifyCharacteristic,
      value: [0x01],
    );
  }

  Future<void> disableNotifications() async {
    //not sure why you would want to do this, but here it is
    if (targetDevice == null) {
      return;
    }
    await _ble.writeCharacteristicWithoutResponse(
      _notifyCharacteristic,
      value: [0x00],
    );
  }

  Future<void> beginReading() async {
    if (targetDevice == null) {
      return;
    }
    _readSubscription = _ble.subscribeToCharacteristic(_readCharacteristic).listen((data) {
      if(kDebugMode){
        print(data);
      }
      if(data.isNotEmpty){
        //unsure if it is easier to parse data here or elsewhere

      }
    }
    );
  }

  Future<void> stopReading() async {
    if(_readSubscription != null){
      await _readSubscription!.cancel();
      _readSubscription = null;
    }
  }



  Future<void> stopScan() async {
    try {
      await _subscription?.cancel();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _connection?.cancel();
      isConnected = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
