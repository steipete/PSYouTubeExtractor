//
//  PSYouTubeExtractor.m
//  PSYouTubeExtractor
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import "PSYouTubeExtractor.h"
#import <UIKit/UIKit.h>

@interface PSYouTubeExtractor() <UIWebViewDelegate> {
    BOOL testedDOM_;
    NSUInteger retryCount_;
    UIWebView *webView_;
    NSURLRequest *lastRequest_;
    PSYouTubeExtractor *selfReference_;
    void (^successBlock_) (NSURL *URL);
    void (^failureBlock_) (NSError *error);
}
- (void)DOMLoaded_;
- (void)cleanup_;
@end

@implementation PSYouTubeExtractor

@synthesize youTubeURL = youTubeURL_;

#define kMaxNumberOfRetries 3 // numbers of retries
#define kWatchdogDelay 0.7f   // seconds we wait for the DOM

// uncomment to enable logging
#define PSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#define PSLog(fmt, ...) 

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithYouTubeURL:(NSURL *)youTubeURL success:(void(^)(NSURL *URL))success failure:(void(^)(NSError *error))failure {
    if ((self = [super init])) {
        successBlock_ = success;
        failureBlock_ = failure;
        youTubeURL_ = youTubeURL;
        selfReference_ = self; // retain while running!
        webView_ = [[UIWebView alloc] init];
        webView_.delegate = self;
        [webView_ loadRequest:[NSURLRequest requestWithURL:youTubeURL]];
        PSLog(@"Starting YouTube extractor for %@", youTubeURL);
    }
    return self;
}

- (void)dealloc {
    [self cleanup_];
    webView_.delegate = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static

+ (PSYouTubeExtractor *)extractorForYouTubeURL:(NSURL *)youTubeURL success:(void(^)(NSURL *URL))success failure:(void(^)(NSError *error))failure {
    PSYouTubeExtractor *extractor = [[PSYouTubeExtractor alloc] initWithYouTubeURL:youTubeURL success:success failure:failure];
    return extractor;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)cleanup_ {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(DOMLoaded_) object:nil]; // cancel watchdog
    successBlock_ = nil;
    failureBlock_ = nil;
    selfReference_ = nil;    
    [webView_ stopLoading];
}

- (BOOL)cancel {
    PSLog(@"Cancel called.");
    if (selfReference_) {
        [self cleanup_];
        return YES;
    }
    return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

// very possible that the DOM isn't really loaded after all or sth failed. Try to load website again.
- (BOOL)doRetry_ {
    if (retryCount_ <= kMaxNumberOfRetries) {
        retryCount_++;
        PSLog(@"Trying again to load page...");
        [webView_ loadRequest:[NSURLRequest requestWithURL:lastRequest_.URL]];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(DOMLoaded_) object:nil];
        return YES;
    }
    return NO;
}

- (void)DOMLoaded_ {
    PSLog(@"DOMLoaded_ / watchdog hit");
    
    // figure out if we can extract the youtube url!
    NSString *youTubeMP4URL = [webView_ stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('video')[0].getAttribute('src')"];
    
    if ([youTubeMP4URL hasPrefix:@"http"]) {
        // probably ok
        if (successBlock_) {
            NSURL *URL = [NSURL URLWithString:youTubeMP4URL];
            successBlock_(URL);
        }
        [self cleanup_];
    }else {
        if (![self doRetry_]) {
            NSError *error = [NSError errorWithDomain:@"com.petersteinberger.betteryoutube" code:100 userInfo:[NSDictionary dictionaryWithObject:@"MP4 URL could not be found." forKey:NSLocalizedDescriptionKey]];
            if (failureBlock_) {
                failureBlock_(error);
            }
            [self cleanup_];
        }
    }    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType {
	BOOL should = YES;
	NSURL *url = [aRequest URL];
	NSString *scheme = [url scheme];
    
	// Check for DOM load message
	if ([scheme isEqualToString:@"x-sswebview"]) {
		NSString *host = [url host];
		if ([host isEqualToString:@"dom-loaded"]) {
            PSLog(@"DOM load detected!");
			[self DOMLoaded_];
		}
		return NO;
	}
    
	// Only load http or http requests if delegate doesn't care
	else {
		should = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
	}
    
	// Stop if we shouldn't load it
	if (should == NO) {
		return NO;
	}
    
	// Starting a new request
	if ([[aRequest mainDocumentURL] isEqual:[lastRequest_ mainDocumentURL]] == NO) {
		lastRequest_ = aRequest;
		testedDOM_ = NO;
	}
    
	return should;
}

// With some guidance of SSToolKit this was pretty easy. Thanks Sam!
- (void)webViewDidFinishLoad:(UIWebView *)webView {
     PSLog(@"webViewDidFinishLoad");
    
	// Check DOM
	if (testedDOM_ == NO) {
		testedDOM_ = YES;
        
        // The internal delegate will intercept this load and forward the event to the real delegate
        // Crazy javascript from http://dean.edwards.name/weblog/2006/06/again
		static NSString *testDOM = @"var _SSWebViewDOMLoadTimer=setInterval(function(){if(/loaded|complete/.test(document.readyState)){clearInterval(_SSWebViewDOMLoadTimer);location.href='x-sswebview://dom-loaded'}},10);";
		[webView_ stringByEvaluatingJavaScriptFromString:testDOM];        
	}
    
    // add watchdog in case DOM never get initialized
    [self performSelector:@selector(DOMLoaded_) withObject:nil afterDelay:kWatchdogDelay];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    PSLog(@"didFailLoadWithError");
    
    if (![self doRetry_]) {
        if (failureBlock_) {
            failureBlock_(error);
        }
        [self cleanup_];
    }
}

@end
