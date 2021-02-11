#import "FlutterEscPosPlugin.h"
#if __has_include(<flutter_esc_pos/flutter_esc_pos-Swift.h>)
#import <flutter_esc_pos/flutter_esc_pos-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_esc_pos-Swift.h"
#endif

//#import <flutter_esc_pos/ePOS2.h>

@interface FlutterEscPosPlugin () <Epos2DiscoveryDelegate>
@property (nonatomic) FlutterMethodChannel *channel;

@end

@implementation FlutterEscPosPlugin

//@synthesize printer;
//@synthesize filter;
//@synthesize discovery;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterEscPosPlugin registerWithRegistrar:registrar];
    
}



//- (void)onPtrReceive:(Epos2Printer *)printerObj code:(int)code status:(Epos2PrinterStatusInfo *)status printJobId:(NSString *)printJobId {
////
//}

//- (void)startDiscover {
//    self.filter = [[Epos2FilterOption alloc] init];
//
//
////    self.discovery = [[Epos2Discovery alloc] init];
//
//
////
//}
//
- (void)onDiscovery:(Epos2DeviceInfo *)deviceInfo {
    NSLog(@"==================== on Discovery: [%@]",deviceInfo.target);
    
    
    
//    SwiftFlutterEscPosPlugin *plug = [SwiftFlutterEscPosPlugin alloc] init];
    
}

@end
