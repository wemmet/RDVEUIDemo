//
//  RDPrivateObject.m
//  RDVECore
//
//  Created by apple on 2018/9/11.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDPrivateObject.h"
#import <objc/runtime.h>

@interface PathCommand : NSObject
@property (nonatomic, assign) CGPathElementType type;
@property (nonatomic, assign) CGPoint point;
@property (nonatomic, strong) NSMutableArray* controlPoints;
@end
@implementation PathCommand
@end
void MyCGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    
    CGPathElementType type = element->type;
    int numberOfPoints = 0;
    
    
    NSMutableArray* points = [NSMutableArray array];
    switch(type) {
        case kCGPathElementMoveToPoint: // contains 1 point
            numberOfPoints = 1;
            
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            numberOfPoints = 1;
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            numberOfPoints = 2;
            break;
        case kCGPathElementAddCurveToPoint: // contains 3 points
            numberOfPoints = 3;
            break;
        case kCGPathElementCloseSubpath: // contains no point
            numberOfPoints = 0;
            break;
    }
    for (int index = 0; index < numberOfPoints - 1; index++) {
        CGPoint point = element->points[index];
        [points addObject:[NSValue valueWithCGPoint:point]];
    }
    PathCommand* pathCommand = [[PathCommand alloc] init];
    pathCommand.type = element->type;
    pathCommand.point = element->points[numberOfPoints-1];
    pathCommand.controlPoints = points;
    
    [bezierPoints addObject:pathCommand];
}

static NSString* LookupTableName = @"lookupTableName";

@implementation VVAssetAnimatePosition(Private)
- (void)setLookupTable:(NSMutableArray *)lookupTable{
    objc_setAssociatedObject(self, &LookupTableName, lookupTable, OBJC_ASSOCIATION_COPY);
}
- (NSMutableArray *)lookupTable{
    return objc_getAssociatedObject(self, &LookupTableName);
}
//- (void)setFixedTimeRange:(CMTimeRange)fixedTimeRange{
//    NSValue* value = [NSValue valueWithBytes:&fixedTimeRange objCType:@encode(CMTimeRange)];
//    objc_setAssociatedObject(self, &fixedTimeRangeName, value, OBJC_ASSOCIATION_COPY);
//}
//- (CMTimeRange)fixedTimeRange{
//    CMTimeRange range;
//    NSValue* value =  objc_getAssociatedObject(self, &fixedTimeRangeName);
//    [value getValue:&range];
//    return range;
//}
- (void)generate{
    CGPathRef yourCGPath = self.path.CGPath;
    NSMutableArray* bezierPoints = [NSMutableArray array];
    CGPathApply(yourCGPath, (__bridge void*)(bezierPoints), MyCGPathApplierFunc);
    
    
    
    int capacityPerPiece = 500/bezierPoints.count;
    
    NSMutableArray* lookupTable = [NSMutableArray array];
    
    CGPoint previousPoint = CGPointZero;
    for (PathCommand* command in bezierPoints) {
        CGPoint endPoint = command.point;
        CGPoint startPoint = previousPoint;
        
        switch (command.type) {
            case kCGPathElementAddLineToPoint:
                for (int i = 0; i<capacityPerPiece; i++) {
                    float t = i*1.0/capacityPerPiece;
                    CGPoint point = calculateLinear(t, startPoint, endPoint);
                    [lookupTable addObject:[NSValue valueWithCGPoint:point]];
                }
                break;
            case kCGPathElementAddQuadCurveToPoint:
                for (int i = 0; i<capacityPerPiece; i++) {
                    float t = i*1.0/capacityPerPiece;
                    CGPoint point = calculateQuad(t, startPoint, [command.controlPoints[0] CGPointValue], endPoint);
                    [lookupTable addObject:[NSValue valueWithCGPoint:point]];
                }
                break;
            case kCGPathElementAddCurveToPoint:
                for (int i = 0; i<capacityPerPiece; i++) {
                    float t = i*1.0/capacityPerPiece;
                    CGPoint point = calculateCube(t, startPoint, [command.controlPoints[0] CGPointValue], [command.controlPoints[1] CGPointValue],endPoint);
                    [lookupTable addObject:[NSValue valueWithCGPoint:point]];
                }
                break;
            default:
                break;
        }
        previousPoint = endPoint;
        
    }
    self.lookupTable = lookupTable;
}
- (CGPoint)calculateWithTimeValue:(float)v{
    NSInteger index = self.lookupTable.count * v;
    if (index >= self.lookupTable.count) {
        index = self.lookupTable.count - 1;
    }
    return [self.lookupTable[index] CGPointValue];
}
@end

