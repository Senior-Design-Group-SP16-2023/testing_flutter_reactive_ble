import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'package:testing_flutter_reactive_ble/ble_device.dart';
import 'package:testing_flutter_reactive_ble/ble_consts.dart';

class BLEService extends ChangeNotifier {
  static final FlutterReactiveBle _ble = FlutterReactiveBle();

  bool isBluetoothOn = false;
  bool isReadyToWorkout = false;

  StreamSubscription? _subscription;
  final targetDevices = <BLEDevice>[];

  BLEService() {
    if (disableBluetooth) {
      //use disableBluetooth when running on emulator to get past screens that require bluetooth
      isBluetoothOn = true;
      isReadyToWorkout = true;
      notifyListeners();
      return;
    }
    isBluetoothOn = false;
    isReadyToWorkout = false;
    notifyListeners();
    _ble.logLevel = LogLevel.verbose;
    _ble.statusStream.listen((status) {
      if (status == BleStatus.ready) {
        isBluetoothOn = true;
        notifyListeners();
        //will start scan here for actual app
        //startScan();
      } else {
        isBluetoothOn = false;
      }
    });
  }

  startScan() {
    if (disableBluetooth) return;
    disconnect();
    targetDevices.clear();
    _subscription = _ble.scanForDevices(
      withServices: [Uuid.parse(sensorServiceUUID)],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    ).listen(
      (device) {
        BLEDevice newDevice = BLEDevice(_ble, device);
        targetDevices.add(newDevice);
        newDevice.isReadyNotifier.addListener(() {
          if (targetDevices.length == numDevices &&
              targetDevices.every((element) => element.isReadyNotifier.value)) {
            isReadyToWorkout = true;
            notifyListeners();
          } else {
            isReadyToWorkout = false;
            notifyListeners();
          }
        });
        newDevice.connectToDevice();
        if (targetDevices.length == numDevices) {
          stopScan();
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

  Future<void> stopScan() async {
    try {
      await _subscription?.cancel();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  disconnect() async {
    for (BLEDevice device in targetDevices) {
      await device.disconnect();
    }
    isReadyToWorkout = false;
    notifyListeners();
  }

  beginReading() {
    if (disableBluetooth) return;
    for (BLEDevice device in targetDevices) {
      device.beginReading();
    }
  }

  List<List<List<int>>> endReading() {
    if (disableBluetooth) return [];
    for (BLEDevice device in targetDevices) {
      device.endReading();
    }
    List<List<List<int>>> data = [];
    for (BLEDevice device in targetDevices) {
      data.add(device.getData());
    }
    // if(kDebugMode) {
    //   print(data);
    // }
    return data;
  }

  beginCalibration() {
    if (disableBluetooth) return;
    for (BLEDevice device in targetDevices) {
      device.beginCalibration();
    }
  }
}
