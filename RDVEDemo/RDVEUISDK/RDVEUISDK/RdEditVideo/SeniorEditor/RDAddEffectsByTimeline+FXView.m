//
//  RDAddEffectsByTimeline+FXView.m
//  RDVEUISDK
//
//  Created by apple on 2019/11/25.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline+FXView.h"
#import "RDNextEditVideoViewController.h"
#import "UIImageView+RDWebCache.h"
#import "RDAddItemButton.h"
#import "CircleView.h"
#import "RDFileDownloader.h"
//self.fXLabelScrollView;     //特效分类
//self.currentFXScrollView;   //当前选中特效分类


@implementation RDAddEffectsByTimeline (FXView)

//初始化
- (void)initFXView
{
    if( !self.fXConfigView )
    {
        self.currentFXFrameTexture = nil;
        self.currentFXFrameTexture = [self.thumbnailCoreSDK getCurrentFrameWithScale:1.0];
        
        NSMutableArray *typeArray = [[((RDNextEditVideoViewController*)self.delegate) getFilterFxArray] mutableCopy];
        if (!typeArray) {
            typeArray = [NSMutableArray array];
        }
        NSMutableArray<RDFile *> * array = [((RDNextEditVideoViewController*)self.delegate) getFileList];
        if(array.count == 1 && array[0].fileType == kFILEVIDEO) {
            NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:RDLocalizedString(@"时间", nil),@"typeName", nil];
            [typeArray addObject:dic];
        }
        
        [self.filterFxArray removeAllObjects];
        self.filterFxArray = typeArray;
        
        self.isFXFrist = true;
        CGRect rect = self.superview.frame;
        rect.size.height =  rect.size.height + kToolbarHeight;
        self.fXConfigView = [[UIView alloc] initWithFrame:rect];
        self.fXConfigView.hidden = YES;
        self.fXConfigView.backgroundColor = TOOLBAR_COLOR;
        [self.superview.superview insertSubview:self.fXConfigView aboveSubview:self];
        
        float fHeight = (rect.size.height - kToolbarHeight);
        
        self.currentFXScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, fHeight*( 0.132 + 0.085 + 0.156 ), self.fXConfigView.frame.size.width, fHeight * (0.41 + 0.1 ))];
        [self.fXConfigView addSubview:self.currentFXScrollView];
        self.currentFXScrollView.showsVerticalScrollIndicator = NO;
        self.currentFXScrollView.showsHorizontalScrollIndicator = NO;
        
        self.fXLabelScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, fHeight*0.085 + 0.132*fHeight)];
        self.fXLabelScrollView.tag = 1000;
        [self.fXConfigView addSubview:self.fXLabelScrollView];
        
        
        self.fXLabelView = [[UIView alloc] initWithFrame:CGRectMake(0, rect.size.height - kToolbarHeight, rect.size.width, kToolbarHeight)];
        [self.fXConfigView addSubview:self.fXLabelView];
        
        self.fxSaveBtn = [[UIButton alloc] initWithFrame:CGRectMake(rect.size.width - 44, 0, 44, 44)];
        [self.fxSaveBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_勾_"] forState:UIControlStateNormal];
        [self.fxSaveBtn addTarget:self action:@selector(fX_save) forControlEvents:UIControlEventTouchUpInside];
        [self.fXLabelView addSubview:self.fxSaveBtn];
        
        self.fxCancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [self.fxCancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_叉_"] forState:UIControlStateNormal];
        [self.fxCancelBtn addTarget:self action:@selector(fX_cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.fXLabelView addSubview:self.fxCancelBtn];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(44, 0, kWIDTH-88, 44)];
        label.text = RDLocalizedString(@"特效", nil);
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:17];
        [self.fXLabelView addSubview:label];
        
        [self initFXLable];
        
        self.fXConfigView.hidden = YES;
    }
    
}

