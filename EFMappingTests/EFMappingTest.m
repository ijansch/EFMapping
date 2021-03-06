//
//  EFMappingTest.m
//  Spaarspot
//
//  Created by Johan Kool on 23/3/2014.
//  Copyright (c) 2014 Spaarspot. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "EFDataMappingKit.h"

typedef NS_ENUM(int, EFSampleType) {
    EFSampleTypeUnknown,
    EFSampleTypeFoo,
    EFSampleTypeBar,
    EFSampleTypeBaz
};

@interface EFSample : NSObject

@property (nonatomic, copy) NSString *guid;
@property (nonatomic, assign) EFSampleType type;
@property (nonatomic, assign) NSInteger myPoints;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) EFSample *sample;
@property (nonatomic, copy) NSArray *relatedSamples;
@property (nonatomic, assign, readonly) BOOL customInit;

@end

@implementation EFSample

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        [[EFMapper sharedInstance] decodeObject:self withCoder:aDecoder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:0 forKey:@"version"];
    [[EFMapper sharedInstance] encodeObject:self withCoder:aCoder];
}

- (id)initCustomized {
    self = [super init];
    if (self) {
        _customInit = YES;
    }
    return self;
}

@end

@interface EFMappingTest : XCTestCase

@end

@implementation EFMappingTest

- (void)testValidatingValues {
    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m) {
        m.internalClass = [NSString class];
        m.externalKey = @"id";
        m.internalKey = @"guid";
        m.requires = [EFRequires exists];
    }]] forClass:[EFSample class]];

    NSError *error;
    BOOL valid = [mapper validateValues:@{@"id": @"1"} forClass:[EFSample class] error:&error];
    XCTAssertTrue(valid, @"guid error: %@", EFPrettyMappingError(error));

    valid = [mapper validateValues:@{@"id": @1} forClass:[EFSample class] error:&error];
    XCTAssertFalse(valid, @"Expected values to be invalid but found no error");

    valid = [mapper validateValues:@{@"id": [NSNull null]} forClass:[EFSample class] error:&error];
    XCTAssertFalse(valid, @"Expected values to be invalid but found no error");

    valid = [mapper validateValues:@{} forClass:[EFSample class] error:&error];
    XCTAssertFalse(valid, @"Expected values to be invalid but found no error");
}

- (void)testSettingValues {
    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m) {
        m.internalClass = [NSString class];
        m.externalKey = @"id";
        m.internalKey = @"guid";
        m.requires = [EFRequires exists];
    }]] forClass:[EFSample class]];

    NSError *error;
    EFSample *sample = [mapper objectOfClass:[EFSample class] withValues:@{@"id": @"1"} error:&error];
    XCTAssertEqualObjects(sample.guid, @"1", @"guid error: %@", EFPrettyMappingError(error));

    EFSample *sample2 = [mapper objectOfClass:[EFSample class] withValues:@{@"id": [NSNull null]} error:&error];
    XCTAssertNil(sample2, @"Expected error for missing guid");
}

- (void)testTransformingValues {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];

    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m){m.internalClass = [NSString class]; m.externalKey = @"id"; m.internalKey = @"guid"; m.requires = [EFRequires exists];}],
                               [EFMapping mapping:^(EFMapping *m){m.internalClass = [NSDate class]; m.externalKey = @"created_at"; m.internalKey = @"creationDate"; m.formatter = dateFormatter;}]
                               ] forClass:[EFSample class]];

    NSError *error;
    EFSample *sample = [mapper objectOfClass:[EFSample class] withValues:@{@"id": @"1", @"created_at": @"2014-04-01"} error:&error];
    XCTAssertNotNil(sample, @"Expected values to be valid but found error %@", EFPrettyMappingError(error));
    XCTAssertTrue([sample.creationDate isKindOfClass:[NSDate class]], @"Expected a date");

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:sample.creationDate];
    XCTAssertEqual(components.year, 2014, @"Expected year 2014");
    XCTAssertEqual(components.month, 4, @"Expected month 4");
    XCTAssertEqual(components.day, 1, @"Expected day 1");
}

- (void)testCustomInitializers {
    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerInitializer:^id(__unsafe_unretained Class aClass, NSDictionary *values) {;
        return [[aClass alloc] initCustomized];
    } forClass:[EFSample class]];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m){m.internalClass = [NSString class]; m.externalKey = @"id"; m.internalKey = @"guid"; m.requires = [EFRequires exists];}]
                               ] forClass:[EFSample class]];

    NSError *error;
    EFSample *sample = [mapper objectOfClass:[EFSample class] withValues:@{@"id": @"1"} error:&error];
    XCTAssertNotNil(sample, @"Expected values to be valid but found error %@", EFPrettyMappingError(error));
    XCTAssertTrue(sample.customInit, @"Expected custom init to be used");
}

