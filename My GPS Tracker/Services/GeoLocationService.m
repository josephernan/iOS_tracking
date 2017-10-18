//
//  GeoLocationService.m
//  My GPS Tracker
//
//  Created by Derk Humblet on 11/06/16.
//  Copyright © 2016 mygpstracker. All rights reserved.
//

#import "GeoLocationService.h"

@interface GeoLocationService()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@end

@implementation GeoLocationService

- (id)init {
    if (self = [super init]) {
        if (nil == self.lastPosition) { self.lastPosition = [GeoInfo new]; }
        if (nil == self.locationManager) { self.locationManager = [CLLocationManager new]; }
        if (nil == self.geocoder) { self.geocoder = [[CLGeocoder alloc] init]; }
        
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 300; // meters
        
#if !(DISABLE_PERMISSION_ALERTS)
        __weak typeof(self) wself = self;
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC));
        
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            if ([wself.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [wself.locationManager requestWhenInUseAuthorization];
            }
            
            if ([CLLocationManager locationServicesEnabled]) {
                [wself.locationManager startMonitoringSignificantLocationChanges];
                [wself.locationManager startUpdatingLocation];
            }
        });
#endif
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* location = [locations lastObject];
    
    self.lastPosition.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    self.lastPosition.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    
    [self.geocoder reverseGeocodeLocation:location
                        completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                            CLPlacemark *placemark = [placemarks lastObject];
                            if (placemark) {
                                self.lastPosition.country_code2 = placemark.ISOcountryCode;
                                self.lastPosition.postalcode = placemark.postalCode;
                                self.lastPosition.city_name = placemark.locality;
                                self.lastPosition.street_name = placemark.thoroughfare;
                            }
                        }];
}


@end