-(void)initFXLable
{
    if( self.filterFxArray )
    {
        float width = 50;
        self.currentFXLabelIndex = 1;
        __block float contentWidth = 0;
        [self.filterFxArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSDictionary *  objFX = (NSDictionary *) obj;
            
            UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            
            float ItemBtnWidth = [RDHelpClass widthForString:objFX[@"typeName"] andHeight:14 fontSize:14] + 20;
            
            itemBtn.frame = CGRectMake(contentWidth, 0, ItemBtnWidth, self.fXLabelScrollView.bounds.size.height);
//            [itemBtn setTitle: forState:UIControlStateNormal];
//            [itemBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [itemBtn setTitleColor:Main_Color forState:UIControlStateSelected];
//            itemBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        
            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, itemBtn.frame.size.height - 20, itemBtn.frame.size.width, 20)];
            label.font = [UIFont systemFontOfSize:14];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
            label.text = objFX[@"typeName"];
            label.tag = 1001;
            [itemBtn addSubview:label];
            
            itemBtn.tag = idx + 1;
            if (idx == 0) {
                self.currentFXLabelIndex = -1;
                itemBtn.selected = YES;
                [self fxTypeItemBtnAction:itemBtn];
            }
            [itemBtn addTarget:self action:@selector(fxTypeItemBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            
            if( idx == 0 )
               [self fxTypeItemBtnAction:itemBtn];
            
            contentWidth += ItemBtnWidth;
            [self.fXLabelScrollView addSubview:itemBtn];
            
        }];
        self.fXLabelScrollView.contentSize = CGSizeMake(contentWidth+20, 0);
    }
}

-(void)fxTypeItemBtnAction:(UIButton *) btn
{
    if( btn.tag == self.currentFXLabelIndex )
        return;
    
    [self.currentFXScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( [obj isKindOfClass:[RDAddItemButton class]] )
        {
            RDAddItemButton * fxBtn = (RDAddItemButton *)obj;
            [fxBtn stopScrollTitle];
        }
    }];
    
    
    for (UIView *subview in self.currentFXScrollView.subviews) {
        if( [subview isKindOfClass:[UIButton class] ] )
            [subview removeFromSuperview];
    }
    [self.currentFXScrollView removeFromSuperview];
    self.currentFXScrollView = nil;
    
    float fHeight = self.superview.frame.size.height;
    
    self.currentFXScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, fHeight*( 0.132 + 0.085 + 0.156 ), self.fXConfigView.frame.size.width, fHeight * (0.41 + 0.1 ))];
    [self.fXConfigView addSubview:self.currentFXScrollView];
    self.currentFXScrollView.showsVerticalScrollIndicator = NO;
    self.currentFXScrollView.showsHorizontalScrollIndicator = NO;
    
    
    self.currentFXLabelIndex = btn.tag;
    
    __block int tag = btn.tag;
    float height =  self.currentFXScrollView.frame.size.height;
    __block RDAddItemButton * sender = nil;
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //
    
    NSArray * array = nil;
    if( tag < 5 )
    {
        
        array = self.filterFxArray[tag - 1][@"data"];
    }
    else{
        array = [NSArray arrayWithObjects:
                 @"慢动作",
                 @"反复",
                 nil];
    }
    
    float width = height*0.7;
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( (idx == 0) && (tag < 5) )
            return;
        
        RDAddItemButton *fxItemBtn = [RDAddItemButton initFXframe: CGRectMake((idx-((tag < 5)?1:0) ) * (width+15) + 10 , 0, width, height) atpercentage:0.7];
        fxItemBtn.tag = idx + 1;
        
        if( tag < 5 )
        {
            fxItemBtn.label.text = obj[@"name"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [fxItemBtn.thumbnailIV rd_sd_setImageWithURL:[NSURL URLWithString:obj[@"cover"]]];
            });
        }
        else{
            fxItemBtn.label.text = RDLocalizedString([array objectAtIndex:idx],nil);
            UIImage * image = [RDHelpClass imageWithContentOfFile:[NSString stringWithFormat:@"/jianji/effect_icon/剪辑-编辑-特效-%@", [array objectAtIndex:idx]]];
            fxItemBtn.thumbnailIV.image = image;
        }
       
        if( fxItemBtn.tag == (1 + ((tag < 5)?1:0)) )
        {
            fxItemBtn.thumbnailIV.layer.borderColor = Main_Color.CGColor;
            fxItemBtn.label.textColor = [UIColor whiteColor];
            self.currentFXIndex = fxItemBtn.tag;
            sender = fxItemBtn;
        }
        
        
        //            dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentFXScrollView addSubview:fxItemBtn];
        [fxItemBtn addTarget:self action:@selector(addFX:) forControlEvents:UIControlEventTouchUpInside];
        
        float ItemBtnWidth = [RDHelpClass widthForString:fxItemBtn.label.text andHeight:12 fontSize:12];
        
        if( ItemBtnWidth > fxItemBtn.label.frame.size.width )
            [fxItemBtn startScrollTitle];
        //            });
        
    }];
    
    self.currentFXScrollView.delegate = self;
    
    float contentWidth = (array.count-((tag < 5)?1:0) ) * (width+15) + 10;
    if( contentWidth <=  self.currentFXScrollView.frame.size.width )
    {
        contentWidth = self.currentFXScrollView.frame.size.width + 20;
    }
    
    self.currentFXScrollView.contentSize = CGSizeMake( contentWidth, 0);
    //    });
    
    [self.fXLabelScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if( [obj isKindOfClass:[UIButton class]] )
        {
            UIButton *sender = (UIButton*)obj;
            [sender.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                if( [obj isKindOfClass:[UILabel class]] )
                {
                    if( obj.tag == 1001 )
                    {
                        ((UILabel*)obj).textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
                        ((UILabel*)obj).font = [UIFont systemFontOfSize:14];
                    }
                }
                
            }];
            sender.selected = NO;
        }
    }];
    if( !self.isFXFrist )
    {
        self.currentFXIndex = -1;
        if( sender )
            [self addFX:sender];
    }
    else{
        self.isFXFrist = false;
    }
    
    [btn.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if( [obj isKindOfClass:[UILabel class]] )
        {
            if( obj.tag == 1001 )
            {
                ((UILabel*)obj).textColor = Main_Color;
                ((UILabel*)obj).font = [UIFont boldSystemFontOfSize:14];
            }
        }
        
    }];
    btn.selected = YES;
}