- (void)testEncoding {
#warning Missing test
}

- (void)testEncodingSubclasses {
#warning Missing test
}

- (void)testCreatingDictionaryRepresentation {
    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m){m.internalClass = [NSString class]; m.externalKey = @"id"; m.internalKey = @"guid"; m.requires = [EFRequires exists];}],
                               [EFMapping mappingForArrayOfClass:[EFSample class] externalKey:@"children" internalKey:@"relatedSamples"]] forClass:[EFSample class]];

    NSError *error;
    EFSample *sample = [mapper objectOfClass:[EFSample class] withValues:@{@"id": @"1", @"children": @[@{@"id": @"2"}, @{@"id": @"3", @"children": @[@{@"id": @"4"}, @{@"id": @"5"}]}]} error:&error];
    XCTAssertNotNil(sample, @"Map error: %@", EFPrettyMappingError(error));

    id dictionaryRepresentation = [mapper dictionaryRepresentationOfObject:sample];
    XCTAssertNotNil(dictionaryRepresentation, @"Expected something");
    XCTAssertTrue([dictionaryRepresentation isKindOfClass:[NSDictionary class]], @"Expected dict");
    XCTAssertEqual([dictionaryRepresentation[@"children"] count], 2, @"Expected 2 children");
    XCTAssertEqual([dictionaryRepresentation[@"children"][1][@"children"] count], 2, @"Expected 2 grandchildren");
    XCTAssertEqualObjects(dictionaryRepresentation[@"children"][1][@"children"][1][@"id"], @"5", @"Expected id of grandchild 2 to be 5");
}

- (void)testRequirements {
    XCTAssertTrue([[EFRequires exists] evaluateForValue:@"bla"], @"Value exist");
    XCTAssertFalse([[EFRequires exists] evaluateForValue:nil], @"Value exist");

    XCTAssertTrue([[EFRequires passes:^BOOL(id value) {
        return YES;
    }] evaluateForValue:@"bla"], @"Value passes");
    XCTAssertFalse([[EFRequires passes:^BOOL(id value) {
        return NO;
    }] evaluateForValue:@"bla"], @"Value passes");

    XCTAssertTrue([[EFRequires largerThan:@2] evaluateForValue:@3], @"Value larger than");
    XCTAssertFalse([[EFRequires largerThan:@2] evaluateForValue:@2], @"Value larger than");
    XCTAssertFalse([[EFRequires largerThan:@2] evaluateForValue:@1], @"Value larger than");

    XCTAssertTrue([[EFRequires largerThanOrEqualTo:@2] evaluateForValue:@3], @"Value larger than or equal to");
    XCTAssertTrue([[EFRequires largerThanOrEqualTo:@2] evaluateForValue:@2], @"Value larger than or equal to");
    XCTAssertFalse([[EFRequires largerThanOrEqualTo:@2] evaluateForValue:@1], @"Value larger than or equal to");

    XCTAssertFalse([[EFRequires equalTo:@2] evaluateForValue:@3], @"Value equal to");
    XCTAssertTrue([[EFRequires equalTo:@2] evaluateForValue:@2], @"Value equal to");
    XCTAssertFalse([[EFRequires equalTo:@2] evaluateForValue:@1], @"Value equal to");

    XCTAssertFalse([[EFRequires smallerThan:@2] evaluateForValue:@3], @"Value smaller than");
    XCTAssertFalse([[EFRequires smallerThan:@2] evaluateForValue:@2], @"Value smaller than");
    XCTAssertTrue([[EFRequires smallerThan:@2] evaluateForValue:@1], @"Value smaller than");

    XCTAssertFalse([[EFRequires smallerThanOrEqualTo:@2] evaluateForValue:@3], @"Value smaller than or equal to");
    XCTAssertTrue([[EFRequires smallerThanOrEqualTo:@2] evaluateForValue:@2], @"Value smaller than or equal to");
    XCTAssertTrue([[EFRequires smallerThanOrEqualTo:@2] evaluateForValue:@1], @"Value smaller than or equal to");

    NSArray *array = @[[EFRequires largerThan:@2], [EFRequires smallerThan:@4]];
    XCTAssertTrue([array evaluateForValue:@3], @"Value inside range");
    XCTAssertFalse([array evaluateForValue:@1], @"Value outside range");

    XCTAssertFalse([[EFRequires not:array] evaluateForValue:@3], @"Value inverted");
    XCTAssertTrue([[EFRequires not:array] evaluateForValue:@1], @"Value inverted");

    XCTAssertTrue([[EFRequires either:array or:[EFRequires equalTo:@10]] evaluateForValue:@3], @"Value or");
    XCTAssertTrue([[EFRequires either:array or:[EFRequires equalTo:@10]] evaluateForValue:@10], @"Value or");
    XCTAssertFalse([[EFRequires either:array or:[EFRequires equalTo:@10]] evaluateForValue:@1], @"Value or");
}

