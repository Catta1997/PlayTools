//
//  NewInstance.m
//  PlayTools
//
//  Created by Edoardo Cattarin on 26/08/24.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <PlayTools/PlayTools-Swift.h>
#import "NewInstance.h"

__attribute__((visibility("hidden")))
@interface NewInstanceLoader : NSObject
@end

@implementation NSObject (SwizzleInstance)
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
- (bool) pm_return_false {
    return false;
}
@end

@implementation NewInstanceLoader
+ (void)load {
    if(@available(iOS 13.2, *)) {
        [objc_getClass("UIWindow") swizzleInstanceMethod:@selector(application:shouldSaveSecureApplicationState:) withMethod:@selector(pm_return_false)];
    }
    else {
        [objc_getClass("UIWindow") swizzleInstanceMethod:@selector(application:shouldSaveApplicationState:) withMethod:@selector(pm_return_false)];
    }
}
@end
