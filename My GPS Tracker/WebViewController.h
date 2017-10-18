//
//  WebViewController.h
//  My GPS Tracker
//
//  Created by Derk Humblet on 11/06/16.
//  Copyright © 2016 mygpstracker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Firebase/Firebase.h>

@interface WebViewController : UIViewController<UIWebViewDelegate, CLLocationManagerDelegate>

- (void)evalJs:(NSString*)request;

@end
