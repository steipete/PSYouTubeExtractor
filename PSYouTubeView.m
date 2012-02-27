//
//  PSYouTubeView.m
//  PSYouTubeExtractor
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import "PSYouTubeView.h"
#import "PSYouTubeExtractor.h"

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface PSYouTubeView() {
    BOOL showNativeFirst_;
    PSYouTubeExtractor *extractor_;
}
@end

@implementation PSYouTubeView

@synthesize youTubeURL = youTubeURL_;
@synthesize youTubeMovieURL = youTubeMovieURL_;
@synthesize nativeView = nativeView_;
@synthesize setupNativeView = setupNativeView_;
@synthesize setupWebView = setupWebView_;
@synthesize moviePlayerController = moviePlayerController_;
@synthesize webView = webView_;
@synthesize error = error_;
@synthesize animated = animated_;

- (id)initWithYouTubeURL:(NSURL *)youTubeURL frame:(CGRect)frame showNativeFirst:(BOOL)showNativeFirst {
    if ((self = [super initWithFrame:frame])) {
        youTubeURL_ = youTubeURL;
        showNativeFirst_ = showNativeFirst;
        animated_ = YES;
        
        __unsafe_unretained PSYouTubeView *weakSelf = self;
        setupNativeView_ = ^{
            if (!weakSelf.moviePlayerController) {
                MPMoviePlayerController *movieController = [[MPMoviePlayerController alloc] initWithContentURL:weakSelf.youTubeMovieURL];
                movieController.view.frame = weakSelf.bounds;
                movieController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;   
                [weakSelf insertSubview:movieController.view atIndex:0];
                weakSelf->moviePlayerController_ = movieController;
            }else {
                weakSelf.moviePlayerController.contentURL = weakSelf.youTubeMovieURL;
            }
            
            if (weakSelf.youTubeMovieURL) {
                [weakSelf.moviePlayerController prepareToPlay];
                [weakSelf.moviePlayerController setShouldAutoplay:YES];
            }
            
            // if there is a webview, remove it!
            if (weakSelf.webView) {
                [UIView animateWithDuration:weakSelf.isAnimated ? 0.3f : 0.f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    weakSelf.webView.alpha = 0.f;
                } completion:^(BOOL finished) {
                    [weakSelf.webView removeFromSuperview];
                    weakSelf.webView.delegate = nil;
                    weakSelf.webView = nil;
                }];
            }
        };
        
        setupWebView_ = ^{
            if (!weakSelf.webView) {
                UIWebView *webView = [[UIWebView alloc] initWithFrame:weakSelf.bounds];
                webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [weakSelf insertSubview:webView atIndex:0];
                // allow inline playback, even on iPhone
                webView.allowsInlineMediaPlayback = YES;
                weakSelf->webView_ = webView;
                
                // load plugin
                NSString *embedHTML = @"<html><head><style type=\"text/css\"> \
                body {background-color:transparent;color:white;}</style> \
                </head><body style=\"margin:0\"> \
                <embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
                width=\"%0.0f\" height=\"%0.0f\"></embed></body></html>";  
                NSString *html = [NSString stringWithFormat:embedHTML, [weakSelf.youTubeURL absoluteString], weakSelf.frame.size.width, weakSelf.frame.size.height]; 
                [webView loadHTMLString:html baseURL:nil];                
            }
            
            // remove MPMoviePlayerController
            if(weakSelf.moviePlayerController) {
                [UIView animateWithDuration:weakSelf.isAnimated ? 0.3f : 0.f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    weakSelf.moviePlayerController.view.alpha = 0.f;
                } completion:^(BOOL finished) {
                    [weakSelf.moviePlayerController.view removeFromSuperview];
                    weakSelf.moviePlayerController = nil;
                }];
            }
        };
        
        // retains itself until either success or failure is called
        extractor_ = [PSYouTubeExtractor extractorForYouTubeURL:self.youTubeURL success:^(NSURL *URL) {
            //NSLog(@"Finished extracting: %@", URL);
            youTubeMovieURL_ = URL;
            if (setupNativeView_) {
                setupNativeView_();
            }
        } failure:^(NSError *error) {
            //NSLog(@"Failed to query mp4: %@", error);
            error_ = error;
            if (setupWebView_) {
                setupWebView_();
            }
        }];
    }
    return self;
}

- (void)dealloc {
    [extractor_ cancel];
    webView_ .delegate = nil;
}

// invoke the view generation as soon as the view will be added to the screen
// (don't do that in init to allow replacement of the blocks)
- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!self.webView && !self.moviePlayerController) {
        if (showNativeFirst_) {
            if (setupNativeView_) {
                setupNativeView_();
            }
        }else {
            if (setupWebView_) {
                setupWebView_();
            }
        }
    }
}

@end
