import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:testing_flutter_reactive_ble/bluetooth_view_model.dart';

class Buttons extends HookWidget {
  const Buttons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    BluetoothViewModel bluetoothViewModel =
        Provider.of<BluetoothViewModel>(context);
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
              onPressed: () {},
              child: const Text('Connect'),
            ),
            ElevatedButton(
              onPressed: () {
                bluetoothViewModel.stopScan();
              },
              child: const Text('Stop Scan'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Begin Read'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('End Read'),
            ),
            SingleChildScrollView(child: Text('Data'))
          ],
        ),
      ),
    );
  }
}
