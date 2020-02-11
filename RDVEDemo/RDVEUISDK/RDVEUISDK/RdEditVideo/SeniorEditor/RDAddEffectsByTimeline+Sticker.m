//
//  RDAddEffectsByTimeline+Sticker.m
//  RDVEUISDK
//
//  Created by apple on 2019/5/7.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline+Sticker.h"
#import "subtitleEffectScrollView.h"
#import "RDSectorProgressView.h"
#import "RDFileDownloader.h"
#import "UIImage+RDGIF.h"

@implementation RDAddEffectsByTimeline (Sticker)

- (void)initStickerEditView{
    if(!self.stickerConfigView){
        CGRect rect = self.superview.frame;
        rect.size.height =  rect.size.height + kToolbarHeight;
        self.stickerConfigView = [[SubtitleEffectScrollView alloc] initWithFrame:rect withType:1];
        self.stickerConfigView.delegate = self;
        self.stickerConfigView.hidden = YES;
        [self.superview.superview insertSubview:self.stickerConfigView aboveSubview:self];
    }
}

- (void)addSticker{
    if(![self checkStickerIconDownload]){
        return;
    }
    [self.trimmerView addCapation:nil type:4 captionDuration:3];
    [self.stickerConfigView touchescaptionTypeViewChildWithIndex:0];    
    self.stickerConfigView.hidden = NO;
    [RDHelpClass animateView:self.stickerConfigView atUP:NO];
//    [self.stickerConfigView touchescaptionTypeViewChild:nil];
    self.stickerConfigView.isEditSubtitleEffect = NO;
}

- (void)saveStickerTouchUp{
    [self saveSubtitleOrEffectWithPasterView:self.stickerConfigView.pasterTextView];
    
    [self.stickerConfigView setContentTextFieldText: @""];
    [self.stickerConfigView.pasterTextView removeFromSuperview];
    self.stickerConfigView.pasterTextView = nil;
    [self.stickerConfigView removeFromSuperview];
    self.stickerConfigView = nil;
    
    [RDHelpClass animateViewHidden:self.stickerConfigView atUP:NO atBlock:^{
        self.stickerConfigView.hidden = YES;
    }];
    self.addBtn.hidden = NO;
    self.editBtn.hidden = NO;
    self.finishBtn.hidden = YES;
    self.cancelBtn.hidden = YES;
    
    [self updateStickers:NO];
}

- (void)editSticker {
    CaptionRangeView * currentRangeView = [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
    self.trimmerView.scrollView.scrollEnabled = YES;
    [self.trimmerView getcurrentCaption:currentRangeView.file.captionId];
    
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    [self.stickerConfigView setContentTextFieldText: @""];
    [self.stickerConfigView.pasterTextView removeFromSuperview];
    self.stickerConfigView.pasterTextView = nil;
    [self.stickerConfigView removeFromSuperview];
    self.stickerConfigView = nil;
    [self.syncContainer removeFromSuperview];
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>*newFileArray = [NSMutableArray array];
    NSMutableArray *newEffectArray1 = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>*newFileArray1 = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption= view.file.caption;
        if(self.trimmerView.currentCaptionView != view){
            if (ppcaption.stickerType == RDStickerType_Pixelate) {
                [newEffectArray1 addObject:ppcaption];
                [newFileArray1 addObject:view.file];
            }else {
                [newEffectArray addObject:ppcaption];
                [newFileArray addObject:view.file];
            }
        }
    }
    self.oldMaterialEffectFile = [currentRangeView.file mutableCopy];
    
    self.stickerConfigView.hidden = NO;
    [self.trimmerView touchesUpInslide];
    self.stickerConfigView.isEditSubtitleEffect = YES;
    [self checkEffectEditBefor:currentRangeView.file.captiontypeIndex];
//    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:newEffectArray1:newFileArray1:isSaveEffect:)]) {
//        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray newEffectArray1:newEffectArray1 newFileArray1:newFileArray1 isSaveEffect:NO];
//    }
}

