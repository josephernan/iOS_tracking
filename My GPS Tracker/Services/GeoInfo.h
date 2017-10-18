//
//  GeoInfo.h
//  My GPS Tracker
//
//  Created by Derk Humblet on 11/06/16.
//  Copyright © 2016 mygpstracker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeoInfo : NSObject

@property (atomic, strong) NSNumber *longitude;
@property (atomic, strong) NSNumber *latitude;
@property (atomic, strong) NSString *street_name;
@property (atomic, strong) NSString *postalcode;
@property (atomic, strong) NSString *city_name;
@property (atomic, strong) NSString *country_code2;
@property (atomic, strong) NSString *location; // Longitude and latitude seperated by comma

@end