-(void)addFX:(UIButton *) btn
{
    if( self.currentFXIndex == btn.tag )
    {
        if( self.delegate && [self.delegate respondsToSelector:@selector(playOrPauseVideo)] )
        {
            [self.delegate playOrPauseVideo];
        }
        return;
    }
    
//    if( self.delegate && ( [self.delegate respondsToSelector:@selector(previewFx:)] ) )
//    {
//        [self.delegate previewFx:nil];
//    }
    
    RDAddItemButton * iteBtn = [self.currentFXScrollView viewWithTag:self.currentFXIndex];
    iteBtn.thumbnailIV.layer.borderColor = [UIColor clearColor].CGColor;
    iteBtn.label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    self.currentFXIndex = btn.tag;
    RDAddItemButton * sender = (RDAddItemButton *) btn;
    sender.thumbnailIV.layer.borderColor = Main_Color.CGColor;
    sender.label.textColor = [UIColor whiteColor];
    
    [self getEffects:NO];
}

-(RDFXFilter * )getEffects:(BOOL) isEffects
{
    RDFXFilter * filter = [[RDFXFilter alloc] init];
    filter.FXTypeIndex = self.currentFXLabelIndex;
    if( self.currentFXLabelIndex == 5 )
    {
        //时间
        if( (self.currentFXIndex-1) == 0 )
        {
            filter.nameStr = RDLocalizedString(@"慢动作", nil);
            filter.timeFilterType = kTimeFilterTyp_Slow;
        }
        else
        {
            filter.nameStr = RDLocalizedString(@"反复", nil);
            filter.timeFilterType = kTimeFilterTyp_Repeat;
        }
        self.timeFxFilter = nil;
        self.timeFxFilter = [filter mutableCopy];
    }
    else
    {
        NSDictionary *itemDic = [[self.filterFxArray[self.currentFXLabelIndex - 1] objectForKey:@"data"] objectAtIndex:self.currentFXIndex - 1];
        NSString *path = [RDHelpClass getEffectCachedFilePath:itemDic[@"file"] updatetime:itemDic[@"updatetime"]];
        NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
        
        filter.nameStr = itemDic[@"name"];
        
        if (self.currentFXLabelIndex != 5 && fileCount == 0) {
            [self downloadFilterFx:isEffects];
            return filter;
        }else {
            if( (self.currentFXLabelIndex == 1) || (self.currentFXLabelIndex == 2) )
            {
                filter.customFilter = [self dynamicAddFilterFx];
                if( isEffects )
                {
                    [self.trimmerView addCapation:nil type:4 captionDuration:0];
                    self.trimmerView.currentCaptionView.file.isErase = NO;
                    self.trimmerView.isTiming = true;
                    self.trimmerView.currentCaptionView.file.customFilter = filter;
                    [self.trimmerView getCaptioncurrentView:YES];
                    [self saveFXTimeRange:NO];
                    if( self.delegate && ( [self.delegate respondsToSelector:@selector(hiddenView)] ) )
                    {
                        [self.delegate hiddenView];
                    }
                }
                else
                {
                    CMTimeRange timeRange = CMTimeRangeMake(self.thumbnailCoreSDK.currentTime, CMTimeMakeWithSeconds(1, TIMESCALE));
                    filter.customFilter.timeRange = timeRange;
                }
                
            }
            else if( (self.currentFXLabelIndex == 3) || (self.currentFXLabelIndex == 4) )
            {
                filter.customFilter = [self transitionAddFx:filter];
                
                if(self.currentFXLabelIndex == 4)
                {
                    if( !filter.ratingFrameTexturePath )
                    {
                        filter = nil;
                        return nil;
                    }
                }
                
                if( isEffects )
                {
                    [self.trimmerView setProgress:CMTimeGetSeconds(filter.customFilter.timeRange.start)/self.thumbnailCoreSDK.duration animated:NO];
                    if( filter && (filter.FXTypeIndex == 4) )
                    {
                        if( self.trimmerView.timeEffectCapation )
                        {
                            NSArray *list = [self.trimmerView getTimesFor_videoRangeView];
                            for (CaptionRangeView *rangeView in list) {
                                if(rangeView.file.captionId > self.trimmerView.timeEffectCapation.file.captionId){
                                    rangeView.file.captionId --;
                                }
                            }
                            
                            [self.trimmerView.timeEffectCapation removeFromSuperview];
                            self.trimmerView.rangeSlider.hidden = YES;
                            self.trimmerView.timeEffectCapation = nil;
                        }
                    }
                    
                    [self.trimmerView addCapation:nil type:4 captionDuration:CMTimeGetSeconds(filter.customFilter.timeRange.duration) genSpecialFilter:filter];
                    [self saveFXTimeRange:true];
                }
            }
        }
    }
    
    if( isEffects )
    {
        if( filter.FXTypeIndex != 4 )
        {
            [RDHelpClass animateViewHidden:self.fXConfigView atUP:NO atBlock:^{
                
                [self.currentFXScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if( [obj isKindOfClass:[RDAddItemButton class]] )
                    {
                        RDAddItemButton * fxBtn = (RDAddItemButton *)obj;
                        [fxBtn stopScrollTitle];
                    }
                }];
                
                [self.fXConfigView removeFromSuperview];
                self.fXConfigView = nil;
                
                if( filter.FXTypeIndex != 5 )
                {
                    if( self.delegate && [self.delegate respondsToSelector:@selector(playOrPauseVideo)] )
                    {
                        [self.delegate playOrPauseVideo];
                    }
                }
            }];
        }
    }
    else{
        
        if( self.delegate && ( [self.delegate respondsToSelector:@selector(previewFx:)] ) )
        {
            [self.delegate previewFx:filter];
        }
    }
    
    return filter;
}

