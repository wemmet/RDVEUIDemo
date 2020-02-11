//
//  RDAddEffectsByTimeline+Subtitle.m
//  RDVEUISDK
//
//  Created by apple on 2019/5/6.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline+Subtitle.h"
#import "RDFileDownloader.h"
#import "RDSVProgressHUD.h"

@implementation RDAddEffectsByTimeline (Subtitle)

- (void)initSubtitleConfigEditView:(BOOL)showInView {
    if(!self.subtitleConfigView){
        CGRect rect = self.superview.frame;
        rect.size.height =  rect.size.height + kToolbarHeight;
        self.subtitleConfigView = [[SubtitleScrollView alloc] initWithFrame:rect];
        self.subtitleConfigView.fontResourceURL = self.editConfiguration.fontResourceURL;
        self.subtitleConfigView.delegate = self;
        self.subtitleConfigView.textAlpha = 1.0;
        self.subtitleConfigView.hidden = YES;
        if (showInView) {
            [self.subtitleConfigView showInView];
        }
        [self.superview.superview insertSubview:self.subtitleConfigView aboveSubview:self];
    }
}



- (void)addSubtitle {
    if(![self checkSubtitleIconDownload]){
        return;
    }
    
    self.subtitleConfigView.hidden = NO;
    self.subtitleConfigView.isEditting = NO;
    self.subtitleConfigView.inAnimationIndex = 0;
    self.subtitleConfigView.outAnimationIndex = 0;
    self.subtitleConfigView.selectColorItemIndex = -1;
    self.subtitleConfigView.selectBorderColorItemIndex = -1;
    self.subtitleConfigView.selectShadowColorIndex = -1;
    self.subtitleConfigView.selectBgColorIndex = -1;
    if( !self.isCover )
        self.subtitleConfigView.captionRangeView = [self.trimmerView addCapation:nil type:4 captionDuration:3];
    else
        self.subtitleConfigView.captionRangeView = [self.trimmerView addCapation:nil type:4 captionDuration:0.5];

    [self.subtitleConfigView clickToolItem:nil];
    [self.subtitleConfigView touchescaptionTypeViewChildWithIndex:0];
}

//保存字幕
- (void)saveSubtitle:(BOOL)isFinish {
    [self saveSubtitleOrEffectWithPasterView:self.subtitleConfigView.pasterTextView];
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>*newFileArray = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption= view.file.caption;
        if(ppcaption){
            ppcaption.timeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
            if(CMTimeGetSeconds(ppcaption.timeRange.duration)==0){
                [view removeFromSuperview];
                continue;
            }
            ppcaption.position    = view.file.centerPoint;
            ppcaption.imageAnimate.inType = [RDHelpClass captionAnimateToRDCaptionAnimate:view.file.inAnimationIndex];
            ppcaption.imageAnimate.outType = [RDHelpClass captionAnimateToRDCaptionAnimate:view.file.outAnimationIndex];
            ppcaption.music       = nil;
            ppcaption.angle       = view.file.rotationAngle;
            ppcaption.scale       = view.file.scale;
            ppcaption.tColor      = view.file.tColor ? view.file.tColor : view.file.caption.tColor;
            ppcaption.strokeColor = view.file.strokeColor ? view.file.strokeColor : view.file.caption.strokeColor;
            if(view.file.caption.frameArray.count>0)
                ppcaption.frameArray      = @[view.file.caption.frameArray[0]];
            ppcaption.pText       = view.titleLabel.text;
            [newEffectArray addObject:ppcaption];
            [newFileArray addObject:view.file];
        }
    }
    
    [self.subtitleConfigView.pasterTextView removeFromSuperview];
    self.subtitleConfigView.pasterTextView  = nil;
    [self.subtitleConfigView clear];
    [self.subtitleConfigView removeFromSuperview];
    self.subtitleConfigView = nil;
    [self.syncContainer removeFromSuperview];
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:isFinish];
    }
}

- (void)saveSubtitleTimeRange {
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>*newFileArray = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption= view.file.caption;
        RDMusic *music = view.file.music;
        if(ppcaption){
            ppcaption.timeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
            if(CMTimeGetSeconds(ppcaption.timeRange.duration)==0){
                [view removeFromSuperview];
                continue;
            }
            [newEffectArray addObject:ppcaption];
            [newFileArray addObject:view.file];
        }
        else if( music )
        {
            music.effectiveTimeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
            if(CMTimeGetSeconds(music.effectiveTimeRange.duration)==0){
                [view removeFromSuperview];
                continue;
            }
            [newEffectArray addObject:music];
            [newFileArray addObject:view.file];
        }
    }
    self.trimmerView.rangeSlider.hidden = YES;
    self.finishBtn.hidden = YES;
    self.deletedBtn.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.addBtn.hidden = NO;
    if( self.currentEffect == RDAdvanceEditType_Subtitle )
        self.speechRecogBtn.hidden = self.speechRecogBtn.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:YES];
    }
    [self.trimmerView cancelCurrent];
}

- (void)editSubtitle {
    self.trimmerView.scrollView.scrollEnabled = YES;
    CaptionRangeView * currentRangeView = [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
    [self.trimmerView getcurrentCaption:currentRangeView.file.captionId];
    
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    [self.subtitleConfigView setContentTextFieldText:currentRangeView.file.captionText];
    [self.syncContainer removeFromSuperview];
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption= view.file.caption;
        if(self.trimmerView.currentCaptionView != view){
            [newEffectArray addObject:ppcaption];
            [newFileArray addObject:view.file];
        }
    }
    self.oldMaterialEffectFile = [currentRangeView.file mutableCopy];
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:NO];
    }
    self.subtitleConfigView.hidden = NO;
    [self.trimmerView touchesUpInslide];
    self.subtitleConfigView.isEditting = YES;
    [self checkSubtitleEditBefor:currentRangeView.file.captiontypeIndex];
}

