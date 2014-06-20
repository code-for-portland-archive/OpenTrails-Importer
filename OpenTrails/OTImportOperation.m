//
//  OTImportOperation.m
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

#import "OTImportOperation.h"
#import "OTOpenTrails.h"
#import "CHCSVParser.h"

typedef NS_ENUM( NSUInteger, OTImportStage )
{
    OTImportStageNotStarted = 0,
    OTImportStageParsingStewards = 1,
    OTImportStageParsingTrailheads = 2,
    OTImportStageParsingSegments = 3,
    OTImportStageParsingTrails = 4,
    OTImportStageParsingAreas = 5,
    OTImportStageParsingFinished = 6
};

NSString *const OTTrailSegmentsFilePathKey = @"OTTrailSegmentsFilePathKey";
NSString *const OTNamedTrailsFilePathKey = @"OTNamedTrailsFilePathKey";
NSString *const OTTrailheadsFilePathKey = @"OTTrailheadsFilePathKey";
NSString *const OTAreasFilePathKey = @"OTAreasFilePathKey";
NSString *const OTStewardsFilePathKey = @"OTStewardsFilePathKey";
NSString *const OTErrorDomain = @"OTErrorDomain";

@interface OTImportOperation() <CHCSVParserDelegate>

@property (strong) NSDictionary *filePaths;
@property (assign) OTImportStage stage;
@property (strong) NSMutableDictionary *segmentsByIDs;
@property (strong) NSMutableDictionary *trailsByIDs;
@property (strong) NSMutableDictionary *stewardsByIDs;
@property (strong) NSMutableDictionary *csvLineData;

- (void)beginNextTask;
- (void)parseAreas;
- (void)parseTrailheads;
- (void)parseSegments;
- (void)parseTrails;
- (void)parseStewards;
- (void)finishOperation;

- (NSArray *)trailSegmentsMatchingIDs:(NSString *)string;
- (NSArray *)trailsMatchingIDs:(NSString *)string;
- (NSArray *)stewardsMatchingIDs:(NSString *)string;
- (NSDictionary *)splitOSMTagsString:(NSString *)tags;

@end

@implementation OTImportOperation

#pragma mark OTImportOperation

- (instancetype)initWithFilePaths:(NSDictionary *)filePaths;
{
    if ( self = [super init] ) {
        
        _filePaths = filePaths;
        _stage = OTImportStageNotStarted;
        _segmentsByIDs = [NSMutableDictionary new];
        _trailsByIDs = [NSMutableDictionary new];
        _stewardsByIDs = [NSMutableDictionary new];
        _csvLineData = [NSMutableDictionary new];
    }
    
    return self;
}

#pragma mark OTImportOperation Private

- (void)beginNextTask;
{
    switch ( self.stage ) {
        case OTImportStageNotStarted:
            [self parseStewards];
            break;
        case OTImportStageParsingStewards:
            [self parseAreas];
            break;
        case OTImportStageParsingAreas:
            [self parseSegments];
            break;
        case OTImportStageParsingSegments:
            [self parseTrails];
            break;
        case OTImportStageParsingTrails:
            [self parseTrailheads];
            break;
        case OTImportStageParsingTrailheads:
            [self finishOperation];
            break;
        case OTImportStageParsingFinished:
            break;
    }
}

