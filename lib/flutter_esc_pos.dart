import 'dart:async';

import 'package:flutter/services.dart';

class FlutterEscPos {
  static const MethodChannel _channel = const MethodChannel('flutter_esc_pos');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get startPrinterDiscovery async {
    final String result = await _channel.invokeMethod('startPrinterDiscovery');
    return result;
  }

  static Future<String> get stopPrinterDiscovery async {
    final String result = await _channel.invokeMethod('stopPrinterDiscovery');
    return result;
  }

  static Future<String> printToPrinter({List<Map<String, dynamic>> list, String printer, int printerSeries}) async {
    final String result = await _channel.invokeMethod('printList', {'list': list, 'printer': printer, 'printerSeries': printerSeries});
    return result;
  }

  static void setMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
    _channel.setMethodCallHandler(handler);
  }
}

class Printer {
  String target;
  String ipAddress;
  String macAddress;
  String bdAddress;
  String deviceName;
  int deviceType;
  String printerType;
  int printerSeries;
  String connectionType;
}

class PrintObj {
  PrintObj();

  String key;
  dynamic value;

  toMap() {
    return {'key': this.key, 'value': this.value};
  }
}

class PrintText extends PrintObj {
  PrintText(String text) : super() {
    this.key = 'text';
    this.value = '$text\n';
  }

  String key;
  dynamic value;
}

class PrintTextCenter extends PrintObj {
  PrintTextCenter(String text) : super() {
    this.key = 'textCenter';
    this.value = '$text\n';
  }

  String key;
  dynamic value;
}

class PrintTextRight extends PrintObj {
  PrintTextRight(String text) : super() {
    this.key = 'textRight';
    this.value = '$text\n';
  }

  String key;
  dynamic value;
}

class PrintFeed extends PrintObj {
  PrintFeed(int lines) : super() {
    this.key = 'feed';
    this.value = lines;
  }

  String key;
  dynamic value;
}

class PrintLine extends PrintObj {
  PrintLine(int lineThickness) : super() {
    this.key = 'hline';
    this.value = lineThickness;
  }

  String key;
  dynamic value;
}

class PrintCut extends PrintObj {
  PrintCut(int type) : super() {
    this.key = 'cut';
    this.value = type;
  }

  String key;
  dynamic value;
}

class PrintDrawer extends PrintObj {
  PrintDrawer(int type) : super() {
    this.key = 'drawer';
    this.value = type;
  }

  String key;
  dynamic value;
}
