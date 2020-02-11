//
//  RDSoundTimeLine.h
//  RDVEUISDK
//
//  Created by apple on 2019/7/30.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RDSoundTimeLine : UIView
{
    float LineWidth;  //刻度宽度
}

@property (nonatomic, assign) float minTime;    //最小时间
@property (nonatomic, assign) float maxTime;    //最大时间
@property (nonatomic, assign) float LineWidth;  //刻度宽度

@end

NS_ASSUME_NONNULL_END
