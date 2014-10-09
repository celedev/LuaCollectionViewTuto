// AppDelegate.m for a minimal iOS application using Celdev CodeFlow
// Created by Jean-Luc Jumpertz - Celedev on 29/10/2014

#import "AppDelegate.h"

#import "CIMLua/CIMLua.h"
#import "CIMLua/CIMLuaContextMonitor.h"

@interface AppDelegate ()
{
    CIMLuaContext* _luaContext;
    CIMLuaContextMonitor* _luaContextMonitor;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create a Lua Context and an associated Context monitor
    _luaContext = [[CIMLuaContext alloc] initWithName:@"Main Controller" mainSourcePackageId:@"MainController"];
    _luaContextMonitor = [[CIMLuaContextMonitor alloc] initWithLuaContext:_luaContext connectionTimeout:5];
    
    // Create the application window (standard stuff)
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // Run the Lua module that creates the root view controller
    [_luaContext loadLuaModuleNamed:@"CreateController" withCompletionBlock:^(id result) {
        
        if ([result isKindOfClass:[UIViewController class]])
        {
            self.window.rootViewController = result;
        }
    }];
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
