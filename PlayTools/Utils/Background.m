//
//  BatteryLevel.m
//  PlayTools
//
//  Created by Edoardo C. on 07/08/24.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <PlayTools/PlayTools-Swift.h>
#import "Background.h"

__attribute__((visibility("hidden")))
@interface BackgroundLoader : NSObject
@end

@implementation NSObject (SwizzleBackround)

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

- (UISceneActivationState) pm_return_background {
    return UISceneActivationStateUnattached;
}
@end

@implementation BackgroundLoader
+ (void)load {
    [objc_getClass("UIScene") swizzleInstanceMethod:@selector(activationState) withMethod:@selector(pm_return_background)];
}
@end
