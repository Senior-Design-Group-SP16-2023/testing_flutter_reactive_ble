import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testing_flutter_reactive_ble/new_buttons.dart';
import 'package:testing_flutter_reactive_ble/ble_service.dart';

void main() {
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BLEService()),
      ],
      child: Buttons2(),
    );
  }
}
