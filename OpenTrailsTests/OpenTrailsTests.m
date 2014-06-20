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

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSDictionary *filePaths;

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
    
    self.filePaths = @{ OTTrailSegmentsFilePathKey : segments,
                        OTNamedTrailsFilePathKey : trails,
                        OTTrailheadsFilePathKey : trailheads,
                        OTAreasFilePathKey : areas,
                        OTStewardsFilePathKey : stewards };
    
    self.operationQueue = [[NSOperationQueue alloc] init];
}

- (void)tearDown;
{
    [super tearDown];
}

- (void)testSomething;
{
    OTImportOperation *operation = [[OTImportOperation alloc] initWithFilePaths:self.filePaths];
    operation.completionBlock = ^(void) {
        
        NSArray *trails = operation.importedTrails;
    };
    
    [self.operationQueue addOperation:operation];
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

@end
