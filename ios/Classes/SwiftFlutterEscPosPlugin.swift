import Flutter
import UIKit

public var myChannel:FlutterMethodChannel?



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
            let fOption:Epos2FilterOption = Epos2FilterOption()
            fOption.portType = EPOS2_PORTTYPE_ALL.rawValue
            fOption.deviceModel = EPOS2_MODEL_ALL.rawValue
            let plug:FlutterEscPosPlugin = FlutterEscPosPlugin()
            Epos2Discovery.start(fOption, delegate:self)
            result("success")
        } else if "stopPrinterDiscovery" == call.method {
            Epos2Discovery.stop()
            result("success")
        } else if "printList" == call.method {
            let list:[[String : Any]] = (call.arguments as! [String : Any]) ["list"] as! [[String : Any]]
            let target:String = (call.arguments as! [String : Any]) ["printer"] as! String
            let printerSeries:Epos2PrinterSeries = (call.arguments as! [String : Any]) ["printerSeries"] as! Epos2PrinterSeries
            result(printList(list, toPrinter: target, withPrinterSeries: printerSeries))
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onPtrReceive(_ printerObj: Epos2Printer?, code: Int, status: Epos2PrinterStatusInfo?, printJobId: String?) {
        print("============== onPtrReceive")
    }
    
    public func onDiscovery(_ deviceInfo: Epos2DeviceInfo?) {
        print("============== onDiscovery")
        let target = deviceInfo?.target
        let deviceName = deviceInfo?.deviceName
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

        let printerObj:[String : Any] = [
            "target": target ?? "",
            "deviceName": deviceName ?? "",
            "ipAddress": ipAddress ?? "",
            "macAddress": macAddress ?? "",
            "bdAddress": bdAddress ?? "",
            "deviceType": NSNumber(value: deviceInfo?.deviceType ?? 0),
            "printerType": printerType,
            "connectionType": connectionType,
            "printerSeries": NSNumber(value: printerSeries.rawValue),
        ]
        myChannel?.invokeMethod("flutter_esc_pos#deviceInfo", arguments: printerObj)
    }
    
    public func printList(_ list: [[String : Any]]?, toPrinter target: String?, withPrinterSeries printerSeries: Epos2PrinterSeries) -> String? {
        let printer:Epos2Printer? = Epos2Printer(printerSeries: printerSeries.rawValue, lang: EPOS2_MODEL_ANK.rawValue)

        if printer == nil {
           return "Printer Did Not Init"
        }
//        printer.receiveEventDelegate = self
        var result:Epos2ErrorStatus = EPOS2_SUCCESS

        if let lists:[[String : Any]] = list {
            for map:[String : Any] in lists {
                for (key, value) in map {
                    if "text" == key {
                        printer?.addText(value as? String)
                    } else if "textRight" == key {
                        printer?.addTextAlign(EPOS2_ALIGN_RIGHT.rawValue)
                        printer?.addText(value as? String)
                        printer?.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
                    } else if "textCenter" == key {
                        printer?.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
                        printer?.addText(value as? String)
                        printer?.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
                    } else if "feed" == key {
                        printer?.addFeedLine(value as! Int)
                    } else if "hline" == key {
                        printer?.addHLine(0, x2: 65535, style: value as! Int32)
                    } else if "cut" == key {
                        printer?.addCut(value as! Int32)
                    } else if "drawer" == key {
                        printer?.addPulse(EPOS2_DRAWER_5PIN.rawValue, time: EPOS2_PARAM_DEFAULT.byteSwapped)
                    } else {
                        print("===================== [\(key)] not catered for!!!!!")
                    }
                }
            }
        }

        result = EPOS2_SUCCESS
        if (printer?.connect(target, timeout: EPOS2_PARAM_DEFAULT.hashValue)) != nil {
            result = EPOS2_SUCCESS
        } else {
            result = EPOS2_ERR_FAILURE
        }
        if result != EPOS2_SUCCESS {
            return "Printer Did Not Connect"
        } else if result == EPOS2_SUCCESS {
            if let status:Epos2PrinterStatusInfo = printer?.getStatus() {
                if status.connection == EPOS2_SUCCESS.rawValue {
                    if let printResult = printer?.sendData(EPOS2_PARAM_DEFAULT.hashValue) {
                        printer?.disconnect()
                        if printResult == EPOS2_SUCCESS.rawValue {
                            return "OK"
                        } else {
                            return "Printer Did Not Print"
                        }
                    } else {
                        return "Printer did Not Print"
                    }
                }
            } else {
                return "Did Not Get Status"
            }
        }
        return "OK"
    }
    
    public func getPrinterSeries(_ printerName: String?) -> Epos2PrinterSeries {
        var printerName = printerName
        var series:Epos2PrinterSeries = EPOS2_TM_T20

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
