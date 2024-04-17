import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:testing_flutter_reactive_ble/ble_service.dart';

class Buttons2 extends HookWidget {
  const Buttons2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    BLEService bleService = Provider.of<BLEService>(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Demo Home Page'),
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                bleService.startScan();
              },
              child: const Text('Start Scan'),
            ),
            ElevatedButton(
              onPressed: () {
                bleService.stopScan();
              },
              child: const Text('Stop Scan'),
            ),
            ElevatedButton(
                onPressed: () {
                  bleService.beginCalibration();
                },
                child: const Text('Start Calibration')),
            ElevatedButton(
                onPressed: () {
                  bleService.endCalibration();
                },
                child: const Text('Stop Calibration')),
            ElevatedButton(
                onPressed: () {
                  bleService.beginReading();
                },
                child: const Text('Start Reading')),
            ElevatedButton(
                onPressed: () {
                  bleService.endReading();
                },
                child: const Text('Stop Reading')),
            SingleChildScrollView(child: Text('Data'))
          ],
        ),
      ),
    );
  }
}
