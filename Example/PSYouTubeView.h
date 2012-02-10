//
//  PSYouTubeView.h
//  PSYouTubeExtractor
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

/// Uses MPMoviePlayerController whenever possible, else falls back to the UIWebView YouTube plugin.
/// Note: The YouTube plugin doesn't show up in the Simulator. Test on the device!
@interface PSYouTubeView : UIView

/// Init with YouTube URL and desired frame.
/// Note: When we have to fall back to UIWebView, the frame cannot be changed later on.
/// Enable showNativeFirst to first show an empty MPMoviePlayerController.
- (id)initWithYouTubeURL:(NSURL *)youTubeURL frame:(CGRect)frame showNativeFirst:(BOOL)showNativeFirst;

/// Access the original YouTube URL (e.g. http://www.youtube.com/watch?v=Vo0Cazxj_yc)
@property(nonatomic, strong, readonly) NSURL *youTubeURL;

/// Raw mp4 URL, if it could be extracted.
@property(nonatomic, strong, readonly) NSURL *youTubeMovieURL;

/// Set if extracting the YouTube mp4 fails.
@property(nonatomic, strong, readonly) NSError *error;

/// YES if MPMoviePlayerController is used. NO if we had to fallback to UIWebView.
@property(nonatomic, assign, readonly, getter=isNativeView) BOOL nativeView;

/// Animates view changes. Defaults to YES. Fades windows on a change.
@property(nonatomic, assign, getter=isAnimated) BOOL animated;


/// Is called initially, and once if a MP4 is found. Default implementation is provided.
@property(nonatomic, strong) void (^setupNativeView)(void);

/// Used in the default implementation.
@property (nonatomic, strong) MPMoviePlayerController *moviePlayerController;


// Called only if MP4 could not be found. Default implementation is provided.
@property(nonatomic, strong) void (^setupWebView)(void);

/// Used in the default implementation.
@property (nonatomic, strong) UIWebView *webView;

@end
