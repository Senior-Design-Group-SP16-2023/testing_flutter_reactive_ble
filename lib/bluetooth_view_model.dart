import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/cupertino.dart';
import 'package:testing_flutter_reactive_ble/ble/ble_device_connector.dart';
import 'package:testing_flutter_reactive_ble/ble/ble_scanner.dart';
import 'package:testing_flutter_reactive_ble/ble/ble_device_interactor.dart';
import 'package:testing_flutter_reactive_ble/ble/ble_logger.dart';
import 'package:testing_flutter_reactive_ble/ble/ble_status_monitor.dart';

class BluetoothViewModel extends ChangeNotifier {
  final _ble = FlutterReactiveBle();
  late BleDeviceConnector _connector;
  late BleScanner _scanner;
  late BleDeviceInteractor _interactor;
  late BleLogger _logger;
  //late BleStatusMonitor _statusMonitor;

  final Uuid uuid1 = Uuid.parse('7147ac18-c824-438e-8506-60829fbd96a3');

  late List<Uuid> serviceIds;

  BluetoothViewModel() {
    print("LOADING");
    print(uuid1.expanded);
    serviceIds = [];
    _logger = BleLogger(ble: _ble);
    _connector = BleDeviceConnector(ble: _ble, logMessage: _logger.addToLog);
    _scanner = BleScanner(ble: _ble, logMessage: _logger.addToLog);
    //_statusMonitor = BleStatusMonitor(_ble);
    _interactor = BleDeviceInteractor(
      bleDiscoverServices: (deviceId) async {
        await _ble.discoverAllServices(deviceId);
        return _ble.getDiscoveredServices(deviceId);
      },
      logMessage: _logger.addToLog,
      readRssi: (deviceId) => _ble.readRssi(deviceId),
    );
    print("INITIALISED");
    _ble.statusStream.listen((status) {
      if (status == BleStatus.unsupported) {
        print('BLE is not supported');
      }
      if (status == BleStatus.ready) {
        scan();
      } else {
        print(status);
      }
    });
  }

  Future<void> scan() async {
    print("SCANNING");
    _scanner.startScan(serviceIds);
    StreamSubscription<BleScannerState>? b;
    b = _scanner.state.listen((state) {
      if (state.scanIsInProgress) {
        print('Scanning...');
      } else {
        print('Scan finished');
        b?.cancel();
        _scanner.stopScan();
        connect();
      }
    });
  }

  Future<void> stopScan() async {
    _scanner.stopScan();
  }

  Future<void> connect() async {
    print("CONNECTING");
    //get the discovered devices
    final discoveredDevices = _scanner.discoveredDevices;
    //connect to every device discovered
    if (discoveredDevices.isEmpty) {
      print('No devices found');
      return;
    }
    //connect to the first one

    DiscoveredDevice? deviceS;

    for(var device in discoveredDevices){
      if(device.name == "NRF DEVBOARD"){
        deviceS = device;
        await _connector.connect(device.id);
        print('Connected to ${device.name}');

      }
    }

    await Future.delayed(const Duration(seconds: 3));

    _connector.state.listen((event) {
      print('Connection state: $event');
      if(event.connectionState == DeviceConnectionState.connected){
        print('We are live!');
      }
    });

    if(deviceS == null){
      print('No device found');
      return;
    }



    // final device = discoveredDevices.first;
    // await _connector.connect(device.id);
    print('For Real connected to ${deviceS.name}');

    print("Device ID: ${deviceS.id}");

    //wait 3 seconds


    //get the 16 bit UUID of the device

    List<Service> services = await _interactor.discoverServices(deviceS.id);

    print('Discovered services: ${services.length}');

    //for each service, get the characteristics
    Characteristic? toSubscribe;

    Characteristic? toWriteWithResponse;

    for (Service service in services) {
      print('Service: ${service.id}');
      for (Characteristic characteristic in service.characteristics) {
        print('Characteristic: ${characteristic.id}');
        print(characteristic.id);
        print(characteristic.isIndicatable);
        print(characteristic.isNotifiable);
        print(characteristic.isReadable);
        print(characteristic.isWritableWithResponse);
        print(characteristic.isWritableWithoutResponse);
        print(characteristic.service);

      }
    }
    //able to find all the characteristics
    //subscribe to the characteristic
    if (toSubscribe == null) {
      print('No characteristic to subscribe to');
      return;
    } else {
      print('Subscribing to: ${toSubscribe.id}');
    }
    //print everything about the characteristic

    if(toWrite == null){
      print('No characteristic to write to');
      return;
    }else{
      print('Writing to: ${toWrite.id}');
    }

    StreamSubscription<List<int>> subStream =
        toSubscribe.subscribe().listen((event) {
      print('Received data: $event');
    }, onError: (Object e) {
      print('Error: $e');
    });


  }

  Future<void> disconnect(String deviceId) async {
    await _connector.disconnect(deviceId); 
  }

  //maybe a dispose function
}
