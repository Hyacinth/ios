//
//  RouteModel.m
//  CycleStreets
//
//  Created by neil on 22/03/2011.
//  Copyright 2011 CycleStreets Ltd. All rights reserved.
//

#import "RouteManager.h"
#import "Query.h"
#import "XMLRequest.h"
#import "Route.h"
#import "GlobalUtilities.h"
#import "CycleStreets.h"
#import "AppConstants.h"
#import "Files.h"
#import "RouteParser.h"
#import "HudManager.h"
#import "FavouritesManager.h"
#import "ValidationVO.h"

@interface RouteManager(Private) 

- (void)warnOnFirstRoute;

- (void) querySuccess:(XMLRequest *)request results:(NSDictionary *)elements;
- (void) queryRouteSuccess:(XMLRequest *)request results:(NSDictionary *)elements;

- (void) queryFailure:(XMLRequest *)request message:(NSString *)message;

(void)loadRouteForEndPointsResponse:(ValidationVO*)validation;
-(void)loadRouteForRouteIdResponse:(ValidationVO*)validation;


@end

static NSString *layer = @"6";
static NSString *useDom = @"1";


@implementation RouteManager
SYNTHESIZE_SINGLETON_FOR_CLASS(RouteManager);
@synthesize routes;
@synthesize selectedRoute;

//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [routes release], routes = nil;
    [selectedRoute release], selectedRoute = nil;
	
    [super dealloc];
}




/
/***********************************************
 * @description		NOTIFICATIONS
 ***********************************************/
//

-(void)listNotificationInterests{
	
	
	[super listNotificationInterests];
	
}

-(void)didReceiveNotification:(NSNotification*)notification{
	
	[super didReceiveNotification:notification];
	
	
}




//
/***********************************************
 * @description			NEW NETWORL METHODS
 ***********************************************/
//

-(void)loadRouteForEndPoints:(CLLocation)from to:(CLLocation)to{
    
    
    CycleStreets *cycleStreets = [CycleStreets sharedInstance];
    SettingsVO *settingsdp = [SettingsManager sharedInstance].dataProvider;
    
    NSMutableDictionary *parameters=[NSMutableDictionary dictionaryWithObjectsAndKeys:[CycleStreets sharedInstance].APIKey,@"key",
                                     [NSNumber numberWithFloat:from.longitude],@"start_longitude",
                                     [NSNumber numberWithFloat:from.latitude],@"start_latitude",
                                     [NSNumber numberWithFloat:to.latitude],@"finish_longitude",
                                     [NSNumber numberWithFloat:to.longitude],@"finish_latitude",
                                     layer,@"layer",
                                     @"1",@"useDom",
                                     settingsdp.plan,,@"plan",
                                     [settingsdp returnKilometerSpeedValue],@"speed",
                                     cycleStreets.files.clientid,@"clientid", 
                                     nil];
    
    NetRequest *request=[[NetRequest alloc]init];
    request.dataid=CALCULATEROUTE;
    request.requestid=ZERO;
    request.parameters=parameters;
    request.revisonId=0;
    request.source=USER;
    
    NSDictionary *dict=[[NSDictionary alloc] initWithObjectsAndKeys:request,REQUEST,nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUESTDATAREFRESH object:nil userInfo:dict];
    [dict release];
    [request release];
    
    [[HudManager sharedInstance] showHudWithType:HUDWindowTypeProgress withTitle:@"Obtaining route from CycleStreets.net" andMessage:nil];
    
}



-(void)loadRouteForEndPointsResponse:(ValidationVO*)validation{
    
    
    switch(validation.validationStatus){
        
        case ValidationCalculateRouteSuccess:
            
            self.selectedRoute = [validation.responseDict objectForKey:CALCULATEROUTE];
            
            CycleStreets *cycleStreets = [CycleStreets sharedInstance];
            [cycleStreets.files setRoute:[[selectedRoute itinerary] intValue] data:request.data];
                
            [self warnOnFirstRoute];
            [self selectRoute:selectedRoute];	
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CALCULATEROUTERESPONSE object:nil];
            
            [[HudManager sharedInstance] showHudWithType:HUDWindowTypeSuccess withTitle:@"Found Route, added path to map" andMessage:nil];
        
        break;
            
            
        case ValidationCalculateRouteFailed:
            
            [self queryFailure:nil message:@"Could not plan valid route for selected endpoints."];
            
        break;
        
        
    }
    

    
}


