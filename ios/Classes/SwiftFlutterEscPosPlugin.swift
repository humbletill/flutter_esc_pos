import Flutter
import UIKit

private var myChannel:FlutterMethodChannel?

public class SwiftFlutterEscPosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_esc_pos", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterEscPosPlugin()
        myChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }


    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("================= handleMethodCall:[\(call.method)]")
        if "getPlatformVersion" == call.method {
            result("iOS " + UIDevice.current.systemVersion)
        } else if "startPrinterDiscovery" == call.method {
            let option = Epos2FilterOption()
            option.portType = EPOS2_PORTTYPE_ALL
            option.deviceModel = EPOS2_MODEL_ALL
            Epos2Discovery.start(option, delegate: self as? Epos2DiscoveryDelegate?)
            result("success")
        } else if "stopPrinterDiscovery" == call.method {
            Epos2Discovery.stop()
            result("success")
        } else if "printList" == call.method {
            result(printList(call.arguments["list"] as? [String], toPrinter: call.arguments["printer"], withPrinterSeries: (call.arguments["printerSeries"] as? Int).intValue))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onPtrReceive(_ printerObj: Epos2Printer?, code: Int, status: Epos2PrinterStatusInfo?, printJobId: String?) {
        print("============== onPtrReceive")
    }
    
    public func onDiscovery(_ deviceInfo: Epos2DeviceInfo?) {
        var target = deviceInfo?.target
        var deviceName = deviceInfo?.deviceName
        var ipAddress = deviceInfo?.ipAddress
        var macAddress = deviceInfo?.macAddress
        var bdAddress = deviceInfo?.bdAddress
        var printerType = "ip"
        var connectionType = "TCP"
        let printerSeries = getPrinterSeries(deviceInfo?.deviceName)

        if (bdAddress != "") && (ipAddress == "") && (macAddress == "") {
            ipAddress = bdAddress
            macAddress = bdAddress
            printerType = "bluetooth"
            connectionType = "BT"
        } else if (bdAddress == "") && (macAddress != "") {
            bdAddress = macAddress
        }

        let printerObj = [
            "target": target,
            "deviceName": deviceName,
            "ipAddress": ipAddress ?? "",
            "macAddress": macAddress ?? "",
            "bdAddress": bdAddress ?? "",
            "deviceType": NSNumber(value: deviceInfo?.deviceType ?? 0),
            "printerType": printerType,
            "connectionType": connectionType,
            "printerSeries": NSNumber(value: printerSeries),
        ]
        myChannel.invokeMethod("flutter_esc_pos#deviceInfo", arguments: printerObj)
    }
    
    public func printList(_ list: [AnyHashable]?, toPrinter target: String?, withPrinterSeries printerSeries: Int) -> String? {
        print(String(format: "===================== printer: %@ | series: %lu | List: %@", target ?? "", printerSeries, list ?? []))
        var printer: Epos2Printer? = nil
        printer = Epos2Printer(printerSeries: printerSeries, lang: EPOS2_MODEL_ANK)

        if printer == nil {
           return "Printer Did Not Init"
        }
        printer.receiveEventDelegate = self
        let result = EPOS2_SUCCESS
        
        for map in list {
            if "text" == map["key"] {
                printer.addText(map["value"])
            } else if "textRight" == map["key"] {
                printer.addTextAlign(EPOS2_ALIGN_RIGHT)
                printer.addText(map["value"])
                printer.addTextAlign(EPOS2_ALIGN_LEFT)
            } else if "textCenter" == map["key"] {
                printer.addTextAlign(EPOS2_ALIGN_CENTER)
                printer.addText(map["value"])
                printer.addTextAlign(EPOS2_ALIGN_LEFT)
            } else if "feed" == map["key"] {
                printer.addFeedLine(map["value"].intValue)
            } else if "hline" == map["key"] {
                printer.addHLine(0, x2: 65535, style: map["value"].intValue)
            } else if "cut" == map["key"] {
                printer.addCut(map["value"].intValue)
            } else if "drawer" == map["key"] {
                printer.addPulse(EPOS2_DRAWER_5PIN, time: EPOS2_PARAM_DEFAULT)
            } else {
                print("===================== [\(map["key"])] not catered for!!!!!")
            }
        }
        
        result = EPOS2_SUCCESS
        result = printer.connect(target, timeout: EPOS2_PARAM_DEFAULT)
        if result != EPOS2_SUCCESS {
            return "Printer Did Not Connect"
        } else if result == EPOS2_SUCCESS {
            let status = printer.getStatus()
            if status?.getConnection() {
                result = printer.sendData(EPOS2_PARAM_DEFAULT)
                printer.disconnect()
                if result != EPOS2_SUCCESS {
                    return "Printer Did Not Print"
                } else {
                    return "OK"
                }
            } else {
                return "Get Status Failed"
            }
        }
        return "OK"
    }
    
    public func getPrinterSeries(_ printerName: String?) -> Int {
        var printerName = printerName
        var series = EPOS2_TM_T20

        printerName = printerName?.uppercased()

        if printerName == "TM-M10" {
            series = EPOS2_TM_M10
        }

        if printerName == "TM-M30" {
            series = EPOS2_TM_M30
        }

        if (printerName == "TM-M30II") || (printerName == "TM-M30II-H") || (printerName == "TM-M30II-NT") || (printerName == "TM-M30II-S") || (printerName == "TM-M30_023211") {
            series = EPOS2_TM_M30II
        }

        if printerName == "TM-M50" {
            series = EPOS2_TM_M50
        }

        if printerName == "TM-P20" {
            series = EPOS2_TM_P20
        }

        if printerName == "TM-P60" {
            series = EPOS2_TM_P60
        }

        if printerName == "TM-P60II" {
            series = EPOS2_TM_P60II
        }

        if printerName == "TM-P80" {
            series = EPOS2_TM_P80
        }

        if (printerName == "TM-T20") || (printerName == "TM-T20II") || (printerName == "TM-T20II-I") || (printerName == "TM-T20III") || (printerName == "TM-T20IIIL") || (printerName == "TM-T20X") {
            series = EPOS2_TM_T20
        }

        if printerName == "TM-T60" {
            series = EPOS2_TM_T60
        }

        if (printerName == "TM-T70") || (printerName == "TM-T70-I") || (printerName == "TM-T70II") || (printerName == "TM-T70II-DT") || (printerName == "TM-T70II-DT2") {
            series = EPOS2_TM_T70
        }

        if (printerName == "TM-T81II") || (printerName == "TM-T81III") {
            series = EPOS2_TM_T81
        }

        if (printerName == "TM-T82") || (printerName == "TM-T82II") || (printerName == "TM-T82II-I") || (printerName == "TM-T82III") || (printerName == "TM-T82IIIL") || (printerName == "TM-T82X") {
            series = EPOS2_TM_T82
        }

        if printerName == "TM-T83II-I" {
            series = EPOS2_TM_T83
        }

        if printerName == "TM-T83III" {
            series = EPOS2_TM_T83III
        }

        if (printerName == "TM-T88IV") || (printerName == "TM-T88V") || (printerName == "TM-T88VI") || (printerName == "TM-T88V-I") || (printerName == "TM-T88VI-IHUB") || (printerName == "TM-T88V-DT") || (printerName == "TM-T88VI-DT2") {
            series = EPOS2_TM_T88
        }

        if printerName == "TM-T90" {
            series = EPOS2_TM_T90
        }

        if printerName == "TM-T100" {
            series = EPOS2_TM_T100
        }

        if (printerName == "TM-U220") || (printerName == "TM-U220-I") {
            series = EPOS2_TM_U220
        }

        if printerName == "TM-U330" {
            series = EPOS2_TM_U330
        }

        if printerName == "TM-L90" {
            series = EPOS2_TM_L90
        }

        if (printerName == "TM-H6000IV") || (printerName == "TM-H6000V") || (printerName == "TM-H6000IV-DT") {
            series = EPOS2_TM_H6000
        }

        return series
    }

}
