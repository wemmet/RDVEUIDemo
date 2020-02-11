//
//  RDWordSayTextLayerParam.m
//  RDVEUISDK
//
//  Created by apple on 2019/8/12.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDWordSayTextLayerParam.h"

@implementation RDWordSayTextLayerParam

+(RDWordSayTextLayerParam*)initWordSayTextLayerParam:(CATextLayer *) textlayer atRadian:(float) radian atIsText:(BOOL) isText
{
    RDWordSayTextLayerParam * wordSayTextLayerParam = [[RDWordSayTextLayerParam alloc] init];
    wordSayTextLayerParam.textLayer = textlayer;
    wordSayTextLayerParam.textRadian = radian;
    wordSayTextLayerParam.isText = isText;
    wordSayTextLayerParam.textFactorPoint = CGPointMake(0, 0);
    wordSayTextLayerParam.textFactor = -1;
    wordSayTextLayerParam.textPoint = CGPointMake(0, 0);
    wordSayTextLayerParam.textAnchor = CGPointMake(0, 0);
    
    wordSayTextLayerParam.textLayerIndex = -1;
    wordSayTextLayerParam.textRadinIndex = -1;
    
    return wordSayTextLayerParam;
}

@end