-(void)fX_save
{
    
    
    
    RDFXFilter * filter = nil;
    
//    if( self.delegate && ( [self.delegate respondsToSelector:@selector(previewFx:)] ) )
//    {
//        [self.delegate previewFx:nil];
//    }
    
    bool isSave = true;
    if( self.currentFXLabelIndex == 4 )
    {
        NSMutableArray * array = [self.trimmerView getCaptionsViewForcurrentTime:NO];
        
        if( (array != nil) || ( array.count > 0 )  )
        {
            for (int i= 0;i < array.count;i++) {
                CaptionRangeView *ob = (CaptionRangeView*)array[i];
                if( ob.file.customFilter.ratingFrameTexturePath )
                {
                    isSave = false;
                }
            }
        }
    }
    
    if( isSave )
    {
        if( self.currentFXLabelIndex == 5 )
        {
            if( [self.thumbnailCoreSDK isPlaying] )
            {
                if( self.delegate && [self.delegate respondsToSelector:@selector(pauseVideo)] )
                {
                    [self.delegate pauseVideo];
                }
            }
            
//            [self.thumbnailCoreSDK seekToTime:self.timeFxFilter.filterTimeRangel.start];
            
            [self.trimmerView setTimeEffectCapation:self.timeFxFilter.filterTimeRangel atisShow:YES];
            self.trimmerView.timeEffectCapation.file.fxId = -1;
            self.trimmerView.timeEffectCapation.file.currentFrameTexturePath = nil;
            self.trimmerView.timeEffectCapation.file.customFilter = self.timeFxFilter;
            [self saveFXTimeRange:TRUE];
            
            [RDHelpClass animateViewHidden:self.fXConfigView atUP:NO atBlock:^{
                
                [self.currentFXScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if( [obj isKindOfClass:[RDAddItemButton class]] )
                    {
                        RDAddItemButton * fxBtn = (RDAddItemButton *)obj;
                        [fxBtn stopScrollTitle];
                    }
                }];
                
                [self.fXConfigView removeFromSuperview];
                self.fXConfigView = nil;
            }];
        }
        else
        {
           filter = [self getEffects:YES];
        }
    }
    else
    {
        [((RDNextEditVideoViewController*)self.delegate) showPrompt:RDLocalizedString(@"此处已有定格，添加失败！", nil)];
    }
    
    if(self.currentFXLabelIndex == 4)
    {
        if( !filter )
        {
            [((RDNextEditVideoViewController*)self.delegate) showPrompt:RDLocalizedString(@"图片保存失败！请重试", nil)];
            return;
        }
    }
    
    self.currentFXFrameTexture = nil;
}