@implementation RDCaptionCustomAnimate(Private)
- (void)setLookupTable:(NSMutableArray *)lookupTable{
    objc_setAssociatedObject(self, &LookupTableName, lookupTable, OBJC_ASSOCIATION_COPY);
}
- (NSMutableArray *)lookupTable{
    return objc_getAssociatedObject(self, &LookupTableName);
}
//- (void)setFixedTimeRange:(CMTimeRange)fixedTimeRange{
//    NSValue* value = [NSValue valueWithBytes:&fixedTimeRange objCType:@encode(CMTimeRange)];
//    objc_setAssociatedObject(self, &fixedTimeRangeName, value, OBJC_ASSOCIATION_COPY);
//}
//- (CMTimeRange)fixedTimeRange{
//    CMTimeRange range;
//    NSValue* value =  objc_getAssociatedObject(self, &fixedTimeRangeName);
//    [value getValue:&range];
//    return range;
//}
- (void)generate{
    CGPathRef yourCGPath = self.path.CGPath;
    NSMutableArray* bezierPoints = [NSMutableArray array];
    CGPathApply(yourCGPath, (__bridge void*)(bezierPoints), MyCGPathApplierFunc);
    
    
    
    int capacityPerPiece = 500/bezierPoints.count;
    
    NSMutableArray* lookupTable = [NSMutableArray array];
    
    CGPoint previousPoint = CGPointZero;
    for (PathCommand* command in bezierPoints) {
        CGPoint endPoint = command.point;
        CGPoint startPoint = previousPoint;
        
        switch (command.type) {
            case kCGPathElementAddLineToPoint:
                for (int i = 0; i<capacityPerPiece; i++) {
                    float t = i*1.0/capacityPerPiece;
                    CGPoint point = calculateLinear(t, startPoint, endPoint);
                    [lookupTable addObject:[NSValue valueWithCGPoint:point]];
                }
                break;
            case kCGPathElementAddQuadCurveToPoint:
                for (int i = 0; i<capacityPerPiece; i++) {
                    float t = i*1.0/capacityPerPiece;
                    CGPoint point = calculateQuad(t, startPoint, [command.controlPoints[0] CGPointValue], endPoint);
                    [lookupTable addObject:[NSValue valueWithCGPoint:point]];
                }
                break;
            case kCGPathElementAddCurveToPoint:
                for (int i = 0; i<capacityPerPiece; i++) {
                    float t = i*1.0/capacityPerPiece;
                    CGPoint point = calculateCube(t, startPoint, [command.controlPoints[0] CGPointValue], [command.controlPoints[1] CGPointValue],endPoint);
                    [lookupTable addObject:[NSValue valueWithCGPoint:point]];
                }
                break;
            default:
                break;
        }
        previousPoint = endPoint;
        
    }
    self.lookupTable = lookupTable;
}
- (CGPoint)calculateWithTimeValue:(float)v{
    NSInteger index = self.lookupTable.count * v;
    if (index >= self.lookupTable.count) {
        index = self.lookupTable.count - 1;
    }
    return [self.lookupTable[index] CGPointValue];
}
@end

static NSString* fixedTimeRangeName = @"fixedTimeRange";
static NSString* passThroughTimeRangeName = @"passThroughTimeRange";
@implementation RDScene (Private)
- (void)setFixedTimeRange:(CMTimeRange)fixedTimeRange{
    NSValue* value = [NSValue valueWithBytes:&fixedTimeRange objCType:@encode(CMTimeRange)];
    objc_setAssociatedObject(self, &fixedTimeRangeName, value, OBJC_ASSOCIATION_COPY);
}
- (CMTimeRange)fixedTimeRange{
    CMTimeRange range;
    NSValue* value =  objc_getAssociatedObject(self, &fixedTimeRangeName);
    [value getValue:&range];
    return range;
}
- (void)setPassThroughTimeRange:(CMTimeRange)passThroughTimeRange{
    NSValue* value = [NSValue valueWithBytes:&passThroughTimeRange objCType:@encode(CMTimeRange)];
    objc_setAssociatedObject(self, &passThroughTimeRangeName, value, OBJC_ASSOCIATION_COPY);
}
- (CMTimeRange)passThroughTimeRange{
    CMTimeRange range;
    NSValue* value = objc_getAssociatedObject(self,&(passThroughTimeRangeName));
    [value getValue:&range];
    return range;
}
@end


static NSString* rdMusicAudioMixInputParameterName = @"rdMusicAudioMixInputParameterName";

@implementation RDMusic (Private)
- (void)setMixParameter:(AVAudioMixInputParameters *)mixParameter{
    objc_setAssociatedObject(self, &rdMusicAudioMixInputParameterName, mixParameter, OBJC_ASSOCIATION_COPY);
}
- (AVAudioMixInputParameters *)mixParameter{
    return objc_getAssociatedObject(self, &rdMusicAudioMixInputParameterName);
    
}
@end