- (void)checkEffectEditBefor:(NSInteger)typeIndex{
    CaptionRangeView *rangeView = self.trimmerView.currentCaptionView;
    
    UIColor     *fontstrokeColor = rangeView.file.strokeColor;
    UIColor     *fontTextColor  = rangeView.file.tColor;
    NSString    *fontName       = rangeView.file.fontName;
//    NSString    *fontCode       = rangeView.file.fontCode;
    float   ppsc                = (rangeView.file.caption.size.width * self.exportSize.width)/ (float) rangeView.file.caption.size.width <1 ? (rangeView.file.caption.size.width * self.exportSize.width)/ (float) rangeView.file.caption.size.width : 1;
    float   fontSize            = rangeView.file.tFontSize  * ppsc;
    float   sc                  = rangeView.file.scale;
    CGFloat radius              = atan2f(rangeView.file.captionTransform.b, rangeView.file.captionTransform.a);
    
    [self initStickerEditView];
    self.stickerConfigView.isEditSubtitleEffect = YES;
    self.stickerConfigView.hidden = NO;
    [self.stickerConfigView touchescaptionTypeViewChildWithIndex:rangeView.file.captiontypeIndex];
    
    CGAffineTransform transform2    = CGAffineTransformMakeRotation(radius);
    self.stickerConfigView.pasterTextView.transform   = CGAffineTransformScale(transform2, sc * ppsc, sc * ppsc);
    [self.stickerConfigView.pasterTextView setFramescale: sc * ppsc];
    self.stickerConfigView.pasterTextView.center      = CGPointMake(rangeView.file.centerPoint.x *self.syncContainer.frame.size.width,rangeView.file.centerPoint.y *self.syncContainer.frame.size.height);
    
    self.stickerConfigView.pasterTextView.contentLabel.fontColor  = fontTextColor;
    self.stickerConfigView.pasterTextView.contentLabel.strokeColor = fontstrokeColor;
//    self.stickerConfigView.pasterTextView.fontCode                = fontCode;
    self.stickerConfigView.pasterTextView.fontPath = rangeView.file.fontPath;
    self.stickerConfigView.pasterTextView.contentLabel.font       = [UIFont fontWithName:fontName size:fontSize];
    self.stickerConfigView.pasterTextView.fontSize                = fontSize;
    [self.stickerConfigView.pasterTextView setAlignment:(NSTextAlignment)rangeView.file.caption.tAlignment];
    
    [self.trimmerView changeCurrentRangeviewFile:nil
                                         tColor:fontTextColor
                                    strokeColor:fontstrokeColor
                                       fontName:fontName
                                        fontCode:nil//fontCode
                                      typeIndex:rangeView.file.captiontypeIndex
                                      frameSize:CGSizeZero captionText:@""
                                       aligment:rangeView.file.caption.tAlignment
                                inAnimateTypeIndex:rangeView.file.inAnimationIndex
                            outAnimateTypeIndex:rangeView.file.outAnimationIndex
                                    pushInPoint:rangeView.file.caption.textAnimate.pushInPoint
                                   pushOutPoint:rangeView.file.caption.textAnimate.pushOutPoint
                                    captionView:nil];
    
    float width = ((self.stickerConfigView.contentSize.width-self.stickerConfigView.frame.size.width)*0.5);
    float fontScale  =  1.2f *( (sc * ppsc) - 1);
    float contentOffset_x = width * fontScale + width;
    self.stickerConfigView.contentOffset = CGPointMake(contentOffset_x, 0);
}

