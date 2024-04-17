import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'package:testing_flutter_reactive_ble/my_device.dart';

class BLEService extends ChangeNotifier {
  static final FlutterReactiveBle _ble = FlutterReactiveBle();

  bool isReady = false;
  bool isSetup = false;
  bool start = false;

  StreamSubscription? _subscription;
  final targetDevices = <MyDevice>[];

  static const List<String> names = ['SP16 Sensor Board'];

  BLEService() {
    isReady = false;
    isSetup = false;
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
    start = true;
    // disconnect();
    while(!start) {
      //wait for ble to be ready
    }
    if (!isReady) {
      return;
    }
    targetDevices.clear();
    _subscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: false,
    ).listen(
      (device) {
        if (names.contains(device.name)) {
          MyDevice newDevice = MyDevice(_ble, device);
          targetDevices.add(newDevice);
          late VoidCallback listener;
          listener = () {
            if (targetDevices.length == names.length &&
                targetDevices
                    .every((element) => element.isReadyNotifier.value)) {
              isSetup = true;
              notifyListeners();
            }
            newDevice.isReadyNotifier.removeListener(listener);
          };
          newDevice.isReadyNotifier.addListener(listener);
          if (targetDevices.length == names.length) {
            stopScan();
            connectToDevices();
          }
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

  connectToDevices() {
    for (MyDevice device in targetDevices) {
      device.connectToDevice();
    }
  }

  disconnect() async {
    for (MyDevice device in targetDevices) {
      await device.disconnect();
    }
    start = true;
    isSetup = false;
    notifyListeners();
  }

  beginReading() {
    for (MyDevice device in targetDevices) {
      device.beginReading();
    }
  }

  endReading() {
    for (MyDevice device in targetDevices) {
      device.endReading();
    }
  }

  beginCalibration() {
    for (MyDevice device in targetDevices) {
      device.beginCalibration();
    }
  }

  endCalibration() {
    for (MyDevice device in targetDevices) {
      device.endCalibration();
    }
  }
}