static NSString* transformName = @"transform";
static NSString* trackIDName = @"trackID";
static NSString* lastName = @"last";
static NSString* assetCompositionTrackName = @"assetCompositionTrack";
static NSString* natureSizeName = @"natureSize";
static NSString* hasAudioName = @"hasAudio";
static NSString* trackIndexName = @"trackIndex";
static NSString* audioMixInputParameterName = @"audioMixInputParameterName";
static NSString* actualTimeRangeName = @"actualTimeRange";

@implementation VVAsset (Private)
- (void)setMixParameter:(AVAudioMixInputParameters *)mixParameter{
    objc_setAssociatedObject(self, &audioMixInputParameterName, mixParameter, OBJC_ASSOCIATION_COPY);
}
- (AVAudioMixInputParameters *)mixParameter{
    return objc_getAssociatedObject(self, &audioMixInputParameterName);
    
}
- (void)setHasAudio:(BOOL)hasAudio{
    NSNumber* b = [NSNumber numberWithBool:hasAudio];
    objc_setAssociatedObject(self, &hasAudioName, b, OBJC_ASSOCIATION_COPY);
}
- (BOOL)hasAudio{
    NSNumber* b = objc_getAssociatedObject(self, &hasAudioName);
    return [b boolValue];
}
- (void)setTrackIndex:(NSInteger)trackIndex{
    NSNumber* ti = [NSNumber numberWithInteger:trackIndex];
    objc_setAssociatedObject(self, &trackIndexName, ti, OBJC_ASSOCIATION_COPY);
}
- (NSInteger)trackIndex{
    NSNumber* ti = objc_getAssociatedObject(self, &trackIndexName);
    return [ti integerValue];
}

- (void)setNatureSize:(CGSize)natureSize{
    NSValue* value = [NSValue value:&natureSize withObjCType:@encode(CGSize)];
    objc_setAssociatedObject(self, &natureSizeName, value, OBJC_ASSOCIATION_COPY);
}
- (CGSize)natureSize{
    CGSize natureSize;
    NSValue* value = objc_getAssociatedObject(self, &natureSizeName);
    [value getValue:&natureSize];
    return natureSize;
}
- (void)setAssetCompositionTrack:(AVCompositionTrack *)assetCompositionTrack{
    objc_setAssociatedObject(self, &assetCompositionTrackName, assetCompositionTrack, OBJC_ASSOCIATION_COPY);
    
}
- (AVCompositionTrack *)assetCompositionTrack{
    return objc_getAssociatedObject(self, &assetCompositionTrackName);
}
- (void)setTransform:(CGAffineTransform)transform{
    NSValue* value = [NSValue value:&transform withObjCType:@encode(CGAffineTransform)];
    objc_setAssociatedObject(self, &transformName, value, OBJC_ASSOCIATION_COPY);
}
- (CGAffineTransform)transform{
    CGAffineTransform transform;
    NSValue* value = objc_getAssociatedObject(self, &transformName);
    [value getValue:&transform];
    return transform;
}
- (void)setTrackID:(NSNumber *)trackID{
    objc_setAssociatedObject(self, &trackIDName, trackID, OBJC_ASSOCIATION_COPY);
}
- (NSNumber *)trackID{
    return objc_getAssociatedObject(self, &trackIDName);
}
- (void)setLast:(float)last{
    NSNumber* number = [NSNumber numberWithFloat:last];
    objc_setAssociatedObject(self, &lastName, number, OBJC_ASSOCIATION_COPY);
}
- (float)last{
    NSNumber* number = objc_getAssociatedObject(self, &lastName);
    return [number floatValue];
}

- (void)setActualTimeRange:(CMTimeRange)actualTimeRange {
    NSValue* value = [NSValue value:&actualTimeRange withObjCType:@encode(CMTimeRange)];
    objc_setAssociatedObject(self, &actualTimeRangeName, value, OBJC_ASSOCIATION_COPY);
}
- (CMTimeRange)actualTimeRange {
    CMTimeRange timeRange;
    NSValue* value = objc_getAssociatedObject(self, &actualTimeRangeName);
    [value getValue:&timeRange];
    return timeRange;
}

@end

@implementation VVMovieEffect (Private)
- (void)setTrackID:(NSNumber *)trackID{
    objc_setAssociatedObject(self, &trackIDName, trackID, OBJC_ASSOCIATION_COPY);
}
- (NSNumber *)trackID{
    return objc_getAssociatedObject(self, &trackIDName);
}

@end