- (void)parseAreas;
{
    self.stage = OTImportStageParsingAreas;
    
    NSString *path = [self.filePaths objectForKey:OTAreasFilePathKey]; // optional file.

    if ( ![[NSFileManager defaultManager] isReadableFileAtPath:path] )
        [self beginNextTask];
    
    @try {
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *featureCollection = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSMutableArray *areas = [NSMutableArray new];
        
        for ( NSDictionary *feature in featureCollection[@"features"] ) {
            
            NSDictionary *properties = feature[@"properties"];
            NSDictionary *geometry = feature[@"geometry"];
            NSString *identifier = properties[@"id"];
            NSArray *coordinateArrays = geometry[@"coordinates"];
            
            if ( [identifier length] == 0 || [coordinateArrays count] == 0 )
                continue;
            
            NSUInteger index, count = [coordinateArrays count];
            CLLocationCoordinate2D coordinates[count];
            
            for ( index = 0; index < count; index++ ) {
                NSArray *pair = coordinateArrays[index];
                double longitude = [pair[0] doubleValue];
                double latitude = [pair[1] doubleValue];
                coordinates[index] = CLLocationCoordinate2DMake( latitude, longitude );
            }

            OTArea *area = [[OTArea alloc] initWithIdentifier:identifier coordinates:coordinates count:count];

            area.name = properties[@"name"];
            area.URL = [NSURL URLWithString:properties[@"url"]];
            area.steward = self.stewardsByIDs[properties[@"stewardID"]];
            area.openStreetMapTags = [self splitOSMTagsString:properties[@"osm_tags"]];
            
            [areas addObject:areas];
        }
        
        self.importedAreas = [areas copy];
    }
    @catch (NSException *exception) {
        
        NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString( @"OpenTrails importer could not parse %@.", @"" ), path];
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription };
        self.error = [[NSError alloc] initWithDomain:OTErrorDomain code:OTErrorCodeDataFormatError userInfo:userInfo];
        self.stage = OTImportStageParsingFinished;
        return;
    }
    
    [self beginNextTask];
}

- (void)parseTrailheads;
{
    self.stage = OTImportStageParsingTrailheads;
    
    NSString *path = [self.filePaths objectForKey:OTTrailheadsFilePathKey]; // required file.
    
    @try {
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *featureCollection = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        
        for ( NSDictionary *feature in featureCollection[@"features"] ) {
            
            NSDictionary *properties = feature[@"properties"];
            NSDictionary *geometry = feature[@"geometry"];
            NSString *identifier = properties[@"id"];
            NSArray *coordinates = geometry[@"coordinates"];
            
            if ( [identifier length] == 0 || [coordinates count] == 0 )
                continue;
            
            double longitude = [coordinates[0] doubleValue];
            double latitude = [coordinates[1] doubleValue];

            OTTrailhead *trailhead = [[OTTrailhead alloc] init];
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake( latitude, longitude );
            
            trailhead.coordinate = coordinate;
            trailhead.name = properties[@"name"];
            trailhead.address = properties[@"address"];
            trailhead.stewards = [self stewardsMatchingIDs:properties[@"steward_ids"]];
            trailhead.openStreetMapTags = [self splitOSMTagsString:properties[@"osm_tags"]];
            trailhead.hasParking = [properties[@"parking"] isEqualToString:@"yes"];
            trailhead.hasDrinkingWater = [properties[@"drinkwater"] isEqualToString:@"yes"];
            trailhead.hasRestrooms = [properties[@"restrooms"] isEqualToString:@"yes"];
            trailhead.hasKiosk = [properties[@"kiosk"] isEqualToString:@"yes"];
            
            for ( OTTrail *trail in [self trailSegmentsMatchingIDs:properties[@"trail_ids"]] ) {
                
                NSMutableArray *trailheads = [NSMutableArray arrayWithArray:trail.trailheads];
                [trailheads addObject:trailhead];
                trail.trailheads = [trailheads copy];
            }
        }
    }
    @catch (NSException *exception) {
        
        NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString( @"OpenTrails importer could not parse %@.", @"" ), path];
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription };
        self.error = [[NSError alloc] initWithDomain:OTErrorDomain code:OTErrorCodeDataFormatError userInfo:userInfo];
        self.stage = OTImportStageParsingFinished;
        return;
    }
    
    [self beginNextTask];
}

