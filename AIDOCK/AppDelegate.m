//
//  AppDelegate.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/19.
//

#import "AppDelegate.h"
#import <objc/runtime.h>

// iOS 26 fix: _UINavigationBarVisualProviderModernIOSSwift crashes with
// valueForUndefinedKey: contentView due to a UIKit internal KVC bug.
// Inject a safe implementation at load time, targeting only that private class.
@interface _iOS26NavBarKVCFix : NSObject
@end
@implementation _iOS26NavBarKVCFix
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *targets = @[
            @"_UINavigationBarVisualProviderModernIOSSwift",
            @"UIKit._UINavigationBarVisualProviderModernIOSSwift",
        ];
        IMP safeIMP = imp_implementationWithBlock(^id(id __unused self, NSString __unused *key) {
            return nil;
        });
        SEL sel = @selector(valueForUndefinedKey:);
        const char *types = method_getTypeEncoding(
            class_getInstanceMethod([NSObject class], sel));
        for (NSString *name in targets) {
            Class cls = NSClassFromString(name);
            if (!cls) continue;
            Method m = class_getInstanceMethod(cls, sel);
            if (m) {
                method_setImplementation(m, safeIMP);
            } else {
                class_addMethod(cls, sel, safeIMP, types);
            }
        }
    });
}
@end

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
