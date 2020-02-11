//
//  RDRecordingTime.h
//  RDVEUISDK
//
//  Created by apple on 2019/8/1.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "decibelLine.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDRecordingTime : UIView

-(void)refreshTime:(float) sec atIsNode:(bool) isNode;
-(void)deleteRefreshTime:(float) sec atdecibelArray:(NSMutableArray<recordingSegment *> *) decibelArray;
-(void)clearTime;

@end

NS_ASSUME_NONNULL_END
