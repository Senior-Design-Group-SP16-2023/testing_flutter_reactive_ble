import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:testing_flutter_reactive_ble/ble/reactive_state.dart';

class BleScanner implements ReactiveState<BleScannerState> {
  BleScanner(
      {required FlutterReactiveBle ble,
      required void Function(String message) logMessage})
      : _ble = ble,
        _logMessage = logMessage;

  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  final StreamController<BleScannerState> _stateStreamController =
      StreamController();

  final _devices = <DiscoveredDevice>[];

  @override
  Stream<BleScannerState> get state => _stateStreamController.stream;

  get discoveredDevices {
    return _devices;
  }

  void startScan(List<Uuid> serviceIds) {
    _logMessage('Start ble discovery');
    print("serviceIds: $serviceIds");
    _devices.clear();
    _subscription?.cancel();
    _subscription = _ble.scanForDevices(withServices: serviceIds).listen(
      (device) {
        final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
        if (knownDeviceIndex >= 0) {
          _devices[knownDeviceIndex] = device;
        } else {
          print('Found device: ${device.name}');
          _devices.add(device);
        }
        _pushState();
      },
      onError: (Object e) => {
        _logMessage('Device scan fails with error: $e'),
        print("error in scan: $e")
      },
    );

    _pushState();
  }

  void _pushState() {
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  Future<void> stopScan() async {
    _logMessage('Stop ble discovery');

    await _subscription?.cancel();
    _subscription = null;
    _pushState();
  }

  Future<void> dispose() async {
    await _stateStreamController.close();
  }

  StreamSubscription<DiscoveredDevice>? _subscription;
}

class BleScannerState {
  const BleScannerState({
    required this.discoveredDevices,
    required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}
