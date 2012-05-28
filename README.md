## PSYouTubeExtractor ("BetterYouTube")

*Edit: This was a nice experiment, but there's now a better solution that doesn't involve UIWebViews: https://github.com/larcus94/LBYouTubeView*


Displaying YouTube is a pain in the ass. This class makes it a lot more bearable by trying to extract the native mp4 when available. If that doesn't work, we fall back to the UIWebView YouTube plugin.

There are two classes available:

### PSYouTubeExtractor

Does some crazy things behind the scenes and extracts the mp4 of a YouTube video. I use an UIWebView to get the data, as Google does a pretty good job of obfuscating their html content. 

        [PSYouTubeExtractor extractorForYouTubeURL:self.youTubeURL success:^(NSURL *URL) {
            NSLog(@"Finished extracting: %@", URL);
			// show the movie!
        } failure:^(NSError *error) {
            NSLog(@"Failed to query mp4: %@", error);
        }];

Note that PSYouTubeExtractor is *not* a NSOperation, as there's some craziness behind the scenes that needs a RunLoop (and I don't wanna mess around with runloops in NSOperation). The class retains itself until either success or failure is called, or until you send cancel to it. The blocks are nullified afterwards, so don't worry about retain cycles. (You still have to worry about Xcode bit chin' about it.)

### PSYouTubeView

Woohoo! That's where the awesomeness is. Just use this instead of your UIWebView and you're good.

    NSURL *youTubeURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=Vo0Cazxj_yc"];  
  
    PSYouTubeView *youTubeView = [[PSYouTubeView alloc] initWithYouTubeURL:youTubeURL
                                                                     frame:CGRectMake(0,0,200,200)
                                                           showNativeFirst:YES];
    [self.view addSubview:youTubeView];

Note that you should set the correct frame right away. If we need to fallback to UIWebView, the YouTube plugin can't resize. (You can recreate it, but that would kill a running video). However, in most cases it should extract the mp4 successfully and you don't need to worry about that crap.

The setting 'showNativeFirst' decides if you want to start with a MPMoviePlayerController or a UIWebView. As we are optimistic, I suggest you set this to YES per default.

I am using this class for [PSPDFKit](http://pspdfkit.com), my pdf framework where you can add interactive elements, and YouTube just sucked too much, so I wrote this helper. That's also why there is a block for "setupNativeView" and "setupWebView", you can override those and do your own custom stuff with it.

### ARC
… what else? Also should work with iOS 4.0 upwards. Tested with iOS 4.3 and 5.0.

### Help wanted!

If anyone has a better way of extracting the final YouTube mp4 url (maybe some crazy regex magic), it would make the class a lot faster (we could get rid of the UIWebView). I am kinda ok with the UIWebView solution though, as this one will be pretty robust. I look for a <video> tag, and as long as Google shows a video on a YouTube page, we find the source.

Also, we could add support for Reachability to re-try the extracting in case we didn't had network when the view was created. Feel free to send a pull request!

PS: If you like this stuff, [you should follow me on Twitter!](http://twitter.com/steipete)


### License

MIT! See LICENSE file for the legal stuff.