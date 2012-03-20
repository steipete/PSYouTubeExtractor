//
//  PSYouTubeExtractor.m
//  PSYouTubeExtractor
//
//  Created by Peter Steinberger on 2/9/12.
//  Copyright (c) 2012 Peter Steinberger. All rights reserved.
//

#import "PSYouTubeExtractor.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface PSYouTubeExtractor() <UIWebViewDelegate> {
    BOOL testedDOM_;
    NSUInteger retryCount_;
    NSInteger  domWaitCounter_;
    UIWebView *webView_;
    NSURLRequest *lastRequest_;
    PSYouTubeExtractor *selfReference_;
    void (^successBlock_) (NSURL *URL);
    void (^failureBlock_) (NSError *error);
}
- (void)DOMLoaded_;
- (void)cleanup_;
- (BOOL)doRetry_;
@end

@implementation PSYouTubeExtractor

@synthesize youTubeURL = youTubeURL_;

#define kMaxNumberOfRetries 2 // numbers of retries
#define kWatchdogDelay 5.f    // seconds we wait for the DOM
#define kExtraDOMDelay 3.f    // if DOM doesn't load, wait for some extra time

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
        PSLog(@"Starting YouTube extractor for %@", youTubeURL);
        [self doRetry_];
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    successBlock_ = nil;
    failureBlock_ = nil;
    selfReference_ = nil;    
    [webView_ stopLoading];
    webView_.delegate = nil;
    webView_ = nil;
    retryCount_ = 0;
    domWaitCounter_ = 0;
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
    // stop if we don't have a selfReference. (cleanup was called)
    if (selfReference_ && (retryCount_ <= kMaxNumberOfRetries + 1)) {
        retryCount_++;
        domWaitCounter_ = 0;
        PSLog(@"Trying to load page...");
        webView_.delegate = nil;
        webView_ = [[UIWebView alloc] init];
        webView_.delegate = self;

        // we fake an old version of the iOS browser to get a correct response.
        // else request does seem to fail on iOS 5 upwards unless we're on an actual iPhone device. Weird.
        //NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7A341 Safari/528.16", @"UserAgent", nil];
        //[[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        
        [webView_ loadRequest:[NSURLRequest requestWithURL:youTubeURL_]];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        return YES;
    }
    return NO;
}

- (void)DOMLoaded_ {
    // ugly hack to see what's going on.
    //[[[[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController] view] addSubview:webView_];
    //webView_.frame = [UIScreen mainScreen].bounds;
    
    // figure out if we can extract the youtube url!
    NSString *youTubeMP4URL = [webView_ stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('video')[0].getAttribute('src')"];
    PSLog(@"testing dom. query: %@", youTubeMP4URL);
    
    if ([youTubeMP4URL hasPrefix:@"http"]) {
        // probably ok
        if (successBlock_) {
            NSURL *URL = [NSURL URLWithString:youTubeMP4URL];
            successBlock_(URL);
        }
        [self cleanup_];
    }else {
        if (domWaitCounter_ < kExtraDOMDelay * 4) {
            domWaitCounter_++;
            [self performSelector:@selector(DOMLoaded_) withObject:nil afterDelay:0.25f]; // try often!
            return;
        }
        
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
    
    /*
    // we fake an old version of the iOS browser to get a correct response.
    // else request does seem to fail on iOS 5 upwards unless we're on an actual iPhone device. Weird.
    NSMutableURLRequest *request = (NSMutableURLRequest *)aRequest;
    if ([request respondsToSelector:@selector(setValue:forHTTPHeaderField:)]) {
        [request setValue:@"Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_0 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7A341 Safari/528.16" forHTTPHeaderField:@"User-Agent"];
    }*/
    
	// Check for DOM load message
	if ([scheme isEqualToString:@"x-sswebview"]) {
		NSString *host = [url host];
		if ([host isEqualToString:@"dom-loaded"]) {
            PSLog(@"DOM load detected!");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self DOMLoaded_];
            });
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
    if (!selfReference_) {
        return;
    }
    
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(DOMLoaded_) object:nil];
    [self performSelector:@selector(DOMLoaded_) withObject:nil afterDelay:kWatchdogDelay];
}

- (void)DOMFailed_:(NSError *)error {
    if (![self doRetry_]) {
        if (failureBlock_) {
            failureBlock_(error);
        }
        [self cleanup_];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (!selfReference_) {
        return;
    }
    
    NSURL *errorURL = [error.userInfo objectForKey:@"NSErrorFailingURLKey"];
    if ([[errorURL absoluteString] rangeOfString:@"poswidget"].length) {
        PSLog(@"ignoring error: %@", error);
        return; // ignore those errors
    }
    
    PSLog(@"didFailLoadWithError: %@", error);
    
    // give system a little bit more time, may be an irrelevant error
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(DOMFailed_:) withObject:error afterDelay:kWatchdogDelay/3];
}

@end