//初始化字幕
- (void)checkSubtitleEditBefor:(NSInteger)typeIndex{
    CaptionRangeView *rangeView = self.trimmerView.currentCaptionView;
    float sc                 = rangeView.file.scale;
    float ppsc               = (rangeView.file.caption.size.width * self.exportSize.width)/ (float) rangeView.file.caption.size.width < 1 ? (rangeView.file.caption.size.width * self.exportSize.width)/ (float) rangeView.file.caption.size.width : 1;
    CGFloat   radius         = atan2f(rangeView.file.captionTransform.b, rangeView.file.captionTransform.a);
    UIColor  *fontstrokeColor = rangeView.file.caption.strokeColor;
    UIColor  *fontTextColor  = rangeView.file.caption.tColor;
    NSString *fontName       = rangeView.file.caption.tFontName;
//    NSString *fontCode       = rangeView.file.fontCode;
    float fontSize           = rangeView.file.tFontSize / (self.exportSize.width/self.syncContainer.bounds.size.width);//bug：每编辑一次字幕，字幕就会变大
    RDCaptionTextAlignment alignment = rangeView.file.caption.tAlignment;
    CGPoint pushInPoint = rangeView.file.caption.textAnimate.pushInPoint;
    CGPoint pushOutPoint = rangeView.file.caption.textAnimate.pushOutPoint;
    BOOL isBold = rangeView.file.caption.isBold;
    BOOL isItalic = rangeView.file.caption.isItalic;
    BOOL isVerticalText = rangeView.file.caption.isVerticalText;
    BOOL isShadow = rangeView.file.caption.isShadow;
    float textAlpha = rangeView.file.caption.textAlpha;
    float strokeAlpha = rangeView.file.caption.strokeAlpha;
    float strokeWidth = rangeView.file.caption.isStroke ? rangeView.file.caption.strokeWidth : 0;
    CGSize  tShadowOffset  = rangeView.file.caption.tShadowOffset;
    UIColor  *tShadowColor  = rangeView.file.caption.tShadowColor;
    NSString *captionTextField_text = rangeView.file.captionText;
    NSInteger inAnimationIndex = rangeView.file.inAnimationIndex;
    NSInteger outAnimationIndex = rangeView.file.outAnimationIndex;
    UIColor *bgColor = rangeView.file.caption.backgroundColor;
    float opacity = rangeView.file.caption.opacity;
    [self initSubtitleConfigEditView:NO];
    
    self.subtitleConfigView.hidden = NO;
    self.subtitleConfigView.captionRangeView = self.trimmerView.currentCaptionView;
    self.subtitleConfigView.isEditting = YES;
    self.subtitleConfigView.subtitleAlpha = rangeView.file.caption.opacity;
    self.subtitleConfigView.isBold = isBold;
    self.subtitleConfigView.isItalic = isItalic;
    [self.subtitleConfigView setIsVerticalText:isVerticalText];
    self.subtitleConfigView.isShadow = isShadow;
    self.subtitleConfigView.shadowWidth = tShadowOffset.width;
    self.subtitleConfigView.textAlpha = textAlpha;
    self.subtitleConfigView.strokeWidth = strokeWidth;
    self.subtitleConfigView.strokeAlpha = strokeAlpha;
    self.subtitleConfigView.selectBgColorIndex = rangeView.file.selectBgColorIndex;
    self.subtitleConfigView.inAnimationIndex     = inAnimationIndex;
    self.subtitleConfigView.outAnimationIndex     = outAnimationIndex;
    self.subtitleConfigView.selectColorItemIndex     = rangeView.file.selectColorItemIndex;
    self.subtitleConfigView.selectBorderColorItemIndex = rangeView.file.selectBorderColorItemIndex;
    self.subtitleConfigView.selectShadowColorIndex = rangeView.file.selectShadowColorIndex;
    self.subtitleConfigView.selectFontItemIndex        = rangeView.file.selectFontItemIndex;
    self.subtitleConfigView.selectedTypeId        = rangeView.file.selectTypeId;
    [self.subtitleConfigView showInView];
    
    self.subtitleConfigView.subtitleSize = sc;
    [self.subtitleConfigView setContentTextFieldText:captionTextField_text];
    [self.subtitleConfigView touchescaptionTypeViewChildWithIndex:typeIndex];
    
//    self.subtitleConfigView.pasterTextView.fontCode = fontCode;
    self.subtitleConfigView.pasterTextView.fontPath = rangeView.file.fontPath;
    self.subtitleConfigView.pasterTextView.contentLabel.alpha = opacity;
    self.subtitleConfigView.pasterTextView.labelBgView.backgroundColor = bgColor;
    self.subtitleConfigView.pasterTextView.contentLabel.fontColor = fontTextColor;
    self.subtitleConfigView.pasterTextView.contentLabel.strokeColor = fontstrokeColor;
    self.subtitleConfigView.pasterTextView.contentLabel.textAlpha = textAlpha;
    self.subtitleConfigView.pasterTextView.contentLabel.strokeAlpha = strokeAlpha;
    self.subtitleConfigView.pasterTextView.contentLabel.strokeWidth = strokeWidth;
    self.subtitleConfigView.pasterTextView.shadowLbl.fontColor = fontTextColor;
    self.subtitleConfigView.pasterTextView.shadowLbl.strokeColor = fontTextColor;
    self.subtitleConfigView.pasterTextView.shadowLbl.textAlpha = textAlpha;
    self.subtitleConfigView.pasterTextView.shadowLbl.strokeAlpha = strokeAlpha;
    self.subtitleConfigView.pasterTextView.shadowLbl.strokeWidth = strokeWidth;
    self.subtitleConfigView.pasterTextView.isBold = isBold;
    self.subtitleConfigView.pasterTextView.isItalic = isItalic;
    self.subtitleConfigView.pasterTextView.isVerticalText = isVerticalText;
    self.subtitleConfigView.pasterTextView.isShadow = isShadow;
    self.subtitleConfigView.pasterTextView.shadowOffset = tShadowOffset;
    self.subtitleConfigView.pasterTextView.shadowColor = tShadowColor;
    [self.subtitleConfigView.pasterTextView setFontName:fontName];
    [self.subtitleConfigView.pasterTextView setFontSize:fontSize];
    [self.subtitleConfigView.pasterTextView setTextString:captionTextField_text adjustPosition:NO];
    [self.subtitleConfigView.pasterTextView setAlignment:(NSTextAlignment)alignment];
    [self.subtitleConfigView.pasterTextView.contentLabel setNeedsDisplay];
    [self.subtitleConfigView.pasterTextView.shadowLbl setNeedsDisplay];
    CGAffineTransform transform2 = CGAffineTransformMakeRotation(radius);    
    self.subtitleConfigView.pasterTextView.transform = CGAffineTransformScale(transform2, sc*ppsc, sc*ppsc);
    CGPoint center = CGPointMake(self.syncContainer.frame.size.width * rangeView.file.centerPoint.x, self.syncContainer.frame.size.height * rangeView.file.centerPoint.y);
    self.subtitleConfigView.pasterTextView.center = center;
    
    [self.trimmerView changeCurrentRangeviewFile:nil
                                          tColor:fontTextColor
                                     strokeColor:fontstrokeColor
                                        fontName:fontName
                                        fontCode:nil//fontCode
                                       typeIndex:self.trimmerView.currentCaptionView.file.captiontypeIndex
                                       frameSize:CGSizeZero
                                     captionText:captionTextField_text
                                        aligment:alignment
                              inAnimateTypeIndex:inAnimationIndex
                             outAnimateTypeIndex:outAnimationIndex
                                     pushInPoint:pushInPoint
                                    pushOutPoint:pushOutPoint
                                     captionView:self.subtitleConfigView.captionRangeView];
    
    float fontScale  = 1.2f * ((sc * ppsc) - 1);
    [self.subtitleConfigView setSubtitleSize:fontScale];
    [self.subtitleConfigView.pasterTextView setFramescale: sc * ppsc];
}

- (void)startSpeechRecog {
    self.speechRecogBtn.hidden = YES;
    
    [RDSVProgressHUD showWithStatus:RDLocalizedString(@"正在识别中，请稍等...", nil) maskType:RDSVProgressHUDMaskTypeGradient];
    
    self.speechRecogCount = 0;
    self.speechRecogTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(isRecogCompletion)
                                                      userInfo:nil
                                                       repeats:YES];
    //以腾讯云为例
    [self.fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.fileType == kFILEVIDEO && !obj.isReverse) {
            [RDVECore video2audiowithtype:AVFileTypeAppleM4A
                                 videoUrl:obj.contentURL
                                trimStart:CMTimeGetSeconds(obj.videoTrimTimeRange.start)
                                 duration:CMTimeGetSeconds(obj.videoTrimTimeRange.duration)
                         outputFolderPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"speechRecog"]
                               samplerate:8000
                               completion:^(BOOL result, NSString *outputFilePath) {
                                   if (result && outputFilePath.length > 0) {
                                       NSDictionary *resultCallBack = [RDHelpClass uploadAudioWithPath:outputFilePath appId:self.editConfiguration.tencentAIRecogConfig.appId secretId:self.editConfiguration.tencentAIRecogConfig.secretId secretKey:self.editConfiguration.tencentAIRecogConfig.secretKey serverCallbackPath:self.editConfiguration.tencentAIRecogConfig.serverCallbackPath];
                                       if (resultCallBack && [[resultCallBack objectForKey:@"code"] intValue] == 0) {
                                           NSString *requestId = [resultCallBack objectForKey:@"requestId"];
                                           NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:requestId, @"requestId", [NSNumber numberWithInteger:idx], @"fileIndex", nil];
                                           [self.requestIdArray addObject:dic];
                                           [self getSpeechRecogCallBackWithDic:dic];
                                       }else if (resultCallBack && self.delegate && [self.delegate respondsToSelector:@selector(uploadSpeechFailed:)]) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                if( [[resultCallBack objectForKey:@"code"] intValue] == 1016 )
                                                   [self.delegate uploadSpeechFailed:RDLocalizedString(@"语音识别失败（超出当月试用次数）！",nil)];
                                                else
                                                    [self.delegate uploadSpeechFailed:resultCallBack[@"message"]];
                                               
                                               self.speechRecogBtn.hidden = NO;
                                           });
                                       }
                                   }
                               }];
        }
    }];
}