- (void)saveFXTimeRange:(bool) isTransition {
    NSMutableArray *__strong arr = [self.trimmerView getTimesFor_videoRangeView_withTime];
    
    NSMutableArray *newEffectArray = [NSMutableArray array];
    NSMutableArray <RDCaptionRangeViewFile *>*newFileArray = [NSMutableArray array];
    for(CaptionRangeView *view in arr){
        RDCustomFilter * filter = view.file.customFilter;
        if(filter){
            [newEffectArray addObject:filter];
            [newFileArray addObject:view.file];
        }
    }
    self.trimmerView.rangeSlider.hidden = YES;
    bool isSaveEffect = true;
    if( isTransition )
    {
        self.finishBtn.hidden = YES;
        self.deletedBtn.hidden = YES;
        self.cancelBtn.hidden = YES;
        self.editBtn.hidden = YES;
        self.addBtn.hidden = NO;
    }
    else
    {
        self.finishBtn.hidden = NO;
        self.deletedBtn.hidden = YES;
        self.cancelBtn.hidden = NO;
        self.editBtn.hidden = YES;
        self.addBtn.hidden = YES;
        isSaveEffect = false;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMaterialEffect:newFileArray:isSaveEffect:)]) {
        [self.delegate updateMaterialEffect:newEffectArray newFileArray:newFileArray isSaveEffect:isSaveEffect];
    }
}

