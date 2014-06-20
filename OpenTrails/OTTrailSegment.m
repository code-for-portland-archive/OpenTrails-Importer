//
//  OTTrailSegment.m
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

#import "OTTrailSegment.h"

OTTrailPolicy OTTrailPolicyFromString(NSString *aString) {
    
    OTTrailPolicy policy;
    
    if ( [aString isEqualToString:@"yes"] ) {
        policy = OTTrailPolicyAllowed;
    } else if ( [aString isEqualToString:@"no"] ) {
        policy = OTTrailPolicyNotAllowed;
    } else if ( [aString isEqualToString:@"permissive"] ) {
        policy = OTTrailPolicyDesignated;
    } else if ( [aString isEqualToString:@"designated"] ) {
        policy = OTTrailPolicyDesignated;
    } else {
        policy = OTTrailPolicyUnknown;
    }
    
    return policy;
}

@implementation OTTrailSegment

#pragma mark OTTrailSegment

- (instancetype)initWithIdentifier:(NSString *)identifier coordinates:(CLLocationCoordinate2D *)coordinates count:(NSUInteger)count;
{
    NSParameterAssert( [identifier length] > 0 );
    NSParameterAssert( count > 0 );
    
    if ( self = [super init] ) {
        
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:count];
        NSInteger index;
        
        for ( index = 0; index < count; index++ ) {
            CLLocationCoordinate2D coordinate = coordinates[index];
            [array addObject:[NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)]];
        }
        
        _identifier = identifier;
        _coordinates = [array copy];
    }
    
    return self;
}

#pragma mark NSObject

- (NSString *)description;
{
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendFormat:@"<%@: %p, name=%@, coordinates=", NSStringFromClass( [self class] ), self, self.name];
    
    NSInteger index, count = [self.coordinates count];
    
    for ( index = 0; index < count; index++ ) {
        CLLocationCoordinate2D coordinate;
        [self.coordinates[index] getValue:&coordinate];
        [string appendFormat:@"%f %f, ", coordinate.latitude, coordinate.longitude];
    }
    
    [string appendString:@">"];
    return string;
}

@end