- (void)isRecogCompletion {
    if (self.requestIdArray.count == 0 || self.speechRecogCount >= 60) {
        [self.speechRecogTimer invalidate];
        self.speechRecogTimer = nil;
        if (self.requestIdArray.count > 0) {
            for (NSDictionary *dic in self.requestIdArray) {
                [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(getSpeechRecogCallBackWithDic:) object:dic];
            }
            [self.requestIdArray removeAllObjects];
        }else {            
            self.speechRecogBtn.selected = YES;
        }
        [RDSVProgressHUD dismiss];
    }
    self.speechRecogCount++;
}

- (void)getSpeechRecogCallBackWithDic:(NSDictionary *)dic {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *resultCallBack = [RDHelpClass updateInfomation:[NSMutableDictionary dictionaryWithObject:dic[@"requestId"] forKey:@"requestId"] andUploadUrl:@"http://d.56show.com/filemanage2/public/filemanage/voice2text/findText"];
        if (resultCallBack) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([resultCallBack[@"code"] intValue] == 0) {
                    if ([self.requestIdArray containsObject:dic]) {
                        [self.requestIdArray removeObject:dic];
                    }
                    NSString *text = [resultCallBack[@"data"] objectForKey:@"text"];
                    if (text.length > 0) {
                        [self addSpeechSubtitleWithText:text fileIndex:[dic[@"fileIndex"] integerValue]];
                    }
                    if (self.requestIdArray.count == 0) {
                        self.speechRecogBtn.selected = YES;
                        [RDSVProgressHUD dismiss];
                    }
                }else {
//                    NSLog(@"requestId:%@ errorCode:%d msg:%@", dic[@"requestId"], [resultCallBack[@"code"] intValue], resultCallBack[@"msg"]);
                    [self performSelector:@selector(getSpeechRecogCallBackWithDic:) withObject:dic afterDelay:1.0];
                }
            });
        }
    });
}

- (void)addSpeechSubtitleWithText:(NSString *)text fileIndex:(NSInteger)fileIndex {
    NSString *timeText = [text stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    NSArray *contentArray = [timeText componentsSeparatedByString:@"\n"];
    NSLog(@"%@", timeText);
    float firstStartTime = 0.0;
    float startDuration = 0.0;
    if (fileIndex > 0) {
        for (int i = 0; i < fileIndex; i++) {
            RDFile *file = self.fileList[i];
            if (file.fileType == kFILEVIDEO) {
                if (file.isReverse) {
                    if(CMTimeCompare(file.reverseVideoTrimTimeRange.duration, kCMTimeZero) == 1){
                        startDuration += CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration);
                    }else if(CMTimeCompare(file.reverseVideoTimeRange.duration, kCMTimeZero) == 1) {
                        startDuration += CMTimeGetSeconds(file.reverseVideoTimeRange.duration);
                    }else {
                        startDuration += CMTimeGetSeconds(file.reverseDurationTime);
                    }
                }else {
                    if(CMTimeCompare(file.videoTrimTimeRange.duration, kCMTimeZero) == 1){
                        startDuration += CMTimeGetSeconds(file.videoTrimTimeRange.duration);
                    }else if(CMTimeCompare(file.videoTimeRange.duration, kCMTimeZero) == 1) {
                        startDuration += CMTimeGetSeconds(file.videoTimeRange.duration);
                    }else {
                        startDuration += CMTimeGetSeconds(file.videoDurationTime);
                    }
                }
            }else {
                if (CMTimeCompare(file.imageTimeRange.duration, kCMTimeZero) == 1) {
                    startDuration += CMTimeGetSeconds(file.imageTimeRange.duration);
                }else {
                    startDuration += CMTimeGetSeconds(file.imageDurationTime);
                }
            }
        }
    }
    BOOL isStereo = NO;
    for (int i = 0; i < contentArray.count; i++) {
        NSLog(@"i:%d", i);
        NSString *obj = contentArray[i];
        if ([obj hasPrefix:@"["]) {
            obj = [obj substringToIndex:obj.length - 1];
            NSRange range = [obj rangeOfString:@","];
            if (range.location != NSNotFound) {
                NSString *startTimeStr = [obj substringWithRange:NSMakeRange(1, range.location - 1)];
                float startTime = [RDHelpClass timeFromStr:startTimeStr];
                if (i == 0) {
                    firstStartTime = startTime;
                }
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                [dic setObject:[NSNumber numberWithFloat:startDuration + startTime] forKey:@"startTime"];
                obj = [obj substringFromIndex:range.location + 1];
                range = [obj rangeOfString:@"]"];
                if (range.location != NSNotFound) {
                    NSString *endTimeStr = [obj substringToIndex:range.location];
                    if (!isStereo && [endTimeStr containsString:@","]) {
                        isStereo = YES;
                    }
                    float endTime = [RDHelpClass timeFromStr:endTimeStr];
                    [dic setObject:[NSNumber numberWithFloat:endTime - startTime] forKey:@"duration"];
                    [dic setObject:[obj substringFromIndex:range.location + 1] forKey:@"textContent"];
                    if ([dic[@"textContent"] length] > 0) {
                        [self addSpeechSubtitleWithDic:dic];
                    }
                    if (isStereo) {
                        i++;
                    }
                }
            }
        }
    }
    
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>*newFileArray = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption= view.file.caption;
        if(ppcaption){
            [newEffectArray addObject:ppcaption];
            [newFileArray addObject:view.file];
        }
    }
    self.trimmerView.rangeSlider.hidden = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:YES];
    }
    float progress = (startDuration + firstStartTime)/self.thumbnailCoreSDK.duration;
    [self.trimmerView setProgress:progress animated:NO];
}