-(void)fX_cancel
{
    if( self.delegate && ( [self.delegate respondsToSelector:@selector(previewFx:)] ) )
    {
        [self.delegate previewFx:nil];
    }
    
    [self performSelector:@selector(setFX_cancel) withObject:nil afterDelay:0.2];
    
    self.trimmerView.isTiming = false;
    self.currentFXFrameTexture = nil;
    
    
}

-(void)setFX_cancel
{
    self.finishBtn.hidden = YES;
    self.deletedBtn.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.editBtn.hidden = YES;
    self.addBtn.hidden = NO;
    
    [RDHelpClass animateViewHidden:self.fXConfigView atUP:NO atBlock:^{
        [self.currentFXScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if( [obj isKindOfClass:[RDAddItemButton class]] )
            {
                RDAddItemButton * fxBtn = (RDAddItemButton *)obj;
                [fxBtn stopScrollTitle];
            }
        }];
        [self.fXConfigView removeFromSuperview];
        self.fXConfigView = nil;
        
        [self cancelEffectAction: nil];
    }];
}

//添加
- (void)addEffectAction_FX
{
    
}

//取消
- (void)cancelEffectAction_FX
{
    
}

//完成
- (void)finishEffectAction_FX
{
    
}

//删除
- (void)deleteEffectAction_FX
{
    
}

//保存
- (void)editAddedEffect_FX
{
    
}

//下载
- (void)downloadFilterFx:(BOOL) isEffects {
    NSDictionary *itemDic = [[self.filterFxArray[self.currentFXLabelIndex - 1] objectForKey:@"data"] objectAtIndex:self.currentFXIndex - 1];
    NSString *path = [RDHelpClass getEffectCachedFilePath:itemDic[@"file"] updatetime:itemDic[@"updatetime"]];
    NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
    
    if (self.currentFXLabelIndex != 5 && fileCount == 0) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        
        __weak typeof(self) myself = self;
        [RDFileDownloader downloadFileWithURL:itemDic[@"file"] cachePath:path httpMethod:GET progress:^(NSNumber *numProgress) {
            NSLog(@"%lf",[numProgress floatValue]);
        } finish:^(NSString *fileCachePath) {
            NSLog(@"下载完成");
            BOOL suc =[RDHelpClass OpenZipp:fileCachePath unzipto:[fileCachePath stringByDeletingLastPathComponent]];
            if (suc ) {
                [self getEffects:isEffects];
            }
        } fail:^(NSError *error) {
            NSLog(@"下载失败");
            [myself.hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [myself.hud show];
            [myself.hud hideAfter:2];
        }];
    }
}

