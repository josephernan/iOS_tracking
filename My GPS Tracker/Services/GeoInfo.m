//
//  GeoInfo.m
//  My GPS Tracker
//
//  Created by Derk Humblet on 11/06/16.
//  Copyright © 2016 mygpstracker. All rights reserved.
//

#import "GeoInfo.h"

@implementation GeoInfo

-(id)copyWithZone:(NSZone *)zone {
    GeoInfo *other = [[GeoInfo alloc] init];
    other.longitude = [self.longitude copyWithZone:zone];
    other.latitude = [self.latitude copyWithZone:zone];
    other.street_name = [self.street_name copyWithZone:zone];
    other.postalcode = [self.postalcode copyWithZone:zone];
    other.city_name = [self.city_name copyWithZone:zone];
    other.country_code2 = [self.country_code2 copyWithZone:zone];
    other.location = [self.location copyWithZone:zone];
    
    return other;
}

@end