- (void)addSpeechSubtitleWithDic:(NSDictionary *)dic {
    float progress = [dic[@"startTime"] floatValue]/self.thumbnailCoreSDK.duration;
    [self.trimmerView setProgress:progress animated:NO];
    
    CGRect videoRect = AVMakeRectWithAspectRatioInsideRect(self.exportSize, self.playerView.bounds);
    float  scaleValue = ((self.exportSize.width > self.exportSize.height)?self.exportSize.width/videoRect.size.width:self.exportSize.height/videoRect.size.height);
    NSString *text = RDLocalizedString(@"点击输入字幕", nil);
//    dic[@"textContent"];
    NSString *fontName = [[UIFont systemFontOfSize:10] fontName];
    float fontSize = 20.0;
    CGSize size = [text boundingRectWithSize:CGSizeMake(videoRect.size.width - 16, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName:[UIFont fontWithName:fontName size:fontSize]}
                                     context:nil].size;
    
    RDCaption *caption = [RDCaption new];
    caption.position = CGPointMake(0.5, (videoRect.size.height - size.height)/videoRect.size.height);
    caption.size = CGSizeMake(size.width/videoRect.size.width, 0.1);
    caption.tFrame = CGRectMake(size.width * scaleValue / 2.0, size.height * scaleValue / 2.0, size.width * scaleValue, size.height * scaleValue);
    caption.angle = 0;
    caption.pText = text;
    caption.tColor = [UIColor whiteColor];
    caption.isShadow = YES;
    caption.tFontSize = fontSize * scaleValue;
    caption.tFontName = fontName;
    caption.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds([dic[@"startTime"] floatValue], TIMESCALE), CMTimeMakeWithSeconds([dic[@"duration"] floatValue], TIMESCALE));
    caption.imageAnimate = nil;
    caption.textAnimate = nil;
    
    CaptionRangeView *rangeView = [self.trimmerView addCapation:nil type:2 captionDuration:[dic[@"duration"] floatValue]];
    rangeView.file.captionText = text;
    [rangeView setTitle:text forState:UIControlStateNormal];    
    rangeView.file.caption = caption;
    rangeView.file.captiontypeIndex = 0;
    rangeView.file.rotationAngle = 0;
    rangeView.file.centerPoint = caption.position;
    rangeView.file.scale = 1.0;
    rangeView.file.home = rangeView.frame;
    rangeView.file.tFontSize = caption.tFontSize;
    [self.trimmerView saveCurrentRangeview:NO];
}

#pragma mark- SubtitleScrollViewDelegate
/**选择字幕样式*/
- (void)changeType:(NSString *)configPath index:(NSInteger)index subtitleScrollView:(SubtitleScrollView *)subtitleScrollView Name:(NSString *) name coverPath:(NSString *)coverPath
{
    self.subtitleEffectConfigPath = [configPath stringByDeletingLastPathComponent];
    CGPoint center = CGPointZero;
    RDCaption *caption = [self getCurrentCaptionConfig];
    //    CGSize size = CGSizeMake(caption.size.width/2.0, caption.size.height/2.0);
    
    if(subtitleScrollView.pasterTextView){
        
        center = subtitleScrollView.pasterTextView.center;
        CaptionRangeView *rangeView = self.trimmerView.currentCaptionView;
        caption.opacity = rangeView.file.caption.opacity;
        caption.backgroundColor = rangeView.file.bgColor;
        if(rangeView.file.selectBorderColorItemIndex > 0){
            caption.strokeColor = rangeView.file.strokeColor;
        }else{
            caption.strokeColor = [UIColor clearColor];
        }
        caption.strokeAlpha = rangeView.file.caption.strokeAlpha;
        caption.strokeWidth = rangeView.file.caption.strokeWidth;
        if(rangeView.file.selectColorItemIndex > 0){
            caption.tColor  = rangeView.file.tColor;
        }
        caption.textAlpha = rangeView.file.caption.textAlpha;
        
        if( rangeView.file.captionText )
            caption.pText = rangeView.file.captionText;
        
        if(rangeView.file.selectFontItemIndex !=0){
            caption.tFontName       = rangeView.file.caption.tFontName;
        }
        caption.tFontSize           = rangeView.file.tFontSize / (self.exportSize.width/self.syncContainer.bounds.size.width);//bug：每编辑一次字幕，字幕就会变大
        caption.tAlignment = rangeView.file.caption.tAlignment;
        caption.textAnimate.type = rangeView.file.caption.textAnimate.type;
        caption.textAnimate.pushInPoint = rangeView.file.caption.textAnimate.pushInPoint;
        caption.textAnimate.pushOutPoint = rangeView.file.caption.textAnimate.pushOutPoint;
        caption.textAnimate.inType = rangeView.file.caption.textAnimate.inType;
        caption.textAnimate.outType = rangeView.file.caption.textAnimate.outType;
        
        caption.isBold = rangeView.file.caption.isBold;
        caption.isItalic = rangeView.file.caption.isItalic;
        caption.isShadow = rangeView.file.caption.isShadow;
        caption.tShadowOffset  = rangeView.file.caption.tShadowOffset;
        caption.tShadowColor  = rangeView.file.caption.tShadowColor;
        if( (rangeView.file.captionText.length>0) && ( self.cancelBtn.hidden ) )
            caption.pText = rangeView.file.captionText;
        //        caption.isStretch = YES;
        //        caption.stretchRect = CGRectMake(0.3, 0.3, 0.4, 0.4);
        if( subtitleScrollView.isModifyText )
        {
            [subtitleScrollView setContentTextFieldText:caption.pText];
        }
#if 0
        else
        {
            if( [self.subtitleEffectConfig[@"textContent"] isEqualToString:RDLocalizedString(@"点击输入字幕", nil)] )
            {
                caption.strokeWidth = 2.0;
                caption.strokeColor = UIColorFromRGB(0x000000);
                caption.strokeAlpha = 1.0;
                [subtitleScrollView setStrokeColor:caption.strokeColor atWidth:caption.strokeWidth atAlpha:caption.strokeAlpha];
            }
            else
            {
                caption.strokeWidth = 0.0;
                caption.strokeColor = [UIColor clearColor];
                caption.strokeAlpha = 1.0;
                [subtitleScrollView setStrokeColor:caption.strokeColor atWidth:caption.strokeWidth atAlpha:caption.strokeAlpha];
            }
        }
#endif
    }
    if( subtitleScrollView.pasterTextView )
    {
        self.pasterTextPoint = subtitleScrollView.pasterTextView.frame.origin;
    }
    
    self.stopAnimated = YES;
    [subtitleScrollView.pasterTextView removeFromSuperview];
    subtitleScrollView.pasterTextView = nil;
    
    subtitleScrollView.pasterTextView = [self newCreateCurrentlyEditingLabel:1 caption:caption];
    subtitleScrollView.pasterTextView.labelBgView.backgroundColor = caption.backgroundColor;
    [subtitleScrollView setIsVerticalText:caption.isVerticalText];
    subtitleScrollView.pasterTextView.typeIndex = index;
    subtitleScrollView.pasterTextView.isBold = caption.isBold;
    subtitleScrollView.pasterTextView.isItalic = caption.isItalic;
    subtitleScrollView.pasterTextView.isVerticalText = caption.isVerticalText;
    subtitleScrollView.pasterTextView.isShadow = caption.isShadow;
    subtitleScrollView.pasterTextView.contentLabel.textAlpha = caption.textAlpha;
    subtitleScrollView.pasterTextView.contentLabel.strokeColor = caption.strokeColor;
    subtitleScrollView.pasterTextView.contentLabel.strokeAlpha = caption.strokeAlpha;
    subtitleScrollView.pasterTextView.contentLabel.strokeWidth = caption.strokeWidth;
    subtitleScrollView.pasterTextView.shadowLbl.textAlpha = caption.textAlpha;
    subtitleScrollView.pasterTextView.shadowLbl.strokeAlpha = caption.strokeAlpha;
    subtitleScrollView.pasterTextView.shadowLbl.strokeWidth = caption.strokeWidth;
    subtitleScrollView.pasterTextView.shadowOffset  = caption.tShadowOffset;
    subtitleScrollView.pasterTextView.shadowColor  = caption.tShadowColor;
    if(subtitleScrollView.contentTextFieldText.length == 0){
        [subtitleScrollView setContentTextFieldText:caption.pText];
    }
    [subtitleScrollView.pasterTextView setFontName:caption.tFontName];
    [subtitleScrollView.pasterTextView setTextString:subtitleScrollView.contentTextFieldText adjustPosition:YES];
    [subtitleScrollView.pasterTextView setAlignment:(NSTextAlignment)caption.tAlignment];
    
    [subtitleScrollView clickSubtitleFontItem:nil];
    
    if(!CGPointEqualToPoint(center, CGPointZero) && subtitleScrollView.isEditting){
        [subtitleScrollView.pasterTextView setCenter:center];
    }
    subtitleScrollView.captionRangeView.file.caption.isVerticalText = subtitleScrollView.pasterTextView.isVerticalText;
#if 1   //20191227
    [self.trimmerView changeSubtitleTye:[caption copy]
                              typeIndex:index
                              frameSize:CGSizeZero
                            captionView:subtitleScrollView.captionRangeView];
#else
    [self.trimmerView changeCurrentRangeviewFile:[caption copy]
                                   typeIndex:index
                                   frameSize:CGSizeZero
                                 captionText:subtitleScrollView.pasterTextView.contentLabel.pText
                                    aligment:caption.tAlignment
                          captionAnimateType:caption.textAnimate.type
                            animateTypeIndex:subtitleScrollView.selectAnimationItemIndex
                                 pushInPoint:caption.textAnimate.pushInPoint
                                pushOutPoint:caption.textAnimate.pushOutPoint
                                 captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithTColor:subtitleScrollView.pasterTextView.contentLabel.fontColor
                                             alpha:subtitleScrollView.pasterTextView.contentLabel.textAlpha
                                           colorId:subtitleScrollView.selectColorItemIndex
                                       captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithstrokeColor:subtitleScrollView.pasterTextView.contentLabel.strokeColor
                                            borderWidth:subtitleScrollView.strokeWidth
                                                  alpha:subtitleScrollView.pasterTextView.contentLabel.strokeAlpha
                                          borderColorId:subtitleScrollView.selectBorderColorItemIndex
                                            captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithFontName:subtitleScrollView.pasterTextView.fontName
                                            fontCode:subtitleScrollView.pasterTextView.fontCode
                                            fontPath:subtitleScrollView.pasterTextView.fontPath
                                              fontId:subtitleScrollView.selectFontItemIndex
                                         captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithIsBold:subtitleScrollView.pasterTextView.isBold
                                          isItalic:subtitleScrollView.pasterTextView.isItalic
                                          isShadow:subtitleScrollView.pasterTextView.isShadow
                                       shadowColor:subtitleScrollView.pasterTextView.shadowColor
                                      shadowOffset:subtitleScrollView.pasterTextView.shadowOffset
                                       captionView:subtitleScrollView.captionRangeView];
#endif
    [self.trimmerView changeCurrentRangeviewWithNetCover:coverPath
                                             captionView:subtitleScrollView.captionRangeView];
}

