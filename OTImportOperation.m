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
#import "CHCSVParser.h"

@interface OTImportOperation() <CHCSVParserDelegate>

@property (strong) NSDictionary *filePaths;
@property (assign) BOOL isParsing;
@property (assign) BOOL isComplete;
@property (strong) NSMutableDictionary *segmentsByIDs;
@property (strong) NSMutableDictionary *trailsByIDs;

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

@end
