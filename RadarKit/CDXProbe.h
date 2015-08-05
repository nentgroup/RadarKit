//
//  Probe.h
//  RadarKit
//
//  Created by Jacob Wan on 2015-03-27.
//  Copyright (c) 2015 Cedexis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDXRadarSession.h"

@interface CDXProbe : NSObject

-(id)initWithUrl:(NSString *)url
         process:(CDXRadarSession *)process
         probeId:(int)probeId
      objectType:(int)objectType
     ownerZoneId:(int)ownerZoneId
 ownerCustomerId:(int)ownerCustomerId
      providerId:(int)providerId;

-(void)measureWithCompletionHandler:(void(^)(NSError *error))handler;

@property NSString * url;
@property CDXRadarSession *process;
@property int probeId;
@property int objectType;
@property int ownerZoneId;
@property int ownerCustomerId;
@property int providerId;

@end
