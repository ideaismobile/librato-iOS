//
//  LibratoMetric.m
//  Librato-iOS
//
//  Created by Adam Yanalunas on 9/27/13.
//  Copyright (c) 2013 Amco International Education Services, LLC. All rights reserved.
//

#import "LibratoMetric.h"
#import "NSString+SanitizedForMetric.h"
#import "MTLValueTransformer.h"

NSString *const LibratoMetricMeasureTimeKey = @"measure_time";
NSString *const LibratoMetricNameKey = @"name";
NSString *const LibratoMetricSourceKey = @"source";
NSString *const LibratoMetricValueKey = @"value";

@implementation LibratoMetric

#pragma mark - Lifecycle
+ (instancetype)metricNamed:(NSString *)name valued:(NSNumber *)value
{
    return [LibratoMetric.alloc initWithName:name valued:value options:nil];
}


+ (instancetype)metricNamed:(NSString *)name valued:(NSNumber *)value options:(NSDictionary *)options
{
    return [LibratoMetric.alloc initWithName:name valued:value options:options];
}


+ (instancetype)metricNamed:(NSString *)name valued:(NSNumber *)value source:(NSString *)source measureTime:(NSDate *)date
{
    return [LibratoMetric.alloc initWithName:name valued:value options:@{
                                                                         LibratoMetricSourceKey: source,
                                                                         LibratoMetricMeasureTimeKey: date
                                                                         }];
}


- (instancetype)initWithName:(NSString *)name valued:(NSNumber *)value options:(NSDictionary *)options
{
    if ((self = super.init))
    {
        _name = name;
        _value = value ?: @0;
        _measureTime = options[LibratoMetricMeasureTimeKey] ?: NSDate.date;
        _source = options[LibratoMetricSourceKey] ?: NSNull.null;
        _type = @"counters";
    }
    
    return self;
}


#pragma mark - MTLJSONSerializing
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"name": LibratoMetricNameKey,
        @"value": LibratoMetricValueKey,
        @"measureTime": LibratoMetricMeasureTimeKey,
        @"source": LibratoMetricSourceKey,
        @"type": NSNull.null
    };
}


+ (NSValueTransformer *)measureTimeJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSNumber *epoch) {
        return [NSDate dateWithTimeIntervalSince1970:epoch.integerValue];
    } reverseBlock:^id(NSDate *date) {
        return @(floor(date.timeIntervalSince1970));
    }];
}


+ (NSValueTransformer *)nameJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *name) {
        NSAssert(name.length > 0, @"Measurements must be named");
        return name.sanitizedForMetric;
    } reverseBlock:^id(NSString *name) {
        return name.sanitizedForMetric;
    }];
}


+ (NSValueTransformer *)sourceJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSString *source) {
        return source.sanitizedForMetric;
    } reverseBlock:^id(NSString *source) {
        return (source.length ? source.sanitizedForMetric : nil);
    }];
}


+ (NSValueTransformer *)valueJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSNumber *value) {
        NSAssert([self.class isValidValue:value], @"Boolean is not a valid metric value");
        return value;
    } reverseBlock:^id(NSNumber *value) {
        return value;
    }];
}


// TODO: Some magic key's value for JSONDictionaryFromModel: so I don't need this method
- (NSDictionary *)JSONDictionary
{
    NSArray *nonNullableKeys = @[@"source"];
	__block NSMutableDictionary *jsonDict = [MTLJSONAdapter JSONDictionaryFromModel:self].mutableCopy;
    [nonNullableKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if ([jsonDict.allKeys containsObject:key] && (jsonDict[key] == NSNull.null || jsonDict[key] == nil))
        {
            [jsonDict removeObjectForKey:key];
        }
    }];
    
	return jsonDict;
}


#pragma mark - Validation
+ (BOOL)isValidValue:(NSNumber *)value
{
    return (strcmp([value objCType], @encode(BOOL)) == 0) ? NO : YES;
}


#pragma mark - KVC Collection Operators
- (NSUInteger)squared
{
    return pow(self.value.integerValue, 2);
}


#pragma mark - Overrides
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, name: %@, value: %@>", NSStringFromClass([self class]), self, self.name, self.value];
}


@end