- (void)changeSubtitleColor:(UIColor *)color alpha:(float)alpha contentType:(RDSubtitleContentType)contentType subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    switch (contentType) {
        case RDSubtitleContentType_stroke:
            subtitleScrollView.pasterTextView.contentLabel.strokeColor = color;
            subtitleScrollView.pasterTextView.contentLabel.strokeWidth = alpha;
            subtitleScrollView.pasterTextView.shadowLbl.strokeColor = subtitleScrollView.pasterTextView.shadowLbl.fontColor;
            subtitleScrollView.pasterTextView.shadowLbl.strokeWidth = alpha;
            [subtitleScrollView.pasterTextView.contentLabel setNeedsDisplay];
            [subtitleScrollView.pasterTextView.shadowLbl setNeedsDisplay];
            [self.trimmerView changeCurrentRangeviewWithstrokeColor:color
                                                    borderWidth:alpha
                                                          alpha:1.0
                                                  borderColorId:subtitleScrollView.selectBorderColorItemIndex
                                                    captionView:subtitleScrollView.captionRangeView];
            break;
        case RDSubtitleContentType_shadow:
        {
            float scale = [subtitleScrollView.pasterTextView getFramescale];
            CGRect frame = subtitleScrollView.pasterTextView.shadowLbl.frame;
            frame.origin.x = alpha*scale;
            frame.origin.y = alpha*scale;
            subtitleScrollView.pasterTextView.shadowLbl.frame = frame;
            subtitleScrollView.pasterTextView.shadowColor = color;
            subtitleScrollView.pasterTextView.shadowOffset = CGSizeMake(alpha, alpha);
            [self.trimmerView changeCurrentRangeviewWithShadowColor:color
                                                              width:alpha
                                                            colorId:subtitleScrollView.selectShadowColorIndex
                                                        captionView:subtitleScrollView.captionRangeView];
        }
            break;
        case RDSubtitleContentType_bg:
            subtitleScrollView.pasterTextView.labelBgView.backgroundColor = color;
            [self.trimmerView changeCurrentRangeviewWithBgColor:color colorId:subtitleScrollView.selectBgColorIndex captionView:subtitleScrollView.captionRangeView];
            break;
        default:
            subtitleScrollView.pasterTextView.contentLabel.fontColor = color;
            subtitleScrollView.pasterTextView.contentLabel.textAlpha = alpha;
            subtitleScrollView.pasterTextView.shadowLbl.fontColor = color;
            subtitleScrollView.pasterTextView.shadowLbl.textAlpha = alpha;
            [subtitleScrollView.pasterTextView.contentLabel setNeedsDisplay];
            [subtitleScrollView.pasterTextView.shadowLbl setNeedsDisplay];
            
            [self.trimmerView changeCurrentRangeviewWithTColor:subtitleScrollView.pasterTextView.contentLabel.fontColor
                                                     alpha:alpha
                                                   colorId:subtitleScrollView.selectColorItemIndex
                                               captionView:subtitleScrollView.captionRangeView];
            break;
    }
}

- (void)changeAlpha:(float)alpha subtitleScrollView:(SubtitleScrollView *)subtitleScrollView {
    subtitleScrollView.pasterTextView.alpha = alpha;
    [self.trimmerView changeCurrentRangeviewWithAlpha:alpha captionView:subtitleScrollView.captionRangeView];
}

/**选择字幕字体*/
- (void)setFontWithName:(NSString *)fontName fontCode:(NSString *)fontCode fontPath:(NSString *)fontPath subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    [subtitleScrollView.pasterTextView setFontName:fontName];
    subtitleScrollView.pasterTextView.fontCode    = fontCode;
    subtitleScrollView.pasterTextView.fontPath = fontPath;
#if 0   //20191227
    [self.trimmerView changeCurrentRangeviewFile:nil
                                   typeIndex:0
                                   frameSize:CGSizeZero
                                 captionText:nil
                                    aligment:(RDCaptionTextAlignment)[subtitleScrollView.pasterTextView getTextAlign]
                          captionAnimateFade:subtitleScrollView.isAnimateFade
                          captionAnimateType:(RDCaptionAnimateType)subtitleScrollView.selectAnimationItemIndex
                            animateTypeIndex:(RDCaptionAnimateType)subtitleScrollView.selectAnimationItemIndex
                                 pushInPoint:self.trimmerView.currentCaptionView.file.caption.textAnimate.pushInPoint
                                pushOutPoint:self.trimmerView.currentCaptionView.file.caption.textAnimate.pushOutPoint
                                 captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithTColor:subtitleScrollView.pasterTextView.contentLabel.fontColor
                                             alpha:subtitleScrollView.pasterTextView.contentLabel.textAlpha
                                           colorId:subtitleScrollView.selectColorItemIndex
                                       captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithstrokeColor:subtitleScrollView.pasterTextView.contentLabel.strokeColor
                                            borderWidth:subtitleScrollView.pasterTextView.contentLabel.strokeWidth
                                                  alpha:subtitleScrollView.pasterTextView.contentLabel.strokeAlpha
                                          borderColorId:subtitleScrollView.selectBorderColorItemIndex
                                            captionView:subtitleScrollView.captionRangeView];
