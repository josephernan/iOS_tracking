//
//  GeoLocationService.h
//  My GPS Tracker
//
//  Created by Derk Humblet on 11/06/16.
//  Copyright © 2016 mygpstracker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "GeoInfo.h"

@interface GeoLocationService : NSObject<CLLocationManagerDelegate>

@property (atomic, strong) GeoInfo *lastPosition;

@end
