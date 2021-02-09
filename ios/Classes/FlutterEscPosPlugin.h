#import <Flutter/Flutter.h>
#import "ePOS2.h"
#import "ePOSEasySelect.h"

@interface FlutterEscPosPlugin : NSObject<FlutterPlugin, Epos2DiscoveryDelegate>

//+(int)start:(Epos2FilterOption *)filterOption delegate:(id<Epos2DiscoveryDelegate>)delegate;

@end
