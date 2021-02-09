import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos/flutter_esc_pos.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _printerDiscoveryState = 'None';
  List<Printer> _printerList = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initCallbackHandler();
  }

  void initCallbackHandler() {
    FlutterEscPos.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'flutter_esc_pos#deviceInfo':
          print(call.arguments);
          setState(() {
            Printer printer = Printer();
            printer.target = call.arguments['target'];
            printer.ipAddress = call.arguments['ipAddress'];
            printer.macAddress = call.arguments['macAddress'];
            printer.bdAddress = call.arguments['bdAddress'];
            printer.deviceName = call.arguments['deviceName'];
            printer.deviceType = call.arguments['deviceType'];
            printer.printerType = call.arguments['printerType'];
            printer.printerSeries = call.arguments['printerSeries'];
            printer.connectionType = call.arguments['connectionType'];
            _printerList.add(printer);
          });
          break;
        default:
          print("Callback Method Not Found: ${call.method}\nArguments: ${call.arguments}");
      }
    });
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    String printerDiscoveryState;

    try {
      platformVersion = await FlutterEscPos.platformVersion;
      printerDiscoveryState = await FlutterEscPos.startPrinterDiscovery;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      printerDiscoveryState = 'Failed to get Printer Discovery State';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _printerDiscoveryState = printerDiscoveryState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              Text('Printer Discovery State: $_printerDiscoveryState\n'),
              Divider(),
              Text('Printers:\n'),
              for (Printer printer in _printerList) Text('${printer.deviceName}\n${printer.macAddress}\n${printer.printerSeries}\n${printer.connectionType}\n\n'),
              Divider(),
              FlatButton(
                child: Text("Print"),
                onPressed: () async {
                  for (Printer printer in _printerList) {
                    List<Map<String, dynamic>> list = [];
                    list.add(PrintText('Hello Printer ${printer.deviceName}').toMap());
                    list.add(PrintLine(1).toMap());
                    list.add(PrintTextCenter('${printer.ipAddress}').toMap());
                    list.add(PrintTextCenter('${printer.macAddress}').toMap());
                    list.add(PrintTextCenter('${printer.target}').toMap());
                    list.add(PrintLine(2).toMap());
                    list.add(PrintTextRight('this is on right!').toMap());
                    list.add(PrintLine(4).toMap());
                    list.add(PrintFeed(10).toMap());
                    list.add(PrintCut(1).toMap());
                    print(list);
                    String result = await FlutterEscPos.printToPrinter(list: list, printer: printer.target, printerSeries: printer.printerSeries);
                    print(result);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