-(void)loadRouteForRouteId:(NSString*)routeid{
    
    
    CycleStreets *cycleStreets = [CycleStreets sharedInstance];
    SettingsVO *settingsdp = [SettingsManager sharedInstance].dataProvider;
    
    NSMutableDictionary *parameters=[NSMutableDictionary dictionaryWithObjectsAndKeys:[CycleStreets sharedInstance].APIKey,@"key",
                                     @"1",@"useDom",
                                     settingsdp.plan,,@"plan",
                                     routeid,@"itinerary",
                                     nil];
    
    NetRequest *request=[[NetRequest alloc]init];
    request.dataid=RETRIEVEROUTEBYID;
    request.requestid=ZERO;
    request.parameters=parameters;
    request.revisonId=0;
    request.source=USER;
    
    NSDictionary *dict=[[NSDictionary alloc] initWithObjectsAndKeys:request,REQUEST,nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUESTDATAREFRESH object:nil userInfo:dict];
    [dict release];
    [request release];

    [[HudManager sharedInstance] showHudWithType:HUDWindowTypeProgress withTitle:[NSString stringWithFormat:@"Searching for route %@ on CycleStreets",query.routeID] andMessage:nil];
}


-(void)loadRouteForRouteIdResponse:(ValidationVO*)validation{
    
    
    switch(validation.validationStatus){
            
        case ValidationRetrieveRouteByIdSuccess:
            
            self.selectedRoute=[validation.responseDict objectForKey:RETRIEVEROUTEBYID];
            
            CycleStreets *cycleStreets = [CycleStreets sharedInstance];
            [cycleStreets.files setRoute:[[selectedRoute itinerary] intValue] data:request.data];
            
            [self selectRoute:selectedRoute];	
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NEWROUTEBYIDRESPONSE object:nil];
            
            [[HudManager sharedInstance] showHudWithType:HUDWindowTypeSuccess withTitle:@"Found Route, this route is now selected." andMessage:nil];
            
            break;
            
            
        case ValidationRetrieveRouteByIdFailed:
            
            [self queryFailure:nil message:@"Unable to find a route with this number."];
            
        break;
            
            
    }
    
    
}


//
/***********************************************
 * @description			OLD NETWORK EVENTS
 ***********************************************/
//
// this functionality can be entirely repalced by standard request/response logic as it is aonly called from
// one place
- (void) runQuery:(Query *)query {
	[query runWithTarget:self onSuccess:@selector(querySuccess:results:) onFailure:@selector(queryFailure:message:)];
	
	[[HudManager sharedInstance] showHudWithType:HUDWindowTypeProgress withTitle:@"Obtaining route from CycleStreets.net" andMessage:nil];

}

- (void) runRouteIdQuery:(Query *)query {
	
	[query runWithTarget:self onSuccess:@selector(queryRouteSuccess:results:) onFailure:@selector(queryRouteFailure:message:)];
	
	
	
	
}


- (void) querySuccess:(XMLRequest *)request results:(NSDictionary *)elements {
	
	//update the table.
	self.selectedRoute = [[Route alloc] initWithElements:elements];
	
	if ([selectedRoute itinerary] == nil) {
		[self queryFailure:nil message:@"Could not plan valid route for selected endpoints."];
	} else {
		
		[[HudManager sharedInstance] showHudWithType:HUDWindowTypeSuccess withTitle:@"Found Route, added path to map" andMessage:nil];
		
		BetterLog(@"");
		//save the route data to file.
		CycleStreets *cycleStreets = [CycleStreets sharedInstance];
		[cycleStreets.files setRoute:[[selectedRoute itinerary] intValue] data:request.data];
		
		[self warnOnFirstRoute];
		[self selectRoute:selectedRoute];		
	}
}