- (void)parseSegments;
{
    self.stage = OTImportStageParsingSegments;
    
    NSString *path = [self.filePaths objectForKey:OTTrailSegmentsFilePathKey]; // required file.
    
    @try {
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSDictionary *featureCollection = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        
        for ( NSDictionary *feature in featureCollection[@"features"] ) {
            
            NSDictionary *properties = feature[@"properties"];
            NSDictionary *geometry = feature[@"geometry"];
            NSString *identifier = properties[@"id"];
            NSArray *coordinateArrays = geometry[@"coordinates"];
            
            if ( [identifier length] == 0 || [coordinateArrays count] == 0 )
                continue;
            
            NSUInteger index, count = [coordinateArrays count];
            CLLocationCoordinate2D coordinates[count];
            
            for ( index = 0; index < count; index++ ) {
                NSArray *pair = coordinateArrays[index];
                double longitude = [pair[0] doubleValue];
                double latitude = [pair[1] doubleValue];
                coordinates[index] = CLLocationCoordinate2DMake( latitude, longitude );
            }
            
            OTTrailSegment *segment = [[OTTrailSegment alloc] initWithIdentifier:identifier coordinates:coordinates count:count];
            
            segment.name = properties[@"name"];
            segment.steward = self.stewardsByIDs[properties[@"steward_id"]];
            segment.openStreetMapTags = [self splitOSMTagsString:properties[@"osm_tags"]];
            segment.motorVehiclePolicy = OTTrailPolicyFromString( properties[@"motor_vehicles"] );
            segment.footTrafficPolicy = OTTrailPolicyFromString( properties[@"foot"] );
            segment.bicyclePolicy = OTTrailPolicyFromString( properties[@"bicycle"] );
            segment.horsePolicy = OTTrailPolicyFromString( properties[@"horse"] );
            segment.skiPolicy = OTTrailPolicyFromString( properties[@"ski"] );
            segment.wheelchairPolicy = OTTrailPolicyFromString( properties[@"wheelchair"] );

            self.segmentsByIDs[identifier] = segment;
        }
    }
    @catch (NSException *exception) {
        
        NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString( @"OpenTrails importer could not parse %@.", @"" ), path];
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorDescription };
        self.error = [[NSError alloc] initWithDomain:OTErrorDomain code:OTErrorCodeDataFormatError userInfo:userInfo];
        self.stage = OTImportStageParsingFinished;
        return;
    }
    
    [self beginNextTask];
}

- (void)parseTrails;
{
    self.stage = OTImportStageParsingTrails;

    // Named_trails.csv is a required file.
    
    NSString *path = [self.filePaths objectForKey:OTNamedTrailsFilePathKey];
    CHCSVParser *parser = [[CHCSVParser alloc] initWithContentsOfCSVFile:path];

    parser.delegate = self;
    [parser parse];
}

- (void)parseStewards;
{
    self.stage = OTImportStageParsingStewards;
    
    // Stewards.csv is a required file.
    
    NSString *path = [self.filePaths objectForKey:OTStewardsFilePathKey];
    CHCSVParser *parser = [[CHCSVParser alloc] initWithContentsOfCSVFile:path];
    
    parser.delegate = self;
    [parser parse];
}

- (void)finishOperation;
{
    self.importedTrails = [[self.trailsByIDs allValues] copy];
    self.stage = OTImportStageParsingFinished;
}

- (NSArray *)trailSegmentsMatchingIDs:(NSString *)string;
{
    NSArray *components = [string componentsSeparatedByString:@";"];
    NSMutableSet *segments = [[NSMutableSet alloc] initWithCapacity:[components count]];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    
    for ( NSString *component in components ) {
        
        NSString *segmentID = [component stringByTrimmingCharactersInSet:whitespace];
        OTTrailSegment *segment = self.segmentsByIDs[segmentID];
        
        if ( segment == nil )
            continue;
        
        [segments addObject:segment];
    }
    
    return [segments allObjects];
}

- (NSArray *)trailsMatchingIDs:(NSString *)string;
{
    NSArray *components = [string componentsSeparatedByString:@";"];
    NSMutableSet *trails = [[NSMutableSet alloc] initWithCapacity:[components count]];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];

    for ( NSString *component in components ) {
        
        NSString *trailID = [component stringByTrimmingCharactersInSet:whitespace];
        OTTrail *trail = self.trailsByIDs[trailID];
        
        if ( trail == nil )
            continue;
        
        [trails addObject:trail];
    }
    
    return [trails allObjects];
}

- (NSArray *)stewardsMatchingIDs:(NSString *)string;
{
    NSArray *components = [string componentsSeparatedByString:@";"];
    NSMutableSet *stewards = [[NSMutableSet alloc] initWithCapacity:[components count]];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];

    for ( NSString *component in components ) {
        
        NSString *stewardID = [component stringByTrimmingCharactersInSet:whitespace];
        OTSteward *steward = self.stewardsByIDs[stewardID];
        
        if ( steward == nil )
            continue;
        
        [stewards addObject:steward];
    }
    
    return [stewards allObjects];
}

