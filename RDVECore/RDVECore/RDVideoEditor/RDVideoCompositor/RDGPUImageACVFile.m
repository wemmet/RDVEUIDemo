//
//  RDGPUImageACVFile.m
//  RDVECore
//
//  Created by 周晓林 on 2017/11/6.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageACVFile.h"
#import <UIKit/UIKit.h>
//  RDGPUImageACVFile
//
//  ACV File format Parser
//  Please refer to http://www.adobe.com/devnet-apps/photoshop/fileformatashtml/PhotoshopFileFormats.htm#50577411_pgfId-1056330
//



@implementation RDGPUImageACVFile

@synthesize rgbCompositeCurvePoints, redCurvePoints, greenCurvePoints, blueCurvePoints;

- (id) initWithACVFileData:(NSData *)data {
    self = [super init];
    if (self != nil)
    {
        if (data.length == 0)
        {
            NSLog(@"failed to init ACVFile with data:%@", data);
            
            return self;
        }
        
        Byte* rawBytes = (Byte*) [data bytes];
        version        = RDInt16WithBytes(rawBytes);
        rawBytes+=2;
        
        totalCurves    = RDInt16WithBytes(rawBytes);
        rawBytes+=2;
        
        NSMutableArray *curves = [NSMutableArray new];
        
        float pointRate = (1.0 / 255);
        // The following is the data for each curve specified by count above
        for (NSInteger x = 0; x<totalCurves; x++)
        {
            unsigned short pointCount = RDInt16WithBytes(rawBytes);
            rawBytes+=2;
            
            NSMutableArray *points = [NSMutableArray new];
            // point count * 4
            // Curve points. Each curve point is a pair of short integers where
            // the first number is the output value (vertical coordinate on the
            // Curves dialog graph) and the second is the input value. All coordinates have range 0 to 255.
            for (NSInteger y = 0; y<pointCount; y++)
            {
                unsigned short y = RDInt16WithBytes(rawBytes);
                rawBytes+=2;
                unsigned short x = RDInt16WithBytes(rawBytes);
                rawBytes+=2;
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                [points addObject:[NSValue valueWithCGSize:CGSizeMake(x * pointRate, y * pointRate)]];
#else
                [points addObject:[NSValue valueWithSize:CGSizeMake(x * pointRate, y * pointRate)]];
#endif
            }
            [curves addObject:points];
        }
        rgbCompositeCurvePoints = [curves objectAtIndex:0];
        redCurvePoints = [curves objectAtIndex:1];
        greenCurvePoints = [curves objectAtIndex:2];
        blueCurvePoints = [curves objectAtIndex:3];
    }
    return self;
}

unsigned short RDInt16WithBytes(Byte* bytes) {
    uint16_t result;
    memcpy(&result, bytes, sizeof(result));
    return CFSwapInt16BigToHost(result);
}
@end

