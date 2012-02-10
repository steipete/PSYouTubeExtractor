//
//  PSAppDelegate.m
//  BetterYouTube
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import "PSAppDelegate.h"
#import "PSYouTubeTestViewController.h"

@implementation PSAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[PSYouTubeTestViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
