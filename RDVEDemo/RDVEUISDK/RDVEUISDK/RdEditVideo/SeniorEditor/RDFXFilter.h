//
//  RDFXFilter.h
//  RDVEUISDK
//
//  Created by apple on 2019/11/26.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDFile.h"
#import "RDScene.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDFXFilter : NSObject

@property(assign,nonatomic)NSString       *ratingFrameTexturePath; //特效定格

@property(strong,nonatomic)RDCustomFilter *customFilter;       //特效参数（除时间特效）

@property(assign,nonatomic)TimeFilterType timeFilterType;       //时间特效
@property(assign,nonatomic)CMTimeRange     filterTimeRangel;     //时长

    
@property(assign,nonatomic)int              FXTypeIndex;        //特效类型
@property(assign,nonatomic)NSString         *nameStr;           //特效名字

@end

NS_ASSUME_NONNULL_END