#endif
    [self.trimmerView changeCurrentRangeviewWithFontName:fontName
                                            fontCode:fontCode
                                            fontPath:fontPath
                                              fontId:subtitleScrollView.selectFontItemIndex
                                         captionView:subtitleScrollView.captionRangeView];
}

/**选择字幕大小*/
- (void)changeSize:(float)value subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    CGAffineTransform transform = subtitleScrollView.pasterTextView.transform;
    
    CGAffineTransform transform1 = CGAffineTransformMake(transform.a, transform.b, transform.c, transform.d, transform.tx,transform.ty);
    
    CGFloat radius = atan2f(transform1.b, transform1.a);
    CGAffineTransform transform2 = CGAffineTransformMakeRotation(radius);
    
    [subtitleScrollView.pasterTextView setFramescale:1 + value/1.2f ];
    subtitleScrollView.pasterTextView.transform =  CGAffineTransformScale(transform2, 1 + value/1.2f, 1+ value/1.2f);
}

/**选择字幕位置*/
- (void)changePosition:(RDSubtitleAlignment )postion subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    CGFloat radius = atan2f(subtitleScrollView.pasterTextView.transform.b, subtitleScrollView.pasterTextView.transform.a);
    //double duijiaoxian = hypot(((double) _pasterView.frame.size.width), ((double) _pasterView.frame.size.height));//已知直角三角形两个直角边长度，求斜边长度
    float captionLastScale = [subtitleScrollView.pasterTextView getFramescale];
    double s = fabs(sin(radius));
    double c = fabs(cos(radius));
    float leftX = (c * subtitleScrollView.pasterTextView.contentImage.frame.size.width + subtitleScrollView.pasterTextView.contentImage.frame.size.height * s)/2.0 * captionLastScale;
    float topY = (s * subtitleScrollView.pasterTextView.contentImage.frame.size.width  + subtitleScrollView.pasterTextView.contentImage.frame.size.height * c)/2.0 * captionLastScale;
    CGPoint center = subtitleScrollView.pasterTextView.center;
    switch (postion) {
        case RDSubtitleAlignmentTopLeft:
        {
            center.x = leftX;
            center.y = topY;
        }
            break;
        case RDSubtitleAlignmentTopCenter:
        {
            center.x = self.syncContainer.frame.size.width/2.0;
            center.y = topY;
        }
            break;
        case RDSubtitleAlignmentTopRight:
        {
            center.x = subtitleScrollView.pasterTextView.superview.frame.size.width - leftX;
            center.y = topY;
        }
            break;
        case RDSubtitleAlignmentLeftCenter:
        {
            center.x = leftX;
            center.y = self.syncContainer.frame.size.height/2.0;
        }
            break;
        case RDSubtitleAlignmentCenter:
        {
            center.x = self.syncContainer.frame.size.width/2.0;
            center.y = self.syncContainer.frame.size.height/2.0;
        }
            break;
        case RDSubtitleAlignmentRightCenter:
        {
            center.x = subtitleScrollView.pasterTextView.superview.frame.size.width - leftX;
            center.y = self.syncContainer.frame.size.height/2.0;
        }
            break;
        case RDSubtitleAlignmentBottomLeft:
        {
            center.x = leftX;
            center.y = subtitleScrollView.pasterTextView.superview.frame.size.height - topY;
        }
            break;
        case RDSubtitleAlignmentBottomCenter:
        {
            center.x = self.syncContainer.frame.size.width/2.0;
            center.y = subtitleScrollView.pasterTextView.superview.frame.size.height - topY;
        }
            break;
        case RDSubtitleAlignmentBottomRight:
        {
            center.x = subtitleScrollView.pasterTextView.superview.frame.size.width - leftX;
            center.y = subtitleScrollView.pasterTextView.superview.frame.size.height - topY;
        }
            break;
        default:
            break;
    }
    [subtitleScrollView.pasterTextView setCenter:center];
    [self.trimmerView changeCurrentRangeviewWithSubtitleAlignment:postion captionView:subtitleScrollView.captionRangeView];
}

- (void)changeMoveSlightlyPosition:(RDMoveSlightlyDirection)direction subtitleScrollView:(SubtitleScrollView *)subtitleScrollView {
    CGPoint center = subtitleScrollView.pasterTextView.center;
    float move = 1.0;
    switch (direction) {
        case RDMoveSlightlyTop:
            center.y -= move;
            break;
        case RDMoveSlightlyLeft:
            center.x -= move;
            break;
        case RDMoveSlightlyRight:
            center.x += move;
            break;
        case RDMoveSlightlyBottom:
            center.y += move;
            break;
        default:
            break;
    }
    [subtitleScrollView.pasterTextView setCenter:center];
}

/**改变字幕内容*/
- (void)changeSubtitleContentString:(NSString *)contentString subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    //    subtitleScrollView.pasterTextView.needStretching = YES;
    [subtitleScrollView.pasterTextView setTextString:contentString adjustPosition:NO];
#if 1
    self.trimmerView.currentCaptionView.file.captionText = contentString;
    [self.trimmerView.currentCaptionView setTitle:contentString forState:UIControlStateNormal];
#else
    [self.trimmerView changeCurrentRangeviewFile:nil
                                   typeIndex:subtitleScrollView.pasterTextView.typeIndex
                                   frameSize:CGSizeZero
                                 captionText:subtitleScrollView.pasterTextView.contentLabel.pText
                                    aligment:(RDCaptionTextAlignment)[subtitleScrollView.pasterTextView getTextAlign]
                          captionAnimateFade:subtitleScrollView.isAnimateFade
                          captionAnimateType:(RDCaptionAnimateType)captionAnimateType
                           inAnimateTypeIndex:subtitleScrollView.inAnimationIndex
                          outAnimateTypeIndex:subtitleScrollView.outAnimationIndex
                                 pushInPoint:self.trimmerView.currentCaptionView.file.caption.textAnimate.pushInPoint
                                pushOutPoint:self.trimmerView.currentCaptionView.file.caption.textAnimate.pushOutPoint
                                 captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithTColor:subtitleScrollView.pasterTextView.contentLabel.fontColor alpha:subtitleScrollView.pasterTextView.contentLabel.textAlpha colorId:subtitleScrollView.selectColorItemIndex
                                       captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithstrokeColor:subtitleScrollView.pasterTextView.contentLabel.strokeColor borderWidth:subtitleScrollView.pasterTextView.contentLabel.strokeWidth alpha:subtitleScrollView.pasterTextView.contentLabel.strokeAlpha borderColorId:subtitleScrollView.selectBorderColorItemIndex
                                            captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithFontName:subtitleScrollView.pasterTextView.fontName
                                            fontCode:subtitleScrollView.pasterTextView.fontCode
                                            fontPath:subtitleScrollView.pasterTextView.fontPath
                                              fontId:subtitleScrollView.selectFontItemIndex
                                         captionView:subtitleScrollView.captionRangeView];
#endif
}