- (NSDictionary *)splitOSMTagsString:(NSString *)tags;
{
    if ( [tags length] == 0 )
        return @{};
    
    NSArray *pairs = [tags componentsSeparatedByString:@";"];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[pairs count]];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    for ( NSString *string in pairs ) {
        NSArray *pair = [string componentsSeparatedByString:@"="];
        NSString *key = [pair[0] stringByTrimmingCharactersInSet:whitespace];
        NSString *value = [pair[1] stringByTrimmingCharactersInSet:whitespace];
        dictionary[key] = value;
    }
    
    return [dictionary copy];
}

#pragma mark NSOperation

- (void)start;
{
    [self beginNextTask];
}

- (BOOL)isConcurrent;
{
    return YES;
}

- (BOOL)isExecuting;
{
    return self.stage != OTImportStageNotStarted && self.stage != OTImportStageParsingFinished;
}

- (BOOL)isFinished;
{
    return self.stage == OTImportStageParsingFinished;
}

#pragma mark CHCSVParserDelegate

- (void)parserDidEndDocument:(CHCSVParser *)parser;
{
    [self beginNextTask];
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber;
{
    [self.csvLineData removeAllObjects];
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber;
{
    NSString *identifier = self.csvLineData[@"identifier"];
    
    if ( [identifier length] == 0 )
        return;

    if ( self.stage == OTImportStageParsingStewards ) {
        
        OTSteward *steward = [[OTSteward alloc] initWithIdentifier:identifier];
        
        steward.name = self.csvLineData[@"name"];
        steward.URL = self.csvLineData[@"URL"];
        steward.phone = self.csvLineData[@"phone"];
        steward.address = self.csvLineData[@"address"];
        steward.publisher = [self.csvLineData[@"publisher"] boolValue];

        self.stewardsByIDs[identifier] = steward;
        
    } else if ( self.stage == OTImportStageParsingTrails ) {
        
        OTTrail *trail = [[OTTrail alloc] initWithIdentifier:identifier];
        
        trail.name = self.csvLineData[@"name"];
        trail.trailDescription = self.csvLineData[@"description"];
        trail.network = self.csvLineData[@"network"];
        trail.segments = self.csvLineData[@"segments"];
        
        self.trailsByIDs[identifier] = trail;
    }
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex;
{
    if ( self.stage == OTImportStageParsingStewards ) {
        
        switch ( fieldIndex ) {
            case 0:
                self.csvLineData[@"identifier"] = field;
                break;
            case 1:
                self.csvLineData[@"name"] = field;
                break;
            case 2:
                self.csvLineData[@"URL"] = [NSURL URLWithString:field];
                break;
            case 3:
                self.csvLineData[@"phone"] = field;
                break;
            case 4:
                self.csvLineData[@"address"] = field;
                break;
            case 5:
                self.csvLineData[@"publisher"] = [field isEqualToString:@"yes"] ? @(YES) : @(NO);
                break;
            default:
                NSLog( @"Warning: unhandled field in stewards.csv at index %ld.", (long) fieldIndex );
                break;
        }
        
    } else if ( self.stage == OTImportStageParsingTrails ) {
        
        switch ( fieldIndex ) {
            case 0:
                self.csvLineData[@"name"] = field;
                break;
            case 1:
                self.csvLineData[@"segments"] = [self trailSegmentsMatchingIDs:field];
                break;
            case 2:
                self.csvLineData[@"identifier"] = field;
                break;
            case 3:
                self.csvLineData[@"description"] = field;
                break;
            case 4:
                self.csvLineData[@"network"] = field;
                break;
            default:
                NSLog( @"Warning: unhandled field in stewards.csv at index %ld.", (long) fieldIndex );
                break;
        }
    }
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;
{
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString( @"OpenTrails importer could not parse CSV file.", @"" ), NSUnderlyingErrorKey : error };
    self.error = [[NSError alloc] initWithDomain:OTErrorDomain code:OTErrorCodeDataFormatError userInfo:userInfo];
    self.stage = OTImportStageParsingFinished;
}

#pragma mark NSObject

+ (NSSet *)keyPathsForValuesAffectingIsExecuting;
{
    return [NSSet setWithObjects:@"stage", nil];
}

+ (NSSet *)keyPathsForValuesAffectingIsFinished
{
    return [NSSet setWithObjects:@"stage", nil];
}

@end
