//
//  AETemplateInfoTableViewCell.h
//  RDVEUISDK
//
//  Created by apple on 2019/11/12.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDZSlider.h"
#import "RDMoveProgress.h"

@protocol AETemplateInfoTableViewCellDelegate <NSObject>

- (void)createVideo;

- (void)playOrPause;

- (void)changeVideoProgress:(float)progress;

@end


@interface AETemplateInfoTableViewCell : UITableViewCell

@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UIButton *playBtn;

@property (nonatomic, strong) UIView *playerToolBar;

@property (nonatomic, strong) UILabel *durationLabel;

@property (nonatomic, strong) UILabel *currentTimeLabel;

@property (nonatomic, strong) RDZSlider *videoProgressSlider;

@property (nonatomic, strong) RDMoveProgress *playProgress;

@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) UILabel *tipLbl;

@property (nonatomic, strong) UILabel *textLbl;

@property (nonatomic, strong) UILabel *picLbl;

@property (nonatomic, strong) UILabel *videoLbl;

@property (nonatomic, strong) UIButton *createBtn;

@property (nonatomic, strong) UIView *repeatView;

@property (nonatomic, strong) UILabel *repeatLbl;

@property (nonatomic, strong) UISwitch *repeatSwitch;

@property (nonatomic, weak) id<AETemplateInfoTableViewCellDelegate> delegate;

- (void)setInfoDic:(NSDictionary *)infoDic cellHeight:(float)cellHeight;

- (void)setPlayBtnHidden:(BOOL)hidden;

@end