/**改变字幕内容是否加粗，是否斜体，是否有阴影*/
- (void) changeWithIsBold:(BOOL)isBold isItalic:(BOOL )isItalic isShadow:(BOOL)isShadow subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    subtitleScrollView.pasterTextView.isBold       = isBold;
    subtitleScrollView.pasterTextView.isItalic     = isItalic;
    subtitleScrollView.pasterTextView.isShadow     = isShadow;
    [subtitleScrollView.pasterTextView.contentLabel setNeedsLayout];
    [subtitleScrollView.pasterTextView.shadowLbl setNeedsLayout];
    [self.trimmerView changeCurrentRangeviewWithIsBold:subtitleScrollView.isBold
                                          isItalic:subtitleScrollView.isItalic
                                          isShadow:subtitleScrollView.isShadow
                                       shadowColor:subtitleScrollView.pasterTextView.shadowColor
                                      shadowOffset:subtitleScrollView.pasterTextView.shadowOffset
                                       captionView:subtitleScrollView.captionRangeView];
}

- (void)previewAnimation:(CaptionAnimateType)inType outType:(CaptionAnimateType)outType subtitleScrollView:(SubtitleScrollView *)subtitleScrollView {
    [self saveSubtitleOrEffectWithPasterView:self.subtitleConfigView.pasterTextView];
    NSMutableArray *arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    CMTimeRange timeRange = kCMTimeRangeZero;
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
    float animationDuration = 0.5;
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption= view.file.caption;
        if(ppcaption){
            if (view == self.trimmerView.currentCaptionView) {
                ppcaption.position    = view.file.centerPoint;
                ppcaption.music       = nil;
                ppcaption.angle       = view.file.rotationAngle;
                ppcaption.scale       = view.file.scale;
                ppcaption.tColor      = view.file.tColor ? view.file.tColor : view.file.caption.tColor;
                ppcaption.strokeColor = view.file.strokeColor ? view.file.strokeColor : view.file.caption.strokeColor;
                if(view.file.caption.frameArray.count>0)
                    ppcaption.frameArray      = @[view.file.caption.frameArray[0]];
                ppcaption.imageAnimate.inDuration = animationDuration;
                ppcaption.imageAnimate.outDuration = animationDuration;
                ppcaption.textAnimate.inDuration = animationDuration;
                ppcaption.textAnimate.outDuration = animationDuration;
                ppcaption.imageAnimate.fadeInDuration = animationDuration;
                ppcaption.imageAnimate.fadeOutDuration = animationDuration;
                ppcaption.textAnimate.fadeInDuration = animationDuration;
                ppcaption.textAnimate.fadeOutDuration = animationDuration;
                ppcaption.timeRange = CMTimeRangeMake(ppcaption.timeRange.start, CMTimeMakeWithSeconds(2, TIMESCALE));
                timeRange = ppcaption.timeRange;
            }
            [newEffectArray addObject:ppcaption];
            [newFileArray addObject:view.file];
        }
    }
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
            [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:NO];
        }
        if ([self.delegate respondsToSelector:@selector(previewWithTimeRange:)]) {
            self.subtitleConfigView.pasterTextView.hidden = YES;
            [self.delegate previewWithTimeRange:timeRange];
        }
    }
}

/**是否应用到所有字幕*/
- (void)useToAllWithSubtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    float  captionLastScale = [subtitleScrollView.pasterTextView getFramescale];
    [self.trimmerView useToAllWithTypeToAll:subtitleScrollView.useTypeToAll
                         animationToAll:subtitleScrollView.useAnimationToAll
                             colorToAll:subtitleScrollView.useColorToAll
                            borderToAll:subtitleScrollView.useBorderToAll
                              fontToAll:subtitleScrollView.useFontToAll
                              sizeToAll:subtitleScrollView.useSizeToAll
                          positionToAll:subtitleScrollView.usePositionToAll
                                  scale:captionLastScale
                            captionView:subtitleScrollView.captionRangeView];
}

/**保存字幕信息*/
- (void)saveSubtitleConfig:(NSInteger)index subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
{
    if([[subtitleScrollView contentTextFieldText] length] == 0){
        [self.hud setCaption:RDLocalizedString(@"点击输入字幕", nil)];
        [self.hud show];
        [self.hud hideAfter:2];
        return;
    }
    
    [subtitleScrollView.pasterTextView hideEditingHandles];
    subtitleScrollView.isEditting = NO;
    subtitleScrollView.pasterTextView.isBold       = subtitleScrollView.isBold;
    subtitleScrollView.pasterTextView.isItalic     = subtitleScrollView.isItalic;
    subtitleScrollView.pasterTextView.isShadow     = subtitleScrollView.isShadow;

    [self.trimmerView changeCurrentRangeviewWithBgColor:subtitleScrollView.pasterTextView.labelBgView.backgroundColor
                                                colorId:subtitleScrollView.selectBgColorIndex
                                            captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithTColor:subtitleScrollView.pasterTextView.contentLabel.fontColor
                                                 alpha:subtitleScrollView.pasterTextView.contentLabel.textAlpha
                                               colorId:subtitleScrollView.selectColorItemIndex
                                           captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithstrokeColor:subtitleScrollView.pasterTextView.contentLabel.strokeColor
                                                borderWidth:subtitleScrollView.strokeWidth
                                                      alpha:subtitleScrollView.pasterTextView.contentLabel.strokeAlpha
                                              borderColorId:subtitleScrollView.selectBorderColorItemIndex
                                                captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithFontName:subtitleScrollView.pasterTextView.fontName
                                                fontCode:subtitleScrollView.pasterTextView.fontCode
                                                fontPath:subtitleScrollView.pasterTextView.fontPath
                                                  fontId:subtitleScrollView.selectFontItemIndex
                                             captionView:subtitleScrollView.captionRangeView];
    
    [self.trimmerView changeCurrentRangeviewWithIsBold:subtitleScrollView.pasterTextView.isBold
                                              isItalic:subtitleScrollView.pasterTextView.isItalic
                                              isShadow:subtitleScrollView.pasterTextView.isShadow
                                           shadowColor:subtitleScrollView.pasterTextView.shadowColor
                                          shadowOffset:subtitleScrollView.pasterTextView.shadowOffset
                                           captionView:subtitleScrollView.captionRangeView];
    self.trimmerView.currentCaptionView.file.thumbnailImage = subtitleScrollView.pasterTextView.contentImage.image;
    
    if( self.cancelBtn.hidden )
    {
        subtitleScrollView.captionRangeView.file.caption.isVerticalText = subtitleScrollView.pasterTextView.isVerticalText;
        [self saveSubtitle:NO];
        
        [subtitleScrollView.pasterTextView removeFromSuperview];
        subtitleScrollView.pasterTextView  = nil;
        [subtitleScrollView clear];
        [subtitleScrollView removeFromSuperview];
        subtitleScrollView = nil;
        
        self.oldMaterialEffectFile = nil;
      
        self.finishBtn.hidden = YES;
        self.addBtn.hidden = NO;
        self.editBtn.hidden = NO;
        self.deletedBtn.hidden = NO;
        [RDHelpClass animateViewHidden:self.subtitleConfigView atUP:NO atBlock:^{
            self.subtitleConfigView.hidden = YES;
        }];
        self.speechRecogBtn.hidden = YES;
        
    }
    else{
        subtitleScrollView.captionRangeView.file.caption.isVerticalText = subtitleScrollView.pasterTextView.isVerticalText;
//        self.addBtn.hidden = YES;
//        self.finishBtn.hidden = NO;
//        self.cancelBtn.hidden = NO;
//        self.speechRecogBtn.hidden = YES;
        [RDHelpClass animateViewHidden:self.subtitleConfigView atUP:NO atBlock:^{
            self.subtitleConfigView.hidden = YES;
        }];
        
//        [self saveSubtitleOrEffectWithPasterView:self.subtitleConfigView.pasterTextView];
//        [self.subtitleConfigView.pasterTextView removeFromSuperview];
//        self.subtitleConfigView.pasterTextView  = nil;
//        [self.subtitleConfigView clear];
//        [self.subtitleConfigView removeFromSuperview];
//        self.subtitleConfigView = nil;
//        [self.syncContainer removeFromSuperview];
//        self.trimmerView.rangeSlider.hidden = YES;
        
        int captionId = self.trimmerView.currentCaptionView.file.captionId;
        
        [self finishEffectAction:self.finishBtn];
        
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(addingStickerWithDuration: captionId:)]) {
            [self.delegate addingStickerWithDuration:0 captionId:captionId];
        }
        
        
        if( self.delegate && [ self.delegate respondsToSelector:@selector(pauseVideo) ])
            [self.delegate pauseVideo];
        
        self.addBtn.hidden = YES;
        self.finishBtn.hidden = NO;
    }
}