- (void)updateStickers:(BOOL)isSave {
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>*newFileArray = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCaption *ppcaption = view.file.caption;
        if(ppcaption){
            ppcaption.timeRange   = CMTimeRangeMake(CMTimeAdd(view.file.timeRange.start, CMTimeMakeWithSeconds(self.trimmerView.piantouDuration, TIMESCALE)), view.file.timeRange.duration);
            if(CMTimeGetSeconds(ppcaption.timeRange.duration)==0){
                [view removeFromSuperview];
                continue;
            }
            ppcaption.position    = view.file.centerPoint;
            ppcaption.music       = nil;
            ppcaption.angle       = view.file.rotationAngle;
            ppcaption.tFontSize   = view.file.caption.tFontSize;
            ppcaption.scale       = view.file.scale;
            ppcaption.tColor      = view.file.tColor ? view.file.tColor : view.file.caption.tColor;
            ppcaption.strokeColor = view.file.strokeColor ? view.file.strokeColor : view.file.caption.strokeColor;
            ppcaption.tFontName   = view.file.fontName;
            ppcaption.pText       = view.titleLabel.text;
            [newEffectArray addObject:ppcaption];
            [newFileArray addObject:view.file];
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:isSave];
    }
}

#pragma mark- SubtitleEffectScrollViewDelegate
//贴纸
/**type: 1: 字幕  2:特效 3:字体
 */
