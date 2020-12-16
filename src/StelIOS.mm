/*
 * Stellarium
 * Copyright (C) 2013 Guillaume Chereau
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA  02110-1335, USA.
 */

#include "StelIOS.hpp"
#include <QDebug>
#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject <CLLocationManagerDelegate>
{
@public
	CLLocationManager *locationManager;
}
@end

@implementation LocationManager

- (id)init
{
	self = [super init];
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.distanceFilter = kCLDistanceFilterNone;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	return self;
}

- (void)start
{
	[locationManager startUpdatingLocation];
}

- (void)stop
{
	[locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	qDebug() << "GPS updateLocation";
	if (StelIOS::GPSCallback)
		StelIOS::GPSCallback(newLocation.coordinate.latitude,
		                     newLocation.coordinate.longitude,
		                     newLocation.altitude,
		                     newLocation.horizontalAccuracy);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	NSLog(@"Location got new authorisation status: %d", status);
	/*
	if (status == kCLAuthorizationStatusDenied)
		XXX do something.
	if (status == kCLAuthorizationStatusAuthorized)
		XXX do something.
	*/
}

@end

static LocationManager *locationManager = NULL;

void (*StelIOS::GPSCallback)(double, double, double, double) = NULL;


void StelIOS::setGPSCallback(void (*callback)(double, double, double, double))
{
	StelIOS::GPSCallback = callback;
	if (locationManager == NULL)
	{
		locationManager = [[LocationManager alloc] init];
	}
	if (callback)
		[locationManager start];
	else
		[locationManager stop];
}

