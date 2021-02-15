#import <Flutter/Flutter.h>
#import <flutter_esc_pos/ePOS2.h>

@interface FlutterEscPosPlugin : NSObject<FlutterPlugin, Epos2DiscoveryDelegate, Epos2PtrReceiveDelegate>

//@property (nonatomic) Epos2Printer *printer;
//@property (nonatomic) Epos2FilterOption *filter;
//@property (nonatomic) Epos2Discovery *discovery;

//- (void)startDiscover;

- (void)startEpsonDiscovery:(Epos2FilterOption *)option forChannel:(FlutterMethodChannel *)channel;
+ (NSString *)printList:(NSArray *)list toPrinter:(NSString *)target withPrinterSeries:(int)printerSeries;
- (int)getPrinterSeries:(NSString *)printerName;

@end
