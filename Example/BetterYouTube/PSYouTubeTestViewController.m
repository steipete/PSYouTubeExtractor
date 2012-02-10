//
//  PSYouTubeTestViewController.m
//  BetterYouTube
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import "PSYouTubeTestViewController.h"
#import "PSYouTubeView.h"

@implementation PSYouTubeTestViewController

@synthesize moviePlayerController = moviePlayerController_;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *youTubeURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=Vo0Cazxj_yc"];
    CGFloat size = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? 250 : 500;
    CGRect videoRect = CGRectMake(0, 0, size, size);
    
    PSYouTubeView *youTubeView = [[PSYouTubeView alloc] initWithYouTubeURL:youTubeURL frame:videoRect showNativeFirst:YES];
    youTubeView.center = self.view.center;
    youTubeView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:youTubeView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
