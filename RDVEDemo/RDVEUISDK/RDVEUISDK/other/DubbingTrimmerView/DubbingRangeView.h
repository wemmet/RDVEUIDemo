//
//  DubbingRangeView.h
//  RDVEUISDK
//
//  Created by emmet on 15/10/9.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface DubbingRangeViewFile : RDDraftDataModel

@property (nonatomic,assign) CMTime     dubbingStartTime;

@property (nonatomic,assign) CMTime     dubbingDuration;

@property (nonatomic,copy) NSString   *musicPath;

@property (nonatomic,assign) float      volume;

@property (nonatomic,assign)CGRect        home;

@property (nonatomic,assign) NSInteger  dubbingIndex;

@property (assign, nonatomic) float  piantouDuration;

@property (assign, nonatomic) float  pianweiDuration;

@end

@protocol DubbingRangeViewFile <NSObject>

@end

@interface DubbingRangeView : UIButton

@property (nonatomic,assign) CMTime     dubbingStartTime;

@property (nonatomic,assign) CMTime     dubbingDuration;

@property (nonatomic,copy) NSString   *musicPath;

@property (nonatomic,assign) float      volume;

@property (nonatomic,assign) NSInteger  dubbingIndex;

@end