//动感 分屏 添加
-(RDCustomFilter *)dynamicAddFilterFx
{
    NSDictionary *itemDic = [[self.filterFxArray[self.currentFXLabelIndex - 1] objectForKey:@"data"] objectAtIndex:self.currentFXIndex - 1];
    NSString *path = [RDHelpClass getEffectCachedFilePath:itemDic[@"file"] updatetime:itemDic[@"updatetime"]];
    
    NSLog(@"*** begin添加滤镜特效:%f",CMTimeGetSeconds(self.thumbnailCoreSDK.currentTime));
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSString *folderName;
    for (NSString *fileName in files) {
        if (![fileName isEqualToString:@"__MACOSX"]) {
            NSString *folderPath = [path stringByAppendingPathComponent:fileName];
            BOOL isDirectory = NO;
            BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory];
            if (isExists && isDirectory) {
                folderName = fileName;
                break;
            }
        }
    }
    path = [path stringByAppendingPathComponent:folderName];
    
    NSString *itemConfigPath = [path stringByAppendingPathComponent:@"config.json"];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:itemConfigPath];
    NSMutableDictionary *effectDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    
    CMTimeRange timeRange = CMTimeRangeMake(self.thumbnailCoreSDK.currentTime, CMTimeMakeWithSeconds(self.thumbnailCoreSDK.duration-CMTimeGetSeconds(self.thumbnailCoreSDK.currentTime), TIMESCALE));
    RDCustomFilter * filterCustomFilter = [RDGenSpecialEffect getCustomFilerWithFxId:[itemDic[@"id"] intValue] filterFxArray:self.filterFxArray timeRange:timeRange];
    return filterCustomFilter;
}
//转场 定格
-(RDCustomFilter *)transitionAddFx:(RDFXFilter *) filter
{
    NSDictionary *itemDic = [[self.filterFxArray[self.currentFXLabelIndex - 1] objectForKey:@"data"] objectAtIndex:self.currentFXIndex - 1];
    NSString *path = [RDHelpClass getEffectCachedFilePath:itemDic[@"file"] updatetime:itemDic[@"updatetime"]];
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSString *folderName;
    for (NSString *fileName in files) {
        if (![fileName isEqualToString:@"__MACOSX"]) {
            NSString *folderPath = [path stringByAppendingPathComponent:fileName];
            BOOL isDirectory = NO;
            BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory];
            if (isExists && isDirectory) {
                folderName = fileName;
                break;
            }
        }
    }
    path = [path stringByAppendingPathComponent:folderName];
    
    NSString *itemConfigPath = [path stringByAppendingPathComponent:@"config.json"];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:itemConfigPath];
    NSMutableDictionary *effectDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    
    float duration = [effectDic[@"duration"] floatValue];
    if (duration == 0.0) {
        duration = 1.0;
    }
    
    CMTimeRange timeRange = CMTimeRangeMake(self.thumbnailCoreSDK.currentTime, CMTimeMakeWithSeconds(duration, TIMESCALE));
    
    //图片截取 （ 定格 ）
    NSArray *textureParams = effectDic[@"textureParams"];
    __block UIImage *currentFrameTexture;
    [textureParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj objectForKey:@"paramName"] isEqualToString:@"currentFrameTexture"]) {
            //需要先截取当前帧
            currentFrameTexture = self.currentFXFrameTexture;
            *stop = YES;
        }
    }];
    
    RDCustomFilter * filterCustomFilter = nil;
    if (currentFrameTexture) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:kCurrentFrameTextureFolder]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:kCurrentFrameTextureFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
        filter.ratingFrameTexturePath = [RDHelpClass getFileUrlWithFolderPath:kCurrentFrameTextureFolder fileName:@"currentFrameTexture.jpg"].path;
        NSData* imagedata = UIImageJPEGRepresentation(currentFrameTexture, 1.0);
        [[NSFileManager defaultManager] createFileAtPath:filter.ratingFrameTexturePath contents:imagedata attributes:nil];
        imagedata = nil;
        
        filterCustomFilter = [RDGenSpecialEffect getCustomFilerWithFxId:[itemDic[@"id"] intValue] filterFxArray:self.filterFxArray timeRange:timeRange currentFrameTexturePath:filter.ratingFrameTexturePath];
    }else {
        filterCustomFilter = [RDGenSpecialEffect getCustomFilerWithFxId:[itemDic[@"id"] intValue] filterFxArray:self.filterFxArray timeRange:timeRange];
    }
    
    
    return filterCustomFilter;
}

#pragma mark- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if( scrollView == self.currentFXScrollView )
    {
        if( self.currentFXScrollView.contentOffset.x > (self.currentFXScrollView.contentSize.width - self.currentFXScrollView.frame.size.width + KScrollHeight) )
        {
            if(  self.currentFXLabelIndex <  self.filterFxArray.count  )
            {
                self.currentFXScrollView.delegate = nil;
                [self fxTypeItemBtnAction:[self.fXLabelScrollView viewWithTag:self.currentFXLabelIndex+1]];
            }
        }
        else if(  self.currentFXScrollView.contentOffset.x < - KScrollHeight )
        {
            if( self.currentFXLabelIndex > 1 )
            {
                self.currentFXScrollView.delegate = nil;
                [self fxTypeItemBtnAction:[self.fXLabelScrollView viewWithTag:self.currentFXLabelIndex-1]];
            }
        }
    }
    
}
@end
