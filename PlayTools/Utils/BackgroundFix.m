//
//  BackgroundFix.m
//  PlayTools
//
//  Created by Edoardo C. on 03/07/2025.
//
//  This runtime patch prevents Catalyst games from being "frozen" when their
//  main window is minimised or moved to a different Space in macOS 15 Sequoia.
//  It forces every UIWindow's backing NSWindow to join *all* Spaces, avoiding
//  the occlusion‑based energy suspension introduced in macOS 15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - NSObject category that does the real work

@interface NSObject (PTBackgroundFix)
/// Iterate over all UIWindowScene / UIWindow pairs and force
/// NSWindow.collectionBehavior |= (CanJoinAllSpaces | Stationary)
+ (void)pt_applyJoinAllSpacesFix;
@end

@implementation NSObject (PTBackgroundFix)

+ (void)pt_applyJoinAllSpacesFix {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) { continue; }
        UIWindowScene *windowScene = (UIWindowScene *)scene;

        for (UIWindow *uiWindow in windowScene.windows) {
            // KVC bridge: UIWindow -> private NSWindow
            id nsWindow = [uiWindow valueForKey:@"nsWindow"];
            if (!nsWindow) { continue; }
            NSUInteger behavior = [[nsWindow valueForKey:@"collectionBehavior"] unsignedIntegerValue];

            const NSUInteger kCanJoinAllSpaces = (1 << 0); // NSWindowCollectionBehaviorCanJoinAllSpaces
            const NSUInteger kStationary       = (1 << 7); // NSWindowCollectionBehaviorStationary
            const NSUInteger requiredFlags     = kCanJoinAllSpaces | kStationary;

            if ((behavior & requiredFlags) != requiredFlags) {
                behavior |= requiredFlags;
                [nsWindow setValue:@(behavior) forKey:@"collectionBehavior"];
                NSLog(@"[PlayTools] JoinAllSpaces fix applied to %@", nsWindow);
            }
        }
    }
}

@end

#pragma mark - Loader class executed at injection time

__attribute__((visibility("hidden")))
@interface PTBackgroundFixLoader : NSObject
@end

@implementation PTBackgroundFixLoader

+ (void)load {
    [NSObject pt_applyJoinAllSpacesFix];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_pt_handleAppActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

+ (void)_pt_handleAppActive:(__unused NSNotification *)notification {
    [NSObject pt_applyJoinAllSpacesFix];
}

@end
