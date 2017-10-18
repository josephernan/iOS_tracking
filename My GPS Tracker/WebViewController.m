//
//  WebViewController.m
//  My GPS Tracker
//
//  Created by Derk Humblet on 11/06/16.
//  Copyright © 2016 mygpstracker. All rights reserved.
//

#import "WebViewController.h"
#import "Reachability.h"
#import <KVNProgress/KVNProgress.h>

@interface WebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property Reachability *internetReachable;
@property CLLocationManager *locationManager;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureLocation];
    [self configureReachability];
    [self loadWebView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark Configurations

- (void)evalJs:(NSString*)request {
    [self.webView stringByEvaluatingJavaScriptFromString:request];
}

- (void)handleJSCall:(NSString*)request {
    NSArray *reqArray = [request componentsSeparatedByString:@"/"];
    if (reqArray.count >= 3) {
        NSString *cmd = [reqArray objectAtIndex:2];
        
        if ([cmd isEqualToString:@"getToken"]) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSString *token = [prefs stringForKey:@"FIREBASE_FCM_TOKEN"];
            NSString *jscall = [NSString stringWithFormat:@"mygps_appRegisterToken(\"%@\", \"IOS\");", token];
            [self.webView stringByEvaluatingJavaScriptFromString:jscall];
        } else if ([cmd isEqualToString:@"handleStartConfig"]) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            long eventId = [prefs integerForKey:@"FIREBASE_FCM_EVENT_ID"];
            NSString *jscall;
            if (eventId > 0) {
                jscall = [NSString stringWithFormat:@"eventsShowEvent(%ld);", eventId];
            } else if (eventId == -1) {
                jscall = [NSString stringWithFormat:@"eventLoadList();switchPage('events');"];
            }
            [self.webView stringByEvaluatingJavaScriptFromString:jscall];

            [prefs removeObjectForKey:@"FIREBASE_FCM_EVENT_ID"];
            [prefs synchronize];
        } else if ([cmd isEqualToString:@"resetToken"]) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSString *token = [prefs stringForKey:@"FIREBASE_FCM_TOKEN"];
            NSString *loginUrl = [reqArray objectAtIndex:3];
            loginUrl = [loginUrl stringByReplacingOccurrencesOfString:@"~~" withString:@"/"];
            loginUrl = [loginUrl stringByAppendingString:@"/mobile"];
            NSString *jscall = [NSString stringWithFormat:@"mygps_appResetToken(\"%@\", function(){window.open(\"%@\", '_self', false);});", token, loginUrl];
            [self.webView stringByEvaluatingJavaScriptFromString:jscall];
        }
    }
}

- (void)configureLocation {
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
}

- (void)configureReachability {
    self.internetReachable = [Reachability reachabilityWithHostname:@"www.mygpstracker.nl"];
    __weak WebViewController *weakSelf = self;
    self.internetReachable.reachableBlock = ^(Reachability *reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadWebView];
        });
    };
    
    // Internet is not reachable
    self.internetReachable.unreachableBlock = ^(Reachability *reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KVNProgress setConfiguration:[KVNProgressConfiguration defaultConfiguration]];
            [[KVNProgress configuration] setFullScreen:NO];
            [[KVNProgress configuration] setCircleStrokeForegroundColor:[UIColor redColor]];
            [[KVNProgress configuration] setSuccessColor:[UIColor redColor]];
            [[KVNProgress configuration] setBackgroundFillColor:[UIColor whiteColor]];
            [[KVNProgress configuration] setBackgroundType:KVNProgressBackgroundTypeSolid];
            [[KVNProgress configuration] setMinimumDisplayTime:5];
            [KVNProgress showErrorWithStatus:@"Cannot load mobile portal.\nDo you have a working internet connection?\nOr try again later..."];
            [weakSelf loadEmptyWebView];
        });
    };
    
    [self.internetReachable startNotifier];
}

#pragma mark WebView

- (void)loadWebView {
    //NSURL *url = [AppConfig getUrl];
    NSString *urlString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"PORTAL_URL"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
    self.webView.scrollView.bounces = NO;
    self.webView.delegate = self;
}

- (void)loadEmptyWebView {
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:@""]];
    [self.webView loadRequest:requestObj];
    self.webView.delegate = self;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    NSString *portalUrl = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"PORTAL_URL"];
    NSLog(@"abs url %@ %@", url.absoluteString, portalUrl);
    if (navigationType == UIWebViewNavigationTypeLinkClicked && ![url.absoluteString hasPrefix:portalUrl]) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    } else if ([[url scheme] isEqualToString:@"appinterface"]) {
        [self handleJSCall:url.absoluteString];
    }
    return YES;
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError*)error {
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
}


@end