- (void)downloadFile:(NSString *)fileUrl cachePath:(NSString *)cachePath fileName:(NSString *)fileName timeunix:(NSString *)timeunix type:(NSInteger)type sender:(UIView *)sender progress:(void(^)(float progress))progressBlock finishBlock:(void(^)())finishBlock failBlock:(void(^)(void))failBlock
{
    if(!fileUrl){
        return;
    }
    UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
    CGRect rect = CGRectMake(sender.frame.size.width-accessory.size.width, sender.frame.size.height - accessory.size.height, accessory.size.width, accessory.size.height);
    RDSectorProgressView *ddprogress = [[RDSectorProgressView alloc] initWithFrame:rect];
    
    [sender addSubview:ddprogress];
    
    NSString *url_str=[NSString stringWithString:[fileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSString * path = cachePath;
    __weak typeof(self) weakSelf= self;
    
    NSString *cacheFolderPath = [path stringByDeletingLastPathComponent];
    [RDFileDownloader downloadFileWithURL:url_str cachePath:cacheFolderPath httpMethod:GET progress:^(NSNumber *numProgress) {
        [ddprogress setProgress:[numProgress floatValue]];
    } finish:^(NSString *fileCachePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载完成");
            
            NSString *path = kStickerCheckPlistPath;
            [RDHelpClass OpenZip:fileCachePath unzipto:[fileCachePath stringByDeletingLastPathComponent] caption:NO];
            NSString *fname = fileName;
            if(fname.length == 0){
                fname = [[fileCachePath stringByDeletingLastPathComponent] lastPathComponent];
            }
            NSString *openzipPath = [kStickerFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",fname]];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSArray *fileArray = [fm contentsOfDirectoryAtPath:openzipPath error:nil];
            if(fileArray.count > 0){
                NSString *name;
                for (NSString *fileName in fileArray) {
                    if (![fileName isEqualToString:@"__MACOSX"]) {
                        NSString *folderPath = [openzipPath stringByAppendingPathComponent:fileName];
                        BOOL isDirectory = NO;
                        BOOL isExists = [fm fileExistsAtPath:folderPath isDirectory:&isDirectory];
                        if (isExists && isDirectory) {
                            name = fileName;
                            break;
                        }
                    }
                }
                NSString *jsonPath = [[openzipPath stringByAppendingPathComponent:name] stringByAppendingPathComponent:@"config.json"];
                NSData *jsonData = [[NSData alloc] initWithContentsOfFile:jsonPath];
                NSMutableDictionary *jsonDic = [RDHelpClass objectForData:jsonData];
                jsonData = nil;
                if ([jsonDic[@"apng"] boolValue]) {
                    NSString *apngPath = [[openzipPath stringByAppendingPathComponent:name] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", jsonDic[@"name"]]];
                    NSData *apngData = [NSData dataWithContentsOfFile:apngPath];
                    UIImage *apngImage = [UIImage rd_sd_animatedGIFWithData:apngData];
                    [jsonDic setObject:[NSNumber numberWithFloat:apngImage.duration] forKey:@"duration"];
                    NSArray *timeArray = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0], @"beginTime", [NSNumber numberWithFloat:apngImage.duration], @"endTime", nil]];
                    [jsonDic setObject:timeArray forKey:@"timeArray"];
                    NSMutableArray *frameArray = [NSMutableArray array];
                    __block float totalDuration = 0.0;
                    [apngImage.images enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        BOOL result = [UIImagePNGRepresentation(obj) writeToFile:[[openzipPath stringByAppendingPathComponent:name] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%lu.png", jsonDic[@"name"], (unsigned long)idx]] atomically:YES];
                        if(!result) {
                            NSLog(@"%d保存失败", (unsigned long)idx);
                        }else {
                            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:totalDuration], @"time", [NSNumber numberWithInteger:idx], @"pic", nil];
                            [frameArray addObject:dic];
                            totalDuration += obj.duration;
                        }
                    }];
                    
                    if( totalDuration == 0 )
                    {
                        BOOL result = [UIImagePNGRepresentation(apngImage) writeToFile:[[openzipPath stringByAppendingPathComponent:name] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@0.png", jsonDic[@"name"]]] atomically:YES];
                        if(!result) {
                            NSLog(@"%d保存失败", (unsigned long)0);
                        }else {
                            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:totalDuration], @"time", [NSNumber numberWithInteger:0], @"pic", nil];
                            [frameArray addObject:dic];
                        }
                    }
                    
                    if (frameArray.count > 0) {
                        [jsonDic setObject:frameArray forKey:@"frameArray"];
                    }
                    unlink([jsonPath UTF8String]);
                    NSString *jsonStr = [RDHelpClass objectToJson:jsonDic];
                    if (jsonStr.length > 0) {
                        NSError *error = nil;
                        [jsonStr writeToFile:jsonPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                        if (error) {
                            NSLog(@"%@", error);
                        };
                    }
                }
                
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
                [self.stickerConfigView touchescaptionTypeViewChild:(UIButton*)sender];
                [sender viewWithTag:1].hidden = YES;
                [ddprogress removeFromSuperview];
                finishBlock();
            }else{
                NSLog(@"下载失败");
                [self.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                [self.hud show];
                [self.hud hideAfter:2];
                [sender viewWithTag:1].hidden = NO;
                [ddprogress removeFromSuperview];
                failBlock();
            }
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载失败");
            [self.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [self.hud show];
            [self.hud hideAfter:2];
            
            [ddprogress removeFromSuperview];
            sender.hidden = NO;
            failBlock();
        });
    }];
}
/**type: 1: 字幕  2:特效
 */
- (void)changeSubtitleEffect:(NSString*)configPath type:(NSInteger)type index:(NSInteger)index
{
    self.stopAnimated = YES;
    [self.stickerConfigView.pasterTextView removeFromSuperview];
    self.stickerConfigView.pasterTextView = nil;
    self.subtitleEffectConfigPath = [configPath stringByDeletingLastPathComponent];
    
    RDCaption *caption = [self getCurrentCaptionConfig];
    
    self.stickerConfigView.pasterTextView = [self newCreateCurrentlyEditingLabel:type caption:caption];
    
    self.stickerConfigView.pasterTextView.typeIndex = index;

    [self.trimmerView changeCurrentRangeviewFile:[caption copy]
                                      tColor:nil
                                 strokeColor:nil
                                    fontName:self.stickerConfigView.pasterTextView.fontName
                                    fontCode:self.stickerConfigView.pasterTextView.fontCode
                                   typeIndex:index
                                   frameSize:self.stickerConfigView.pasterTextView.tsize
                                 captionText:self.stickerConfigView.pasterTextView.contentLabel.pText
                                    aligment:caption.tAlignment
                           inAnimateTypeIndex:0
                          outAnimateTypeIndex:0
                                 pushInPoint:CGPointZero
                                pushOutPoint:CGPointZero
                                 captionView:nil];
    self.trimmerView.currentCaptionView.file.rectW = self.stickerConfigView.pasterTextView.rectW;
    [self.trimmerView changeCurrentRangeviewWithNetCover:[self.stickerConfigView typeList][index][@"cover"] captionView:nil];
}

/**改变贴纸大小
 */
- (void)changePointSizeScale:(float)value
{
    CGAffineTransform transform = self.stickerConfigView.pasterTextView.transform;
    CGAffineTransform transform1 = CGAffineTransformMake(transform.a, transform.b, transform.c, transform.d, transform.tx,transform.ty);    
    CGFloat radius = atan2f(transform1.b, transform1.a);
    CGAffineTransform transform2 = CGAffineTransformMakeRotation(radius);
    
    [self.stickerConfigView.pasterTextView setFramescale:value/1.2f ];
    self.stickerConfigView.pasterTextView.transform =  CGAffineTransformScale(transform2, value/1.2f, value/1.2f);
}

/**改变动画
 */
- (void)changeSubtitleAnimateType:(NSInteger)typeIndex
{
    [self.trimmerView changeCurrentRangeviewFile:nil
                                      tColor:self.stickerConfigView.pasterTextView.contentLabel.fontColor
                                 strokeColor:self.stickerConfigView.pasterTextView.contentLabel.strokeColor
                                    fontName:self.stickerConfigView.pasterTextView.fontName
                                    fontCode:@"morenziti"
                                   typeIndex:0/*_editTypeIndex*/
                                   frameSize:CGSizeZero
                                 captionText:nil
                                    aligment:(RDCaptionTextAlignment)[self.stickerConfigView.pasterTextView getTextAlign]
                           inAnimateTypeIndex:typeIndex
                          outAnimateTypeIndex:typeIndex
                                 pushInPoint:CGPointZero
                                pushOutPoint:CGPointZero
                                 captionView:nil];
}

/**隐藏编辑控件
 */
- (void)saveSubtitleEffect:(NSInteger)index
{
    [self.stickerConfigView.pasterTextView hideEditingHandles];
    self.currentTimeLbl.hidden = NO;
    if(self.stickerConfigView.isEditSubtitleEffect){
        self.stickerConfigView.isEditSubtitleEffect = NO;
        [self saveStickerTouchUp];
        return;
    }
    
    self.trimmerView.rangeSlider.hidden= YES;
    self.addBtn.hidden = YES;
    self.finishBtn.hidden = NO;
    self.cancelBtn.hidden = NO;
    float addingDuration = 0;
    if ([self.subtitleEffectConfig[@"unLoop"] boolValue]) {
        addingDuration = [self.subtitleEffectConfig[@"duration"] floatValue];
    }
    
    int captionId = self.trimmerView.currentCaptionView.file.captionId;
    
    [self finishEffectAction:self.finishBtn];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(addingStickerWithDuration:captionId:)]) {
        [self.delegate addingStickerWithDuration:addingDuration captionId:captionId];
    }
    
    if( self.delegate && [ self.delegate respondsToSelector:@selector(pauseVideo) ])
        [self.delegate pauseVideo];
    
    self.addBtn.hidden = YES;
    self.finishBtn.hidden = NO;
}

/** 贴纸删除 退出时需要的操作 **/
- (void)changeCloseScrollView:(SubtitleEffectScrollView *)subtitleScrollView
{
    if(self.isEdittingEffect)
    {
        CaptionRangeView * currentRangeView = [self.trimmerView getcurrentCaptionFromId:self.currentMaterialEffectIndex];
        currentRangeView.file = [self.oldMaterialEffectFile mutableCopy];
        self.oldMaterialEffectFile = nil;
        
        [self updateStickers:YES];
    }else {
        [self cancelEffectAction:nil];
    }
    
    [RDHelpClass animateViewHidden:self.stickerConfigView atUP:NO atBlock:^{
            [self.stickerConfigView setContentTextFieldText: @""];
            [self.stickerConfigView.pasterTextView removeFromSuperview];
            self.stickerConfigView.pasterTextView = nil;
            [self.stickerConfigView removeFromSuperview];
            self.stickerConfigView = nil;
        //    self.trimmerView.rangeSlider.hidden = YES;
    }];
    self.cancelBtn.hidden = YES;
    self.deletedBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.trimmerView.currentCaptionView = nil;
    

}

@end
