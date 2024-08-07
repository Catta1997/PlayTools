//
//  BatteryLevel.m
//  PlayTools
//
//  Created by Edoardo Cattarin on 07/08/24.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <PlayTools/PlayTools-Swift.h>
#import "UIKit/UIKit.h"
#import "BatteryLevel.h"
__attribute__((visibility("hidden")))
@interface PTSwizzleLoader : NSObject
@end

@implementation NSObject (Swizzle)

- (void) swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    // If current class doesn't exist selector, then get super
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, newSelector);
    
    // Add selector if it doesn't exist, implement append with method
    if (class_addMethod(cls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        // Replace class instance method, added if selector not exist
        // For class cluster, it always adds new selector here
        class_replaceMethod(cls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        // SwizzleMethod maybe belongs to super
        class_replaceMethod(cls,
                            newSelector,
                            class_replaceMethod(cls,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

- (void) swizzleExchangeMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    // If current class doesn't exist selector, then get super
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, newSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

@end
@implementation PTSwizzleLoader

- (bool) pm_return_true {
    return true;
}

- (float) pm_return_battery_full {
    return 1.0;
}

- (UIDeviceBatteryState) pm_return_charging {
    return UIDeviceBatteryStateFull;
}

+ (void)load {
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(isBatteryMonitoringEnabled) withMethod:@selector(pm_return_true)];
    [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(batteryState) withMethod:@selector(pm_return_charging)];
    [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(batteryLevel) withMethod:@selector(pm_return_battery_full)];}
@end
