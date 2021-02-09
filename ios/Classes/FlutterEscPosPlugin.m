#import "FlutterEscPosPlugin.h"
#import "ePOS2.h"

@interface FlutterEscPosPlugin () <Epos2PtrReceiveDelegate,Epos2DiscoveryDelegate>
@property (nonatomic) FlutterMethodChannel *channel;
@end

@implementation FlutterEscPosPlugin

-(instancetype)initWithChannel:(FlutterMethodChannel *)methodChannel  {
    self = [super init];
    if(self) {
        self.channel = methodChannel;
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"flutter_esc_pos" binaryMessenger:[registrar messenger]];
    FlutterEscPosPlugin* instance = [[FlutterEscPosPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"================= handleMethodCall:[%@]",call.method);
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"startPrinterDiscovery" isEqualToString:call.method]) {
        Epos2FilterOption *option = [[Epos2FilterOption alloc] init];
        option.portType = EPOS2_PORTTYPE_ALL;
        option.deviceModel = EPOS2_MODEL_ALL;
        [Epos2Discovery start:option delegate:(id<Epos2DiscoveryDelegate>)self];
        result(@"success");
    } else if ([@"stopPrinterDiscovery" isEqualToString:call.method]) {
        [Epos2Discovery stop];
        result(@"success");
    } else if ([@"printList" isEqualToString:call.method]) {
        result([self printList:call.arguments[@"list"] toPrinter:call.arguments[@"printer"] withPrinterSeries:[call.arguments[@"printerSeries"] intValue]]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)onPtrReceive:(Epos2Printer *)printerObj code:(int)code status:(Epos2PrinterStatusInfo *)status printJobId:(NSString *)printJobId {
    NSLog(@"============== onPtrReceive");
}

-(void)onDiscovery:(Epos2DeviceInfo *)deviceInfo {
    NSString *ipAddress = deviceInfo.ipAddress;
    NSString *macAddress = deviceInfo.macAddress;
    NSString *bdAddress = deviceInfo.bdAddress;
    NSString *printerType = @"ip";
    NSString *connectionType = @"TCP";
    NSInteger printerSeries = [self getPrinterSeries:deviceInfo.deviceName];
    
    if (![bdAddress isEqualToString:@""] && [ipAddress isEqualToString:@""] && [macAddress isEqualToString:@""]) {
        ipAddress = bdAddress;
        macAddress = bdAddress;
        printerType = @"bluetooth";
        connectionType = @"BT";
    } else if ([bdAddress isEqualToString:@""] && ![macAddress isEqualToString:@""]) {
        bdAddress = macAddress;
    }
    
    NSDictionary *printerObj = @{
        @"target": deviceInfo.target,
        @"deviceName": deviceInfo.deviceName,
        @"ipAddress": ipAddress,
        @"macAddress": macAddress,
        @"bdAddress": bdAddress,
        @"deviceType": [NSNumber numberWithInt:deviceInfo.deviceType],
        @"printerType": printerType,
        @"connectionType": connectionType,
        @"printerSeries": [NSNumber numberWithInteger:printerSeries],
    };
    [self.channel invokeMethod:@"flutter_esc_pos#deviceInfo" arguments:printerObj];
}

-(NSString *)printList:(NSArray *)list toPrinter:(NSString *)target withPrinterSeries:(int)printerSeries {
    NSLog(@"===================== printer: %@ | series: %lu | List: %@",target, (long)printerSeries, list);
    Epos2Printer *printer = nil;
    printer = [[Epos2Printer alloc] initWithPrinterSeries:printerSeries lang:EPOS2_MODEL_ANK];
    if (printer == nil) {
        return @"Printer Did Not Init";
    }
    [printer setReceiveEventDelegate:self];
    int result = EPOS2_SUCCESS;

    for (NSDictionary *map in list) {
        if ([@"text" isEqualToString:map[@"key"]]) {
            [printer addText:map[@"value"]];
        } else if ([@"textRight" isEqualToString:map[@"key"]]) {
            [printer addTextAlign:EPOS2_ALIGN_RIGHT];
            [printer addText:map[@"value"]];
            [printer addTextAlign:EPOS2_ALIGN_LEFT];
        } else if ([@"textCenter" isEqualToString:map[@"key"]]) {
            [printer addTextAlign:EPOS2_ALIGN_CENTER];
            [printer addText:map[@"value"]];
            [printer addTextAlign:EPOS2_ALIGN_LEFT];
        } else if ([@"feed" isEqualToString:map[@"key"]]) {
            [printer addFeedLine:[map[@"value"] intValue]];
        } else if ([@"hline" isEqualToString:map[@"key"]]) {
            [printer addHLine:0 x2:65535 style:[map[@"value"] intValue]];
        } else if ([@"cut" isEqualToString:map[@"key"]]) {
            [printer addCut:[map[@"value"] intValue]];
        } else if ([@"drawer" isEqualToString:map[@"key"]]) {
            [printer addPulse:EPOS2_DRAWER_5PIN time:EPOS2_PARAM_DEFAULT];
        } else {
            NSLog(@"===================== [%@] not catered for!!!!!",map[@"key"]);
        }
    }

    result = EPOS2_SUCCESS;
    result = [printer connect:target timeout:EPOS2_PARAM_DEFAULT];
    if (result != EPOS2_SUCCESS) {
        return @"Printer Did Not Connect";
    } else if (result == EPOS2_SUCCESS) {
        Epos2PrinterStatusInfo *status = [printer getStatus];
        if ([status getConnection]) {
            result = [printer sendData:EPOS2_PARAM_DEFAULT];
            [printer disconnect];
            if (result != EPOS2_SUCCESS) {
                return @"Printer Did Not Print";
            } else {
                return @"OK";
            }
        } else {
            return @"Get Status Failed";
        }
    }
    return @"OK";
}

-(void)printTestToPrinter:(NSString *)printerSeries {
    
//    NSLog(@"=================== init printer");
//    Epos2Printer *printer = nil;
//    printer = [[Epos2Printer alloc] initWithPrinterSeries:EPOS2_TM_M30 lang:EPOS2_MODEL_ANK];
//    if (printer == nil) {
//        NSLog(@"=================== printer did not init");
//    }
//    [printer setReceiveEventDelegate:self];

//    NSLog(@"=================== prep print printer");
//    int result = EPOS2_SUCCESS;
////    result = [printer addTextAlign:EPOS2_ALIGN_CENTER];
//    result = [printer addText:@"Hello World"];
//    [printer addFeedLine:10];
//    [printer addCut:1];
//    if (result != EPOS2_SUCCESS) {
//        NSLog(@"=================== printer did not get data");
//    }

//    NSLog(@"=================== connect printer");
//    result = EPOS2_SUCCESS;
//    result = [printer connect:deviceInfo.target timeout:EPOS2_PARAM_DEFAULT];
//    if (result != EPOS2_SUCCESS) {
//        NSLog(@"=================== printer did not connect");
//    } else if (result == EPOS2_SUCCESS) {
//        Epos2PrinterStatusInfo *status = [printer getStatus];
//        if ([status getConnection]) {
//            result = [printer sendData:EPOS2_PARAM_DEFAULT];
//            if (result != EPOS2_SUCCESS) {
//                NSLog(@"=================== printer did NOT PRINT");
//            } else {
//                NSLog(@"=================== printer DID PRINT");
//            }
//            [printer disconnect];
//
//        }
//    }

    
    //    NSLog(@"=================== print printer");
//    result = [printer sendData:EPOS2_PARAM_DEFAULT];
//    if (result != EPOS2_SUCCESS) {
//        NSLog(@"=================== printer did NOT PRINT");
//    }
        
    
    
}


-(int)getPrinterSeries:(NSString *)printerName {
    int series = EPOS2_TM_T20;
    
    printerName = printerName.uppercaseString;
    
    if ([printerName isEqualToString:@"TM-M10"]) {
        series = EPOS2_TM_M10;
    }
    
    if ([printerName isEqualToString:@"TM-M30"]) {
        series = EPOS2_TM_M30;
    }
    
    if ([printerName isEqualToString:@"TM-M30II"] || [printerName isEqualToString:@"TM-M30II-H"] || [printerName isEqualToString:@"TM-M30II-NT"] || [printerName isEqualToString:@"TM-M30II-S"] || [printerName isEqualToString:@"TM-M30_023211"]) {
        series = EPOS2_TM_M30II;
    }
    
    if ([printerName isEqualToString:@"TM-M50"]) {
        series = EPOS2_TM_M50;
    }
    

    if ([printerName isEqualToString:@"TM-P20"]) {
        series = EPOS2_TM_P20;
    }
    
    if ([printerName isEqualToString:@"TM-P60"]) {
        series = EPOS2_TM_P60;
    }
    
    if ([printerName isEqualToString:@"TM-P60II"]) {
        series = EPOS2_TM_P60II;
    }
    
    if ([printerName isEqualToString:@"TM-P80"]) {
        series = EPOS2_TM_P80;
    }
    
    if ([printerName isEqualToString:@"TM-T20"] || [printerName isEqualToString:@"TM-T20II"] || [printerName isEqualToString:@"TM-T20II-I"] || [printerName isEqualToString:@"TM-T20III"] || [printerName isEqualToString:@"TM-T20IIIL"] || [printerName isEqualToString:@"TM-T20X"]) {
        series = EPOS2_TM_T20;
    }
    
    if ([printerName isEqualToString:@"TM-T60"]) {
        series = EPOS2_TM_T60;
    }

    if ([printerName isEqualToString:@"TM-T70"] || [printerName isEqualToString:@"TM-T70-I"] || [printerName isEqualToString:@"TM-T70II"] || [printerName isEqualToString:@"TM-T70II-DT"] || [printerName isEqualToString:@"TM-T70II-DT2"]) {
        series = EPOS2_TM_T70;
    }
    
    if ([printerName isEqualToString:@"TM-T81II"] || [printerName isEqualToString:@"TM-T81III"]) {
        series = EPOS2_TM_T81;
    }
    
    if ([printerName isEqualToString:@"TM-T82"] || [printerName isEqualToString:@"TM-T82II"] || [printerName isEqualToString:@"TM-T82II-I"] || [printerName isEqualToString:@"TM-T82III"] || [printerName isEqualToString:@"TM-T82IIIL"] || [printerName isEqualToString:@"TM-T82X"]) {
        series = EPOS2_TM_T82;
    }
    
    if ([printerName isEqualToString:@"TM-T83II-I"]) {
        series = EPOS2_TM_T83;
    }
    
    if ([printerName isEqualToString:@"TM-T83III"]) {
        series = EPOS2_TM_T83III;
    }
    
    if ([printerName isEqualToString:@"TM-T88IV"] || [printerName isEqualToString:@"TM-T88V"] || [printerName isEqualToString:@"TM-T88VI"] || [printerName isEqualToString:@"TM-T88V-I"] || [printerName isEqualToString:@"TM-T88VI-IHUB"] || [printerName isEqualToString:@"TM-T88V-DT"] || [printerName isEqualToString:@"TM-T88VI-DT2"]) {
        series = EPOS2_TM_T88;
    }
    
    if ([printerName isEqualToString:@"TM-T90"]) {
        series = EPOS2_TM_T90;
    }
    
    if ([printerName isEqualToString:@"TM-T100"]) {
        series = EPOS2_TM_T100;
    }
    
    if ([printerName isEqualToString:@"TM-U220"] || [printerName isEqualToString:@"TM-U220-I"]) {
        series = EPOS2_TM_U220;
    }
    
    if ([printerName isEqualToString:@"TM-U330"]) {
        series = EPOS2_TM_U330;
    }
    
    if ([printerName isEqualToString:@"TM-L90"]) {
        series = EPOS2_TM_L90;
    }
    
    if ([printerName isEqualToString:@"TM-H6000IV"] || [printerName isEqualToString:@"TM-H6000V"] || [printerName isEqualToString:@"TM-H6000IV-DT"]) {
        series = EPOS2_TM_H6000;
    }
    
    return series;
}
@end