- (void) queryRouteSuccess:(XMLRequest *)request results:(NSDictionary *)elements {
	
	BetterLog(@"");
	
	//update the table.
	self.selectedRoute = [[Route alloc] initWithElements:elements];
	
	if ([selectedRoute itinerary] == nil) {
		[self queryFailure:nil message:@"Unable to find a route with this number."];
	} else {
		
		//save the route data to file.
		CycleStreets *cycleStreets = [CycleStreets sharedInstance];
		[cycleStreets.files setRoute:[[selectedRoute itinerary] intValue] data:request.data];
		
		[self warnOnFirstRoute];
		[self selectRoute:selectedRoute];	
		
		[[NSNotificationCenter defaultCenter] postNotificationName:NEWROUTEBYIDRESPONSE object:nil];
		
		[[HudManager sharedInstance] showHudWithType:HUDWindowTypeSuccess withTitle:@"Found Route, this route is now selected." andMessage:nil];
	}
}

- (void) queryFailure:(XMLRequest *)request message:(NSString *)message {
	[[HudManager sharedInstance] showHudWithType:HUDWindowTypeError withTitle:message andMessage:nil];
}


//
/***********************************************
 * @description			RESEPONSE EVENTS
 ***********************************************/
//

- (void) selectRoute:(Route *)route {
	
	BetterLog(@"");
	
	self.selectedRoute=route;
	
	Files *files=[CycleStreets sharedInstance].files;
	NSArray *oldFavourites = [files favourites];
	NSMutableArray *newFavourites = [[[NSMutableArray alloc] initWithCapacity:[oldFavourites count]+1] autorelease];
	[newFavourites addObjectsFromArray:oldFavourites];
	if ([route itinerary] != nil) {
		[newFavourites removeObject:[route itinerary]];
		[newFavourites insertObject:[route itinerary] atIndex:0];
		[files setMiscValue:[route itinerary] forKey:@"selectedroute"];
	}
	[files setFavourites:newFavourites];
	[[FavouritesManager sharedInstance] update];	
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:CSROUTESELECTED object:[route itinerary]];
	
}

- (void)warnOnFirstRoute {
	
	CycleStreets *cycleStreets = [CycleStreets sharedInstance];
	NSMutableDictionary *misc = [NSMutableDictionary dictionaryWithDictionary:[cycleStreets.files misc]];
	NSString *experienceLevel = [misc objectForKey:@"experienced"];
	
	if (experienceLevel == nil) {
		[misc setObject:@"1" forKey:@"experienced"];
		[cycleStreets.files setMisc:misc];
		
		UIAlertView *firstAlert = [[UIAlertView alloc] initWithTitle:@"Warning"
													 message:@"Route quality cannot be guaranteed. Please proceed at your own risk. Do not use a mobile while cycling."
													delegate:self
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil];
		[firstAlert show];		
		[firstAlert release];
	} else if ([experienceLevel isEqualToString:@"1"]) {
		[misc setObject:@"2" forKey:@"experienced"];
		[cycleStreets.files setMisc:misc];
		
		UIAlertView *optionsAlert = [[UIAlertView alloc] initWithTitle:@"Routing modes"
													   message:@"You can change between fastest / quietest / balanced routing type on the Settings page under 'More', before you plan a route."
													  delegate:self
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
		[optionsAlert show];
		[optionsAlert release];
	}	
	 
}


// loads and selects a route from disk by it's identifier
-(void)loadRouteWithIdentifier:(NSString*)identifier{
	
	Route *route=nil;
	
	if (identifier!=nil) {
		CycleStreets *cycleStreets = [CycleStreets sharedInstance];	
		NSData *data = [cycleStreets.files route:[identifier intValue]];
		if(data!=nil){
			RouteParser *parsed = [RouteParser parse:data forElements:[Route routeXMLElementNames]];
			route = [[[Route alloc] initWithElements:parsed.elementLists] autorelease];
		}
	}
	
	if(route!=nil){
		[self selectRoute:route];
	}
}


// loads the currently saved selectedRoute by identifier
-(void)loadSavedSelectedRoute{
	
	CycleStreets *cycleStreets = [CycleStreets sharedInstance];
	NSString *selectedRouteID = [cycleStreets.files miscValueForKey:@"selectedroute"];
	if(selectedRouteID!=nil)
		[self loadRouteWithIdentifier:selectedRouteID];
	
	
}





@end
