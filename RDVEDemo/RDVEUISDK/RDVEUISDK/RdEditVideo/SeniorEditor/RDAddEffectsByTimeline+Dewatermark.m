//
//  RDAddEffectsByTimeline+Dewatermark.m
//  RDVEUISDK
//
//  Created by apple on 2019/5/8.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline+Dewatermark.h"

@implementation RDAddEffectsByTimeline (Dewatermark)

- (void)addDewatermark {
    if (self.isEdittingEffect) {
        [self addDewatermarkFinishAction:nil];
    }
    if (!self.dewatermarkTypeView) {
        [self initDewatermarkTypeView];
    }
    self.dewatermarkTypeView.hidden = NO;
    [self.superview bringSubviewToFront:self.dewatermarkTypeView];
    [self.trimmerView addCapation:nil type:1 captionDuration:0];
    if( !self.isMosaic )
        [self addDewatermarkType:RDDewatermarkType_Dewatermark];
    else
        [self addDewatermarkType:RDDewatermarkType_Mosaic];
}

- (void)addDewatermarkFinishAction:(UIButton *)sender {
    CGRect rect = [self.dewatermarkRectView getclipRect];
    
    CaptionRangeView *view = self.trimmerView.currentCaptionView;
    if (view.file.blur) {
        RDAssetBlur *blur = view.file.blur;
        blur.intensity = self.dewatermakSlider.value;
        [blur setPointsLeftTop:rect.origin
                      rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                   rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                    leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
    }else if (view.file.mosaic) {
        RDMosaic *mosaic = view.file.mosaic;
        mosaic.mosaicSize = self.dewatermakSlider.value;
        [mosaic setPointsLeftTop:rect.origin
                        rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                     rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                      leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
    }else if (view.file.dewatermark) {
        RDDewatermark *dewatermark = view.file.dewatermark;
        dewatermark.rect = rect;
    }
    if (sender) {
        [self.trimmerView saveCurrentRangeview:YES];
    }else {
        [self.trimmerView saveCurrentRangeview:NO];
    }
    
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    NSMutableArray *newEffectArray1 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
    NSMutableArray *newEffectArray2 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
    for (CaptionRangeView *view in arr) {
        CMTimeRange timeRange = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
        if(CMTimeGetSeconds(timeRange.duration)==0){
            [view removeFromSuperview];
            continue;
        }
        if (view.file.blur) {
            RDAssetBlur *blur = view.file.blur;
            blur.timeRange = timeRange;
            [newEffectArray addObject:blur];
            [newFileArray addObject:view.file];
        }else if (view.file.mosaic) {
            RDMosaic *mosaic = view.file.mosaic;
            mosaic.timeRange = timeRange;
            [newEffectArray1 addObject:mosaic];
            [newFileArray1 addObject:view.file];
        }else if (view.file.dewatermark) {
            RDDewatermark *dewatermark = view.file.dewatermark;
            dewatermark.timeRange = timeRange;
            [newEffectArray2 addObject:dewatermark];
            [newFileArray2 addObject:view.file];
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
        [self.delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:YES];
    }
    self.addBtn.hidden = NO;
    self.finishBtn.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.deletedBtn.hidden = YES;
//    self.trimmerView.rangeSlider.hidden = YES;
    
    self.trimmerView.currentCaptionView = nil;
}

- (void)editDewatermark {
    [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
    [self.trimmerView.scrollView setContentOffset:CGPointMake(self.trimmerView.currentCaptionView.frame.origin.x, 0) animated:NO];
    
    [self.dewatermarkRectView removeFromSuperview];
    self.dewatermarkRectView = nil;
    
    CaptionRangeView *rangeView = self.trimmerView.currentCaptionView;
    [self addDewatermarkType:rangeView.file.captiontypeIndex];
    
    CGRect bounds = self.playerView.bounds;
    CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(self.exportSize, bounds);
    float  scaleValue = self.exportSize.width/videoRect.size.width;
    CGRect clipRect = CGRectZero;
    if (rangeView.file.blur) {
        RDAssetBlur *blur = rangeView.file.blur;
        CGPoint origin = CGPointFromString(blur.pointsArray[0]);
        CGPoint rightBottom = CGPointFromString(blur.pointsArray[2]);
        clipRect = CGRectMake(origin.x * videoRect.size.width, origin.y * videoRect.size.height, (rightBottom.x - origin.x) * self.exportSize.width / scaleValue, (rightBottom.y - origin.y) * self.exportSize.height / scaleValue);
    }
    else if (rangeView.file.mosaic) {
        RDMosaic *mosaic = rangeView.file.mosaic;
        CGPoint origin = CGPointFromString(mosaic.pointsArray[0]);
        CGPoint rightBottom = CGPointFromString(mosaic.pointsArray[2]);
        clipRect = CGRectMake(origin.x * videoRect.size.width, origin.y * videoRect.size.height, (rightBottom.x - origin.x) * self.exportSize.width / scaleValue, (rightBottom.y - origin.y) * self.exportSize.height / scaleValue);
    }
    else if (rangeView.file.dewatermark) {
        RDDewatermark *dewatermark = rangeView.file.dewatermark;
        clipRect = CGRectMake(dewatermark.rect.origin.x * videoRect.size.width, dewatermark.rect.origin.y * videoRect.size.height, dewatermark.rect.size.width * self.exportSize.width / scaleValue, dewatermark.rect.size.height * self.exportSize.height / scaleValue);
    }
    [self.dewatermarkRectView setClipRect:clipRect];
    CGRect rect = [self.dewatermarkRectView getclipRect];
    
    NSArray<CaptionRangeView *> *lists = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    NSMutableArray *newEffectArray1 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
    NSMutableArray *newEffectArray2 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
    for(CaptionRangeView *view in lists){
        if(view != self.trimmerView.currentCaptionView){
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }
            else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }
            else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }else {
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                [blur setPointsLeftTop:rect.origin
                              rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                           rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                            leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }
            else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                [mosaic setPointsLeftTop:rect.origin
                              rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                           rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                            leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
                [newEffectArray1 addObject:mosaic];
             
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                dewatermark.rect = rect;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
        [self.delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:NO];
    }
}

- (void)initDewatermarkTypeView {
    self.selectedDewatermarkType = RDDewatermarkType_Blur;
    self.dewatermarkTypeView = [[UIView alloc] initWithFrame:self.frame];
    self.dewatermarkTypeView.backgroundColor = TOOLBAR_COLOR;
    self.dewatermarkTypeView.hidden = YES;
    [self.superview addSubview:self.dewatermarkTypeView];
    
    float w = (kWIDTH - 15*4)/3.0;
    UIButton *blurBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    blurBtn.frame = CGRectMake(15, (self.dewatermarkTypeView.bounds.size.height/2.0 - 45)/2.0, w, 45);
    [blurBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/mosaic_blur_n"] forState:UIControlStateNormal];
    [blurBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/mosaic_blur_p"] forState:UIControlStateSelected];
    [blurBtn setTitle:RDLocalizedString(@"高斯模糊", nil) forState:UIControlStateNormal];
    [blurBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateSelected];
    [blurBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
    blurBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    blurBtn.tag = RDDewatermarkType_Blur;
    [blurBtn addTarget:self action:@selector(dewatermarkTypeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.dewatermarkTypeView addSubview:blurBtn];
    
    UIButton *mosaicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    mosaicBtn.frame = CGRectMake(15*2 + w, blurBtn.frame.origin.y, w, 45);
    [mosaicBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/去水印_马赛克1默认_"] forState:UIControlStateNormal];
    [mosaicBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/去水印_马赛克1选中_"] forState:UIControlStateSelected];
    [mosaicBtn setTitle:RDLocalizedString(@"马赛克", nil) forState:UIControlStateNormal];
    [mosaicBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateSelected];
    [mosaicBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
    mosaicBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [mosaicBtn addTarget:self action:@selector(dewatermarkTypeAction:) forControlEvents:UIControlEventTouchUpInside];
    mosaicBtn.tag = RDDewatermarkType_Mosaic;
    [self.dewatermarkTypeView addSubview:mosaicBtn];
    
    UIButton *dewatermarkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    dewatermarkBtn.frame = CGRectMake(15*3 + w*2.0, blurBtn.frame.origin.y, w, 45);
    [dewatermarkBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/去水印_去水印1默认_"] forState:UIControlStateNormal];
    [dewatermarkBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/去水印_去水印1选中_"] forState:UIControlStateSelected];
    [dewatermarkBtn setTitle:RDLocalizedString(@"去水印", nil) forState:UIControlStateNormal];
    [dewatermarkBtn setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.5] forState:UIControlStateSelected];
    [dewatermarkBtn setTitleColor:UIColorFromRGB(0x888888) forState:UIControlStateNormal];
    dewatermarkBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [dewatermarkBtn addTarget:self action:@selector(dewatermarkTypeAction:) forControlEvents:UIControlEventTouchUpInside];
    dewatermarkBtn.tag = RDDewatermarkType_Dewatermark;
    [self.dewatermarkTypeView addSubview:dewatermarkBtn];
    
    self.degreeView = [[UIView alloc] initWithFrame:CGRectMake(0, self.dewatermarkTypeView.bounds.size.height/2.0, kWIDTH, self.dewatermarkTypeView.bounds.size.height/2.0)];
    [self.dewatermarkTypeView addSubview:self.degreeView];
    
    UILabel *degreeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 50, 20)];
    degreeLbl.text = RDLocalizedString(@"程度", nil);
    degreeLbl.font = [UIFont systemFontOfSize:15.0];
    degreeLbl.textColor = [UIColor whiteColor];
    degreeLbl.textAlignment = NSTextAlignmentCenter;
    degreeLbl.hidden = YES;
    [self.degreeView addSubview:degreeLbl];
    
    self.dewatermakCurrentLabel = degreeLbl;
    
    self.dewatermakSlider = [[UISlider alloc] initWithFrame:CGRectMake(60, degreeLbl.frame.origin.y, kWIDTH - 120, 31)];
    self.dewatermakSlider.minimumValue = 0;
    self.dewatermakSlider.maximumValue = 1;
    self.dewatermakSlider.value = 0.1;
    [self.dewatermakSlider setMaximumTrackTintColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    [self.dewatermakSlider setMinimumTrackTintColor:[UIColor whiteColor]];
//    UIImage *thumbImage = [RDHelpClass rdImageWithColor:Main_Color cornerRadius:9];
    [self.dewatermakSlider setThumbImage:[RDHelpClass imageWithContentOfFile:@"jianji/剪辑_轨道球_"] forState:UIControlStateNormal];
    [self.dewatermakSlider addTarget:self action:@selector(dewatermakSliderScrub:) forControlEvents:UIControlEventValueChanged];
    [self.dewatermakSlider addTarget:self action:@selector(dewatermakSliderEndScrub:) forControlEvents:UIControlEventTouchUpInside];
    [self.dewatermakSlider addTarget:self action:@selector(dewatermakSliderEndScrub:) forControlEvents:UIControlEventTouchCancel];
    [self.degreeView addSubview:self.dewatermakSlider];
}

- (void)dewatermarkTypeAction:(UIButton *)sender {
    [self addDewatermarkType:sender.tag];
}

- (void)addDewatermarkType:(RDDewatermarkType)type {
    self.isSettingEffect = YES;
    UIButton *prevBtn = [self.dewatermarkTypeView viewWithTag:self.selectedDewatermarkType];
    prevBtn.selected = NO;
    self.selectedDewatermarkType = type;
    UIButton *selectedBtn = [self.dewatermarkTypeView viewWithTag:self.selectedDewatermarkType];
    selectedBtn.selected = YES;
    BOOL isNewAdd = NO;
    if (!self.dewatermarkRectView) {
        if (!self.oldMaterialEffectFile) {
            isNewAdd = YES;
        }
        CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(self.exportSize, CGRectMake(0, 0, self.playerView.bounds.size.width, self.playerView.bounds.size.height));
        self.dewatermarkRectView = [[RDUICliper alloc] initWithView:self.playerView freedom:YES];
        self.dewatermarkRectView.minEdge = 30;
        [self.dewatermarkRectView setFrameRect:videoRect];
        self.dewatermarkRectView.clipsToBounds = YES;
        [self.dewatermarkRectView.playBtn removeFromSuperview];
        self.dewatermarkRectView.isOutsideTransparent = YES;
        [self.dewatermarkRectView setVideoSize:self.exportSize];
        [self.dewatermarkRectView setCropType:kCropTypeFreedom];
        self.dewatermarkRectView.delegate = self;
        
        float width = 270;
        float screenScal = self.exportSize.width / videoRect.size.width;
        width /= screenScal;
        
        CGRect clipRect = CGRectMake((videoRect.size.width - width)/2.0, (videoRect.size.height - width)/2.0, width, width);
        [self.dewatermarkRectView setClipRect:clipRect];
    }else {
        if (!self.dewatermarkRectView.superview) {
            [self.playerView addSubview:self.dewatermarkRectView];
        }
    }
    if (!self.oldMaterialEffectFile) {
        CGRect rect = [self.dewatermarkRectView getclipRect];
        if (type == RDDewatermarkType_Blur) {
            self.degreeView.hidden = NO;
            RDAssetBlur *blur = [[RDAssetBlur alloc] init];
            blur.intensity = self.dewatermakSlider.value;
            blur.timeRange = self.trimmerView.currentCaptionView.file.timeRange;
            [blur setPointsLeftTop:rect.origin
                          rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                       rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                        leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
            [self.trimmerView changeDewatermark:blur typeIndex:type];
        }
        else if (type == RDDewatermarkType_Mosaic) {
            self.degreeView.hidden = NO;
            RDMosaic *mosaic = [[RDMosaic alloc] init];
            mosaic.timeRange = self.trimmerView.currentCaptionView.file.timeRange;
            mosaic.mosaicSize = self.dewatermakSlider.value;
            [mosaic setPointsLeftTop:rect.origin
                            rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                         rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                          leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
            
            [self.trimmerView changeDewatermark:mosaic typeIndex:type];
        }else {
            self.degreeView.hidden = YES;
            RDDewatermark *dewatermark = [[RDDewatermark alloc] init];
            dewatermark.rect = rect;
            dewatermark.timeRange = self.trimmerView.currentCaptionView.file.timeRange;
            [self.trimmerView changeDewatermark:dewatermark typeIndex:type];
        }
    }    
    if (isNewAdd) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(changeDewatermarkType:dewatermarkRectView:)]) {
            [self.delegate changeDewatermarkType:type dewatermarkRectView:self.dewatermarkRectView];
        }
    }else {
        NSArray<CaptionRangeView *> *lists = [self.trimmerView getTimesFor_videoRangeView_withTime];
        
        NSMutableArray *newEffectArray = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
        NSMutableArray *newEffectArray1 = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
        NSMutableArray *newEffectArray2 = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
        for(CaptionRangeView *view in lists){
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
            [self.delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:NO];
        }
    }
}
-(void)dewatermakSliderEndScrub:(UISlider *)slider {
    NSArray<CaptionRangeView *> *lists = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    self.dewatermakCurrentLabel.hidden = YES;
    self.dewatermakCurrentLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.dewatermakCurrentLabel.frame = CGRectMake(slider.value*self.dewatermakSlider.frame.size.width+self.dewatermakSlider.frame.origin.x - self.dewatermakCurrentLabel.frame.size.width/2.0, self.dewatermakSlider.frame.origin.y - self.dewatermakCurrentLabel.frame.size.height + 5, self.dewatermakCurrentLabel.frame.size.width, self.dewatermakCurrentLabel.frame.size.height);
    self.dewatermakCurrentLabel.text = [NSString stringWithFormat:@"%d%",(int)(slider.value*100.0)];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    NSMutableArray *newEffectArray1 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
    NSMutableArray *newEffectArray2 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
    for(CaptionRangeView *view in lists){
        if(view != self.trimmerView.currentCaptionView){
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }else {
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                blur.intensity = slider.value;
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                mosaic.mosaicSize = slider.value;
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
        [self.delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:NO];
    }
}


- (void)dewatermakSliderScrub:(UISlider *)slider {
    NSArray<CaptionRangeView *> *lists = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    self.dewatermakCurrentLabel.hidden = NO;
    self.dewatermakCurrentLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    self.dewatermakCurrentLabel.frame = CGRectMake(slider.value*self.dewatermakSlider.frame.size.width+self.dewatermakSlider.frame.origin.x - self.dewatermakCurrentLabel.frame.size.width/2.0, self.dewatermakSlider.frame.origin.y - self.dewatermakCurrentLabel.frame.size.height + 5, self.dewatermakCurrentLabel.frame.size.width, self.dewatermakCurrentLabel.frame.size.height);
    self.dewatermakCurrentLabel.text = [NSString stringWithFormat:@"%d%",(int)(slider.value*100.0)];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    NSMutableArray *newEffectArray1 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
    NSMutableArray *newEffectArray2 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
    for(CaptionRangeView *view in lists){
        if(view != self.trimmerView.currentCaptionView){
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }else {
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                blur.intensity = slider.value;
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                mosaic.mosaicSize = slider.value;
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
        [self.delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:NO];
    }
}

- (void)startAddDewatermark
{
    if(self.isAddingEffect)
    {
        self.trimmerView.rangeSlider.hidden= YES;
    }
    self.currentTimeLbl.hidden = NO;
    
    if (!self.dewatermarkTypeView.hidden || self.isEdittingEffect) {
        self.addBtn.hidden = YES;
        self.deletedBtn.hidden = YES;
        self.finishBtn.hidden = NO;
        self.cancelBtn.hidden = NO;
        [self.dewatermarkRectView removeFromSuperview];
        
        if (self.isEdittingEffect) {
            [self addDewatermarkFinishAction:nil];
        }
    }else {
        [self addDewatermarkFinishAction:self.finishBtn];
    }
}

- (void)preAddDewatermark:(CMTimeRange)timeRange
                    blurs:(NSMutableArray *)blurs
                  mosaics:(NSMutableArray *)mosaics
             dewatermarks:(NSMutableArray *)dewatermarks
{
    CGRect rect = [self.dewatermarkRectView getclipRect];
    
    CaptionRangeView *view = [[self.trimmerView getTimesFor_videoRangeView] lastObject];
    view.file.timeRange = timeRange;
    if (view.file.blur) {
        RDAssetBlur *blur = view.file.blur;
        blur.timeRange = timeRange;
        [blur setPointsLeftTop:rect.origin
                      rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                   rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                    leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
        [blurs addObject:blur];
    }else if (view.file.mosaic) {
        RDMosaic *mosaic = view.file.mosaic;
        mosaic.timeRange = timeRange;
        [mosaic setPointsLeftTop:rect.origin
                      rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                   rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                    leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
        [mosaics addObject:mosaic];
    }else if (view.file.dewatermark) {
        RDDewatermark *dewatermark = view.file.dewatermark;
        dewatermark.timeRange = timeRange;
        dewatermark.rect = rect;
        [dewatermarks addObject:dewatermark];
    }
}

#pragma mark - CropDelegate
- (void)cropViewDidChangeClipValue:(CGRect)rect clipRect:(CGRect)clipRect {
    if (!self.trimmerView.currentCaptionView) {
        [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
    }
    NSArray<CaptionRangeView *> *lists = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    NSMutableArray *newEffectArray1 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray1 = [NSMutableArray array];
    NSMutableArray *newEffectArray2 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray2 = [NSMutableArray array];
    for(CaptionRangeView *view in lists){
        if(view != self.trimmerView.currentCaptionView){
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }else {
            if (view.file.blur) {
                RDAssetBlur *blur = view.file.blur;
                [blur setPointsLeftTop:rect.origin
                              rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                           rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                            leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
                [newEffectArray addObject:blur];
                [newFileArray addObject:view.file];
            }else if (view.file.mosaic) {
                RDMosaic *mosaic = view.file.mosaic;
                [mosaic setPointsLeftTop:rect.origin
                              rightTop:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y)
                           rightBottom:CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
                            leftBottom:CGPointMake(rect.origin.x, rect.origin.y + rect.size.height)];
                [newEffectArray1 addObject:mosaic];
                [newFileArray1 addObject:view.file];
            }else if (view.file.dewatermark) {
                RDDewatermark *dewatermark = view.file.dewatermark;
                dewatermark.rect = rect;
                [newEffectArray2 addObject:dewatermark];
                [newFileArray2 addObject:view.file];
            }
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateDewatermark:newBlurFileArray:newMosaicArray:newMosaicArray:newDewatermarkArray:newDewatermarkFileArray:isSaveEffect:)]) {
        [self.delegate updateDewatermark:newEffectArray newBlurFileArray:newFileArray newMosaicArray:newEffectArray1 newMosaicArray:newFileArray1 newDewatermarkArray:newEffectArray2 newDewatermarkFileArray:newFileArray2 isSaveEffect:NO];
    }
}

@end
