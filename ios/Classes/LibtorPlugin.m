#import "LibtorPlugin.h"
#if __has_include(<libtor/libtor-Swift.h>)
#import <libtor/libtor-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "libtor-Swift.h"
#endif

@implementation LibtorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLibtorPlugin registerWithRegistrar:registrar];
}
@end
