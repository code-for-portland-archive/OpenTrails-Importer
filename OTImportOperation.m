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

@interface OTImportOperation() <CHCSVParserDelegate>

@property (strong) NSDictionary *filePaths;
@property (assign) BOOL isParsing;
@property (assign) BOOL isComplete;
@property (strong) NSMutableDictionary *segmentsByIDs;
@property (strong) NSMutableDictionary *trailsByIDs;
@property (strong) OTTrail *currentTrail;

- (void)parseAreas;
- (void)parseTrailheads;
- (void)parseSegments;
- (void)parseTrails;

- (NSArray *)trailSegmentsMatchingIDs:(NSString *)string;
- (NSArray *)trailsMatchingIDs:(NSString *)string;

@end

@implementation OTImportOperation

#pragma mark OTImportOperation

- (instancetype)initWithFilePaths:(NSDictionary *)filePaths;
{
    if ( self = [super init] ) {
        
        _filePaths = filePaths;
    }
    
    return self;
}

#pragma mark OTImportOperation Private

- (void)parseAreas;
{
    
}

- (void)parseTrailheads;
{
    
}

- (void)parseSegments;
{
    
}

- (void)parseTrails;
{
    
}

- (NSArray *)trailSegmentsMatchingIDs:(NSString *)string;
{
    
}

- (NSArray *)trailsMatchingIDs:(NSString *)string;
{
    
}

#pragma mark NSOperation

- (void)start;
{
    [self willChangeValueForKey:@"isExecuting"];
    self.isParsing = YES;
    [self parseTrailSegments];
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent;
{
    return YES;
}

- (BOOL)isExecuting;
{
    return self.isParsing;
}

- (BOOL)isFinished;
{
    return self.isComplete;
}

#pragma mark CHCSVParserDelegate

- (void)parserDidBeginDocument:(CHCSVParser *)parser;
{
    self.trailsByIDs = [[NSMutableDictionary alloc] init];
}

- (void)parserDidEndDocument:(CHCSVParser *)parser;
{
    [self parseTrailheads];
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber;
{
    if ( recordNumber == 1 )
        return;
    
    self.currentTrail = [[OTTrail alloc] init];
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber;
{
    if ( [self.currentTrail.identifier length] > 0 )
        [self.trailsByIDs setObject:self.currentTrail forKey:self.currentTrail.identifier];
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex;
{
    switch ( fieldIndex ) {
        case 0:
            self.currentTrail.name = field;
            break;
        case 1:
            self.currentTrail.segments = [self trailSegmentsMatchingIDs:field];
            break;
        case 2:
            self.currentTrail.identifier = field;
            break;
        default:
            break;
    }
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    NSDictionary *userInfo = @{ NSUnderlyingErrorKey : error };
    self.error = [[NSError alloc] initWithDomain:OTErrorDomain code:OTErrorCodeDataFormatError userInfo:userInfo];
    self.isParsing = NO;
    self.isComplete = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
