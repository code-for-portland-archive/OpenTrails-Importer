//
//  OpenTrailsTests.m
//  OpenTrailsTests
//
//  Created by mbcharbonneau on 6/20/14.
//  Copyright (c) 2014 Code for Portland. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OTOpenTrails.h"
#import "OTImportOperation.h"

@interface OpenTrailsTests : XCTestCase

@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSArray *trails;

@end

@implementation OpenTrailsTests

- (void)setUp;
{
    [super setUp];

    NSBundle *testsBundle = [NSBundle bundleForClass:[self class]];
    NSString *areas = [testsBundle pathForResource:@"areas" ofType:@"geojson"];
    NSString *trails = [testsBundle pathForResource:@"named_trails" ofType:@"csv"];
    NSString *stewards = [testsBundle pathForResource:@"stewards" ofType:@"csv"];
    NSString *segments = [testsBundle pathForResource:@"trail_segments" ofType:@"geojson"];
    NSString *trailheads = [testsBundle pathForResource:@"trailheads" ofType:@"geojson"];
    
    NSDictionary *filePaths = @{ OTTrailSegmentsFilePathKey : segments,
                                 OTNamedTrailsFilePathKey : trails,
                                 OTTrailheadsFilePathKey : trailheads,
                                 OTAreasFilePathKey : areas,
                                 OTStewardsFilePathKey : stewards };
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    OTImportOperation *operation = [[OTImportOperation alloc] initWithFilePaths:filePaths];
    __weak __typeof(operation) weakOperation = operation;
    
    operation.completionBlock = ^(void) {
        
        self.error = weakOperation.error;
        self.trails = weakOperation.importedTrails;
    };
    
    [queue addOperation:operation];
    [queue waitUntilAllOperationsAreFinished];
}

- (void)tearDown;
{
    [super tearDown];
    
    self.error = nil;
    self.trails = nil;
}

- (void)testSuccess;
{
    XCTAssertNil( self.error, @"import error is not nil: %@", self.error );
    XCTAssertNotEqual( [self.trails count], 0, @"trails array is empty or nil" );
}

- (void)testImportedData;
{
    NSString *name = @"Springwater On The Willamette Art Loop";
    NSPredicate *trailFilter = [NSPredicate predicateWithFormat:@"name == %@", name];
    NSArray *result = [self.trails filteredArrayUsingPredicate:trailFilter];
    
    XCTAssertEqual( [result count], 1 );
    
    OTTrail *trail = [result firstObject];
    
    XCTAssertTrue( [trail.name isEqualToString:name] );
    XCTAssertTrue( [trail.identifier isEqualToString:@"171296"] );
    XCTAssertEqual( [trail.segments count], 2 );
    
    NSString *segmentID = @"169761";
    NSPredicate *segmentFilter = [NSPredicate predicateWithFormat:@"identifier == %@", segmentID];
    OTTrailSegment *segment = [[trail.segments filteredArrayUsingPredicate:segmentFilter] lastObject];
    
    XCTAssertTrue( segment != nil );
    XCTAssertTrue( [segment.steward.name isEqualToString:@"Portland Parks and Recreation"] );
    
    CLLocationCoordinate2D coordinate;
    [segment.coordinates[0] getValue:&coordinate];
    
    XCTAssertEqualWithAccuracy( coordinate.longitude, -122.659661018644, 0.00005 );
    XCTAssertEqualWithAccuracy( coordinate.latitude, 45.4961599218161, 0.00005 );
    
    NSInteger lastIndex = [segment.coordinates count] - 1;
    [segment.coordinates[lastIndex] getValue:&coordinate];

    XCTAssertEqualWithAccuracy( coordinate.longitude, -122.659549669935, 0.00005 );
    XCTAssertEqualWithAccuracy( coordinate.latitude, 45.4955615181693, 0.00005 );
}

@end