- (void)testPrettyErrors {
    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m){m.internalClass = [NSString class]; m.externalKey = @"id"; m.internalKey = @"guid"; m.requires = [EFRequires exists];}],
                               [EFMapping mappingForArrayOfClass:[EFSample class] externalKey:@"children" internalKey:@"relatedSamples"]] forClass:[EFSample class]];

    NSError *error;
    EFSample *sample = [mapper objectOfClass:[EFSample class] withValues:@{@"id": @"1", @"children": @[@{@"id": @"2"}, @{@"id": @3, @"children": @[@{@"id": @"4"}, @{@"id": @5}]}]} error:&error];
    NSString *expectedErrorMsg = @"Encountered 1 validation error in EFSample:\n\
\trelatedSamples: Encountered 1 validation error in array for key relatedSamples:\n\
\t\t0: Encountered 2 validation errors in EFSample:\n\
\t\t\tguid: Did not expect value (3) of class __NSCFNumber for key guid but a NSString instance\n\
\t\t\trelatedSamples: Encountered 1 validation error in array for key relatedSamples:\n\
\t\t\t\t0: Encountered 1 validation error in EFSample:\n\
\t\t\t\t\tguid: Did not expect value (5) of class __NSCFNumber for key guid but a NSString instance";
    XCTAssertEqualObjects(EFPrettyMappingError(error), expectedErrorMsg, @"Pretty print error differs");
}

- (void)testDateFormatting {
    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m){m.internalClass = [NSString class]; m.externalKey = @"id"; m.internalKey = @"guid"; m.requires = [EFRequires exists];}],
                               [EFMapping mapping:^(EFMapping *m){m.internalClass = [NSDate class]; m.externalKey = @"created_at"; m.internalKey = @"creationDate"; m.formatter = [NSDateFormatter ef_rfc3339DateFormatter];}]
                               ] forClass:[EFSample class]];

    NSError *error;
    EFSample *sample = [mapper objectOfClass:[EFSample class] withValues:@{@"id": @"1", @"created_at": @"2014-04-01T09:34:45Z"} error:&error];
    XCTAssertNotNil(sample, @"Expected values to be valid but found error %@", EFPrettyMappingError(error));
    XCTAssertTrue([sample.creationDate isKindOfClass:[NSDate class]], @"Expected a date");

    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit|NSTimeZoneCalendarUnit fromDate:sample.creationDate];
    XCTAssertEqual(components.year, 2014, @"Expected year 2014");
    XCTAssertEqual(components.month, 4, @"Expected month 4");
    XCTAssertEqual(components.day, 1, @"Expected day 1");
    XCTAssertEqual(components.hour, 9, @"Expected hour 9");
    XCTAssertEqual(components.minute, 34, @"Expected minute 34");
    XCTAssertEqual(components.second, 45, @"Expected second 45");
    XCTAssertEqual([components.timeZone secondsFromGMT], 0, @"Expected GMT time zone");
}

- (void)testEnumMapping {
    EFMapper *mapper = [[EFMapper alloc] init];
    [mapper registerMappings:@[[EFMapping mapping:^(EFMapping *m){
                                    m.internalClass = [NSString class];
                                    m.externalKey = @"id";
                                    m.internalKey = @"guid";
                                    m.requires = [EFRequires exists];
                                }],
                               [EFMapping mapping:^(EFMapping *m){
                                    m.internalClass = [NSNumber class];
                                    m.key = @"type";
                                    m.transformer = [EFEnumTransformer transformerWithEnumMapping:@{@(EFSampleTypeFoo): @"foo",
                                                                                                    @(EFSampleTypeBar): @"bar",
                                                                                                    @(EFSampleTypeBaz): @"baz"}];
                                }]
                               ] forClass:[EFSample class]];

    NSError *error;
    EFSample *sample = [mapper objectOfClass:[EFSample class] withValues:@{@"id": @"1", @"type": @"foo"} error:&error];
    XCTAssertNotNil(sample, @"Expected values to be valid but found error %@", EFPrettyMappingError(error));
    XCTAssertEqual(sample.type, EFSampleTypeFoo, @"Expected type to be foo");
}

@end
