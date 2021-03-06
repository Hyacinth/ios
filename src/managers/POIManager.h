//
//  POIManager.h
//  CycleStreets
//
//  Created by Neil Edwards on 21/10/2011.
//  Copyright (c) 2011 CycleStreets Ltd. All rights reserved.
//

#import "FrameworkObject.h"
#import "SynthesizeSingleton.h"
#import "POICategoryVO.h"
#import <CoreLocation/CoreLocation.h>

#define LOCATIONRADIUS 5
#define LOCATIONRESULTSLIMIT 20

@interface POIManager : FrameworkObject{
	
	NSMutableArray				*dataProvider;  // list of all categories
	NSMutableArray				*categoryDataProvider; // list of locations in category from current location
	
}
SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(POIManager)

@property (nonatomic, strong)	NSMutableArray		*dataProvider;
@property (nonatomic, strong)	NSMutableArray		*categoryDataProvider;

-(void)requestPOIListingData;
-(void)requestPOICategoryDataForCategory:(POICategoryVO*)category atLocation:(CLLocationCoordinate2D)location;

@end
