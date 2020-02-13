//
//  RDGPUImageACVFile.h
//  RDVECore
//
//  Created by 周晓林 on 2017/11/6.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDGPUImageACVFile : NSObject
{
    short version;
    short totalCurves;
    
    NSArray *rgbCompositeCurvePoints;
    NSArray *redCurvePoints;
    NSArray *greenCurvePoints;
    NSArray *blueCurvePoints;
}

@property(strong,nonatomic) NSArray *rgbCompositeCurvePoints;
@property(strong,nonatomic) NSArray *redCurvePoints;
@property(strong,nonatomic) NSArray *greenCurvePoints;
@property(strong,nonatomic) NSArray *blueCurvePoints;

- (id) initWithACVFileData:(NSData*)data;


unsigned short RDInt16WithBytes(Byte* bytes);
@end

