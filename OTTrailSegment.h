//
//  OTTrailSegment.h
//  OpenTrails Importer
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Marc Charbonneau
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@import Foundation;
@import MapKit;

@class OTSteward;

typedef NS_ENUM( NSUInteger, OTTrailPolicy )
{
    OTTrailPolicyPolicyAllowed,
    OTTrailPolicyPolicyNotAllowed,
    OTTrailPolicyPolicyPermissive,
    OTTrailPolicyPolicyDesignated
};

@interface OTTrailSegment : NSObject

@property (readonly) NSString *identifier;
@property (readonly) NSArray *coordinates;
@property (copy) NSString *name;
@property (copy) NSDictionary *openStreetMapTags;
@property (strong) OTSteward *steward;
@property (assign) OTTrailPolicy motorVehiclePolicy;
@property (assign) OTTrailPolicy footTrafficPolicy;
@property (assign) OTTrailPolicy bicyclePolicy;
@property (assign) OTTrailPolicy horsePolicy;
@property (assign) OTTrailPolicy skiPolicy;
@property (assign) OTTrailPolicy wheelchairPolicy;

- (instancetype)initWithIdentifier:(NSString *)identifier coordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count;

@end
