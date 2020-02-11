//
//  decibelLine.h
//  RDVEUISDK
//
//  Created by apple on 2019/7/31.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

#define maxNumber  6.0
#define maxInterval 10.0
#define MAxDecibelNumber maxInterval*60.0 + 1


@interface recordingSegment : NSObject

@property (nonatomic, strong)NSMutableArray<NSNumber *> *decibelArray;       //记录音频分贝数
@property (nonatomic, assign)int                        startValue;          //该段录音时间的起始值
@property (nonatomic, assign)int                        endValue;            //该段录音时间的结束值



@end

@interface decibelLine : UIView

@property (nonatomic, assign) int currentAudioDecibelNumber;//当前时间


@property (nonatomic, strong) NSMutableArray<recordingSegment *> *decibelArray;       //记录音频分贝数

@property (nonatomic, strong)UIColor                    *CurrentNumberColor;     //记录音频分贝数的序号为奇数 绘制分贝图的颜色
@property (nonatomic, strong)UIColor                    *lastNumberColor;     //记录音频分贝数的序号为偶数 绘制分贝图的颜色

@end
