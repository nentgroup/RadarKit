//
//  Probe.m
//  RadarKit
//
//  Created by Jacob Wan on 2015-03-27.
//  Copyright (c) 2015 Cedexis. All rights reserved.
//

#import "CDXProbe.h"
#import "CDXLogger.h"

@implementation CDXProbe

-(id)initWithUrl:(NSString *)url
         session:(CDXRadarSession *)session
         probeId:(int)probeId
      objectType:(int)objectType
     ownerZoneId:(int)ownerZoneId
 ownerCustomerId:(int)ownerCustomerId
      providerId:(int)providerId
{
    if (self = [super init]) {
        _url = url;
        _session = session;
        _probeId = probeId;
        _objectType = objectType;
        _ownerZoneId = ownerZoneId;
        _ownerCustomerId = ownerCustomerId;
        _providerId = providerId;
    }
    return self;
}

-(NSString *)probeUrl {
    return [NSString
        stringWithFormat:@"%@?rnd=%d-%d-%d-%d-%d-%d-%lu-%@",
        self.url,
        self.probeId,
        self.session.radar.zoneId,
        self.session.radar.customerId,
        self.ownerZoneId,
        self.ownerCustomerId,
        self.providerId,
        self.session.transactionId,
        self.session.requestSignature
    ];
}

-(void)measureWithCompletionHandler:(void(^)(NSError *))handler {
    
    NSString * probeUrl = self.probeUrl;
    [[CDXLogger sharedInstance] log:[NSString stringWithFormat:@"Probe URL: %@", probeUrl]];
    NSURL * url = [NSURL URLWithString:probeUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
        cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
    timeoutInterval:20.0 ];
    
    NSDate *start = [NSDate date];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self reportResult:4 Measurement:0 completionHandler:^(NSError *errorAtReport) {
                        handler(error);
                    }];
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (!data || 200 != httpResponse.statusCode) {
            error = [NSError errorWithDomain:@"RadarKit" code:httpResponse.statusCode userInfo:@{ data: data }];
            [self reportResult:4 Measurement:0 completionHandler:^(NSError *errorAtReport) {
                        handler(error);
                    }];
            return;
        }
        NSDate *end = [NSDate date];
        int elapsed = 1000 * [end timeIntervalSinceDate:start];
        [[CDXLogger sharedInstance] log:[NSString stringWithFormat:@"Elapsed: %ld", (long)elapsed]];
        if (elapsed >= 4000) {
            [self reportResult:1 Measurement:0 completionHandler:handler];
        }
        int measurement = elapsed;
        if (14 == self.probeId) {
            NSRegularExpression * expr = [NSRegularExpression regularExpressionWithPattern:@"(\\d+)kb\\." options:NSRegularExpressionCaseInsensitive error:&error];
            NSRange searchedRange = NSMakeRange(0, [self.url length]);
            NSArray *matches = [expr matchesInString:self.url options:0 range:searchedRange];
            NSTextCheckingResult * match = [matches objectAtIndex:0];
            NSRange group1 = [match rangeAtIndex:1];
            NSString * fileSize = [self.url substringWithRange:group1];
            int fileSizeHint = [fileSize intValue];
            measurement = 8 * 1000 * fileSizeHint / elapsed;
            [[CDXLogger sharedInstance] log:[NSString stringWithFormat:@"Throughput: %d", measurement]];
        }
        [self reportResult:0 Measurement:measurement completionHandler:handler];
    }];
    [task resume];
}

/**
 *  Builds a URL that can be used for reporting a measurement
 *
 *  @param result      Measurement result code
 *  @param measurement Throughput measured
 *
 *  @return The URL as NSString
 */
-(NSString *)reportUrlForResult:(int)result measurement:(int)measurement {
    return [NSString
        stringWithFormat:@"http://rpt.cedexis.com/f1/%@/%d/%d/%d/%d/%d/%d/1/0",
        self.session.requestSignature,
        self.ownerZoneId,
        self.ownerCustomerId,
        self.providerId,
        self.probeId,
        result,
        measurement
    ];
}

/**
 *  Reports the result of a measurement
 *
 *  @param result      Measurement result code
 *  @param measurement Throughput measured
 *  @param handler     Callback block
 */
-(void)reportResult:(int)result
        Measurement:(int)measurement
  completionHandler:(void(^)(NSError *error))handler {
    
    NSString * reportUrl = [self reportUrlForResult:result measurement:measurement];
    [[CDXLogger sharedInstance] log:[NSString stringWithFormat:@"Report URL: %@", reportUrl]];
    
    NSURL * url = [NSURL URLWithString:reportUrl];
    NSURLRequest * request = [NSURLRequest
        requestWithURL:url
           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
       timeoutInterval:6.0 ];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (!data || (200 != httpResponse.statusCode)) {
                error = [NSError errorWithDomain:@"RadarKit" code:httpResponse.statusCode userInfo:@{ data: data }];
            }
        }
        if (handler) {
            handler(error);
        }
    }];
    [task resume];
}

@end