/**下载字幕和字体*/
- (void)downloadFile:(NSString *)fileUrl
           cachePath:(NSString *)cachePath
            fileName:(NSString *)fileName
            timeunix:(NSString *)timeunix
            fileType:(DownFileType)type
              sender:(UIView *)sender
  subtitleScrollView:(SubtitleScrollView *)subtitleScrollView
            progress:(void(^)(float progress))progressBlock
         finishBlock:(void(^)())finishBlock
           failBlock:(void(^)(void))failBlock
{
    if(!fileUrl){
        return;
    }
    UILabel *progressLbl = [[UILabel alloc] initWithFrame:sender.bounds];
    progressLbl.backgroundColor = [Main_Color colorWithAlphaComponent:0.8];
    progressLbl.text = @"0%";
    progressLbl.textColor = [UIColor whiteColor];
    progressLbl.textAlignment = NSTextAlignmentCenter;
    [sender addSubview:progressLbl];
    
    WeakSelf(self);
    NSString *url_str=[NSString stringWithString:[fileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString * path = cachePath;
    NSString *cacheFolderPath = [path stringByDeletingLastPathComponent];
    [RDFileDownloader downloadFileWithURL:url_str cachePath:cacheFolderPath httpMethod:GET progress:^(NSNumber *numProgress) {
        progressLbl.text = [NSString stringWithFormat:@"%.0f%%", [numProgress floatValue]*100.0];
    } finish:^(NSString *fileCachePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载完成");
            switch (type) {
                case DownFileCapption:
                {
                    NSString *path = kSubtitleCheckPlistPath;
                    [RDHelpClass OpenZip:fileCachePath unzipto:[fileCachePath stringByDeletingLastPathComponent] caption:NO];
                    NSString *fname = fileName;
                    if(fname.length == 0){
                        fname = [[fileCachePath stringByDeletingLastPathComponent] lastPathComponent];
                    }
                    NSString *openzipPath = [kSubtitleFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",fname]];
                    if([[[NSFileManager defaultManager] contentsOfDirectoryAtPath:openzipPath error:nil] count]>0){
                        NSMutableDictionary *checkConfigDic = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
                        if(!checkConfigDic){
                            checkConfigDic = [[NSMutableDictionary alloc] init];
                        }
                        if(timeunix.length==0 || !timeunix){
                            [checkConfigDic setObject:@"2015-02-03" forKey:fname];
                        }else{
                            [checkConfigDic setObject:timeunix forKey:fname];
                        }
                        [checkConfigDic writeToFile:path atomically:YES];
                        [sender viewWithTag:-1].hidden = YES;
                        [progressLbl removeFromSuperview];
                        finishBlock();
                    }else{
                        StrongSelf(self);
                        NSLog(@"下载失败");
                        [strongSelf.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                        [strongSelf.hud show];
                        [strongSelf.hud hideAfter:2];
                        [sender viewWithTag:-1].hidden = NO;
                        [progressLbl removeFromSuperview];
                        failBlock();
                    }
                }
                    break;
                    
                case DownFileFont:
                {
                    NSString *fname = fileName;
                    if(fname.length == 0){
                        fname = [[fileCachePath stringByDeletingLastPathComponent] lastPathComponent];
                    }
                    NSString *openzipPath = [kFontFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",fname]];
                    if([[[NSFileManager defaultManager] contentsOfDirectoryAtPath:openzipPath error:nil] count]>0){
                        NSString *path = kFontCheckPlistPath;
                        NSMutableDictionary *checkConfigDic = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
                        if(!checkConfigDic){
                            checkConfigDic = [[NSMutableDictionary alloc] init];
                        }
                        if(timeunix.length==0 || !timeunix){
                            [checkConfigDic setObject:@"2015-02-03" forKey:fname];
                        }else{
                            [checkConfigDic setObject:timeunix forKey:fname];
                        }
                        [checkConfigDic writeToFile:path atomically:YES];
                        
                        [progressLbl removeFromSuperview];
                        finishBlock();
                    }else{
                        StrongSelf(self);
                        NSLog(@"下载失败");
                        [strongSelf.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                        [strongSelf.hud show];
                        [strongSelf.hud hideAfter:2];
                        
                        [progressLbl removeFromSuperview];
                        sender.hidden = NO;
                        failBlock();
                    }
                }
                    break;
                default:
                    break;
            }
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载失败");
            StrongSelf(self);
            [strongSelf.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [strongSelf.hud show];
            [strongSelf.hud hideAfter:2];
            
            [progressLbl removeFromSuperview];
            sender.hidden = NO;
            failBlock();
        });
    }];
}

/** 关闭SubtitleScrollView **/
- (void)changeClose:(SubtitleScrollView *)subtitleScrollView
{
    if(self.isEdittingEffect)
    {
        CaptionRangeView * currentRangeView = [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
        currentRangeView.file = [self.oldMaterialEffectFile mutableCopy];
        self.oldMaterialEffectFile = nil;;
        
        NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
        
        NSMutableArray *newEffectArray = [NSMutableArray array];
        NSMutableArray <RDCaptionRangeViewFile *>* newFileArray = [NSMutableArray array];
        for(CaptionRangeView *view in arr){
            RDCaption *ppcaption= view.file.caption;
            if(ppcaption){
//                ppcaption.timeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
//                ppcaption.position    = view.file.centerPoint;
//                ppcaption.music       = nil;
//                ppcaption.angle       = view.file.rotationAngle;
//                ppcaption.scale       = view.file.scale;
//                if(view.file.tColor)
//                    ppcaption.tColor      = view.file.tColor;
//                if(view.file.strokeColor)
//                    ppcaption.strokeColor = view.file.strokeColor;
//                if(view.file.caption.frameArray.count>0)
//                    ppcaption.frameArray      = @[view.file.caption.frameArray[0]];
//                ppcaption.pText       = view.titleLabel.text;
                [newEffectArray addObject:ppcaption];
                [newFileArray addObject:view.file];
            }
        }
        self.deletedBtn.hidden = YES;
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
                [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:YES];
            }
            [self finishEffectAction:self.finishBtn];
        }
    }else {
        [self cancelEffectAction:nil];
    }
    self.speechRecogBtn.hidden = self.speechRecogBtn.selected;
    self.finishBtn.hidden = YES;
    
    [RDHelpClass animateViewHidden:self.subtitleConfigView atUP:NO atBlock:^{
        [self.subtitleConfigView setContentTextFieldText:@""];
        [self.subtitleConfigView.pasterTextView removeFromSuperview];
        self.subtitleConfigView.pasterTextView = nil;
        [self.subtitleConfigView clear];
        [self.subtitleConfigView removeFromSuperview];
        self.subtitleConfigView = nil;
    }];
}

@end
