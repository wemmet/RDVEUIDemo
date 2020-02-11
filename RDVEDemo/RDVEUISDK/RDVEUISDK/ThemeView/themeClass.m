//
//  themeClass.m
//  RDVEUISDK
//
//  Created by apple on 2018/8/15.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "themeClass.h"
#import "RDVECore.h"
#import "RDExportProgressView.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "RDATMHudDelegate.h"
#import "RDCameraManager.h"

@interface themeClass()
{
    float                   m_EndTime;    //结尾时间
    CGSize                  m_videoSize;
    ThemeImage_EffectType   m_oldcindex;   //
    ThemeImage_EffectType   m_CurrentCindxe;
    Effect                  m_CurrrentThemeEffect;//当前主题
    float                   m_CurrrentRotate;//当前旋转角度
    bool                    m_Islast;//最后一个多媒体
    RDFileType              m_CurrentFileType;//当前
    NSMutableArray         *m_EpicEffects;
    NSMutableArray         *m_GrammyEffects;
    NSMutableArray         *m_ActionEffects;
    NSMutableDictionary    *m_SunnyEffects;
    NSMutableDictionary    *m_EndAnimationEffects;
}
@end

@implementation themeClass

- (instancetype)init{
    if(self = [super init]){
        
    }
    return self;
}

-(void) SetVideoResolvPowerType:(VideoResolvPowerType) Type{
    videoResolvPowerType = Type;
}
-(void) setVideoSize:(CGSize )videoSize atEndTime:(float) endTime {
    m_videoSize = videoSize;
    m_EndTime = endTime;
}
-(void) setFileList:(NSMutableArray <RDFile *>*) fileList atEndTime:(float) endTime videoSize:(CGSize )videoSize{
    _fileList = fileList;
    m_videoSize = videoSize;
    m_EndTime = endTime;
    
    m_EpicEffects = [[NSMutableArray alloc] init];
    m_GrammyEffects = [[NSMutableArray alloc] init];
    m_ActionEffects = [[NSMutableArray alloc] init];
    m_SunnyEffects = [[NSMutableDictionary alloc] init];
    m_EndAnimationEffects = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < _fileList.count; i++) {
        
        
        RDFile * tempFile = _fileList[i];
        CGSize imagesize =  [self getVVAssetSize:nil atFile:tempFile];
        
        {//EpicEffects
            int  currentIndex = (arc4random() % 2) + 3;
            
            if( i == 0 )
                currentIndex = Image_Effect_Enlarge;
            [self setFileDuration:tempFile atDurationTIme:2.5];
            if( (currentIndex == Image_Effect_PushDown)
               || (currentIndex == Image_Effect_PushUp) )
            {
                
                if(imagesize.width>=imagesize.height){
                    currentIndex = Image_Effect_Enlarge;
                }
            }
            if( VideoResolvPower_Film != videoResolvPowerType )
                currentIndex = Image_Effect_Enlarge;
            
            if( tempFile.fileType == kFILEVIDEO )
            {
                if(imagesize.width > imagesize.height)
                {
                    currentIndex = Image_Effect_Default;
                }
                else
                {
                    currentIndex = Image_Effect_Default;
                }
            }
            
            if( i == (_fileList.count-1) )
            {
                m_CurrrentThemeEffect =  Effect_Grammy;
                currentIndex = Image_Effect_Enlarge;
            }
            
            [m_EpicEffects addObject:[NSNumber numberWithInt:currentIndex]];
        }
        
        {//GrammyEffects
            int  currentIndex = (arc4random() % 4) + 1;
            if( i == 0 )
                currentIndex = Image_Effect_Enlarge;
            
            if( (currentIndex == Image_Effect_PushDown)
               || (currentIndex == Image_Effect_PushUp) )
            {
                if(imagesize.width>=imagesize.height){
                    currentIndex = currentIndex%2 + 1;
                }
            }
            
            if( i == (_fileList.count-1) )
                currentIndex = Image_Effect_Enlarge;
            
            if( ( tempFile.fileType == kFILEVIDEO ) && ( imagesize.width <= imagesize.height ) )
            {
                currentIndex = Image_Effect_Default;
            }
            
            [m_GrammyEffects addObject:[NSNumber numberWithInt:currentIndex]];
        }
        
        {//m_ActionEffects
            
            NSArray *list  = @[[NSNumber numberWithInt:Image_Effect_PushDown],[NSNumber numberWithInt:Image_Effect_PushUp]];
            CGSize size =  [self getVVAssetSize:nil atFile:tempFile];
            int  idex = arc4random() % (list.count);
            ThemeImage_EffectType currentIndex = [list[idex] intValue];
            if( (size.width>=size.height) || ( videoResolvPowerType ==  VideoResolvPower_Portait ) ){
                list  = @[[NSNumber numberWithInt:Image_Effect_Enlarge],[NSNumber numberWithInt:Image_Effect_Narrow]];//,[NSNumber numberWithInt:Image_Effect_Fade]
                idex = arc4random() % (list.count);
                currentIndex = [list[idex] intValue];
            }
            if( tempFile.fileType == kFILEVIDEO )
            {
                list  = @[[NSNumber numberWithInt:Image_Effect_Enlarge],[NSNumber numberWithInt:Image_Effect_Narrow]];//,[NSNumber numberWithInt:Image_Effect_Fade]
                idex = arc4random() % (list.count);
                currentIndex = [list[idex] intValue];
                if( size.width < size.height )
                {
                    currentIndex = Image_Effect_Default;
                }
            }
            
            [m_ActionEffects addObject:[NSNumber numberWithInt:currentIndex]];
        }
        
        {
            
        }
    }
}

#pragma mark-Epic
-(void)GetEpicEffect:(NSMutableArray *) scenes
{
    m_EndTime = 0.3;
    m_CurrrentThemeEffect =  Effect_Epic;
    for (int i = 0; i < _fileList.count; i++) {
        
        
        RDFile * tempFile = [_fileList[i] copy];
        int  currentIndex = [m_EpicEffects[i] intValue];
        
        RDScene * scene = [self getScene_Effect:tempFile atIndex:i atEffect:currentIndex atEndingSpecialEffect:Effect_Epic atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        [scenes addObject:scene];
    }
    //结束闪黑
    {
        RDFile * tempFile = [_fileList[_fileList.count - 1] copy];
        [self setFileDuration:tempFile atDurationTIme:0.5];
        RDScene * scene = [self FlashBlackHandle:tempFile atEffect:0];
        [scenes addObject:scene];
    }
}

#pragma mark-Grammy
-(void) GetGrammyEffect:(NSMutableArray *) scenes{
    m_EndTime = 0.3;
    m_CurrrentThemeEffect =  Effect_Grammy;
    for (int i = 0; i < _fileList.count; i++) {
        
        RDFile * tempFile = [_fileList[i] copy];
        int  currentIndex = [m_GrammyEffects[i] intValue];
       
        
        [self setFileDuration:tempFile atDurationTIme:2.5];
        RDScene * scene = [self getScene_Effect:tempFile atIndex:i atEffect:currentIndex atEndingSpecialEffect:0 atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        [scenes addObject:scene];
    }
}

#pragma mark-Action
-(void) GetActionEffect:(NSMutableArray *) scenes{
    m_EndTime = 0.30;
    
    m_CurrrentThemeEffect =  Effect_Action;
    for (int i = 0; i < _fileList.count; i++) {
        RDFile * tempFile = [_fileList[i] copy];
        [self setFileDuration:tempFile atDurationTIme:4];
        
        ThemeImage_EffectType currentIndex = [m_ActionEffects[i] intValue];
        
        RDScene * scene = [self getScene_Effect:tempFile atIndex:i atEffect:currentIndex atEndingSpecialEffect:1 atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        //scene.transition.duration = 1.2;
        [scenes addObject:scene];
    }

}

#pragma mark-Boxed
-(void) GetBoxedEffect:(NSMutableArray *) scenes{
    m_EndTime = 0.4;
    m_CurrrentThemeEffect = Effect_Boxed;
    for (int i = 0; i < _fileList.count; i++) {
        int  currentIndex = Image_Effect_Narrow;
        
        RDFile * tempFile = [_fileList[i] copy];
        [self setFileDuration:tempFile atDurationTIme:4];
        RDScene * scene = [self getScene_Effect:tempFile atIndex:i atEffect:currentIndex atEndingSpecialEffect:2 atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        if(i<_fileList.count-1){
            scene.transition.type = RDVideoTransitionTypeNone;
        }else{
            scene.transition.type = RDVideoTransitionTypeBlinkBlack;
            scene.transition.duration = 0.2;
        }
        [scenes addObject:scene];
    }
    //结束淡入
    {
        RDFile * tempFile = [_fileList[_fileList.count - 1] copy];
        [self setFileDuration:tempFile atDurationTIme:m_EndTime];
        RDScene * scene = [self FlashBlackHandle:tempFile atEffect:2];
        [scenes addObject:scene];
    }
}

#pragma mark-Lapse
-(void) GetLapseEffect:(NSMutableArray *) scenes
{
    m_EndTime = 0.3;
    m_CurrentCindxe = Image_Effect_Default;
    m_CurrrentThemeEffect = Effect_Grammy;
    for (int i = 0; i < _fileList.count; i++) {
        m_CurrrentRotate = 0;
        RDFile * tempFile = [_fileList[i] copy];
        [self setFileDuration:tempFile atDurationTIme:4];
        RDScene * scene;
       
        CGSize size =  [self getVVAssetSize:nil atFile:tempFile];
        ThemeImage_EffectType currentIndex = ((videoResolvPowerType ==VideoResolvPower_Film )? ( ( size.height > size.width  )?Image_Effect_PushProEnlarge:Image_Effect_Enlarge ):    Image_Effect_Enlarge);
        
        if( tempFile.fileType == kFILEVIDEO )
        {
            currentIndex = Image_Effect_Default;
            
            if( size.width < size.height )
            {
                currentIndex = Image_Effect_Default;
            }
        }
        
        scene  = [self getScene_Effect:tempFile atIndex:i atEffect:currentIndex atEndingSpecialEffect:Effect_Lapse atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        
        [scenes addObject:scene];
        
    }
    
    m_CurrrentRotate = 0;
}
#pragma mark-Flick
-(void)GetFlick:(NSMutableArray *) scenes
{
    m_CurrrentThemeEffect = Effect_Flick;
    if( videoResolvPowerType ==  VideoResolvPower_Film)
    {
        for (int i = 0; i < _fileList.count; i++) {
            RDScene * scene = [[RDScene alloc] init];
            RDFile * tempFile = [_fileList[i] copy];
            [self setFileDuration:tempFile atDurationTIme:4];
            //判断推动方向
            ThemeImage_EffectType typ_ThemeImage_EffectType;
            bool WorH;
            int  index = 3;
            float Oldoffset = 0;
            float offset;
            if( i == (_fileList.count - 1) )
            {
                
                VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:Effect_Flick];
                
                CGSize contentSize = [self getVVAssetSize:vvasset atFile:nil];
                float off = (contentSize.width * (m_videoSize.height/m_videoSize.width))/contentSize.height;
                CGRect crop = CGRectMake(0, (1-off)/3.0, 1, off);

                if(contentSize.height/contentSize.width < (m_videoSize.height/m_videoSize.width)){
                   off = (m_videoSize.width/m_videoSize.height) * (m_videoSize.width/m_videoSize.height);
                    crop = CGRectMake((1-off)/2.0, 0, off, 1);
                }else if (contentSize.height/contentSize.width == (m_videoSize.height/m_videoSize.width)){
                    crop = CGRectMake(0, 0, 1, 1);
                }else{
                    //crop = CGRectMake((1-off)/2.0, 0, off, 1);
                }
                vvasset.isBlurredBorder = NO;
                vvasset.crop = crop;
                vvasset.fillType = RDImageFillTypeFull;
                vvasset.videoFillType = RDVideoFillTypeFit;
                [scene.vvAsset addObject:vvasset];
                scene.transition.type = RDVideoTransitionTypeMask;
                scene.transition.maskURL = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/zhuanchang/transition/transition6.jpg"] Type:@""]];
                scene.transition.duration = 2.0;
                
                [scenes addObject:scene];
                break;
            }
            else if( i == (_fileList.count - 2) )
            {
                typ_ThemeImage_EffectType = Image_Effect_PiecewiseDown;
                WorH = NO;
                index = 3;
                offset = 0;
            }
            else
            {
                typ_ThemeImage_EffectType = Image_Effect_PiecewiseUp;
                WorH = YES;
                index = 3;
                UIImage * image = [RDHelpClass getThumbImageWithUrl:tempFile.contentURL];
                if( image.size.height >= image.size.width )
                {
                    if( 0 == (i%2) )
                    {
                        offset = -0.2;
                        Oldoffset = 0.2;
                    }
                    else
                    {
                        offset = 0.2;
                        Oldoffset = -0.2;
                    }
                }
                else
                {
                    offset = 0;
                    Oldoffset = 0;
                }
              
            }
            {
                VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:Effect_Flick];
                vvasset.isBlurredBorder = NO;
                vvasset.type = RDAssetTypeImage;
                vvasset.url =  [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Boxed背景图" Type:@"jpg"]];
                vvasset.isBlurredBorder = NO;
                [scene.vvAsset addObject:vvasset];
            }
            //设置推动动画
            if( i > 0 )
            {
                RDFile *  Tempfile = [_fileList[i-1] copy];
                [self GetVVAssetEffect:scene atFile:Tempfile atTimeStart:0 atTimeEnd:1.0 atThemeImage_EffectType:typ_ThemeImage_EffectType atOffsetW:Oldoffset atCount:index atWorH:WorH atIndex:i];
            }
            RDFile *  Tempfile1 = [tempFile copy];
            [self GetPushEffect:scene atFile:Tempfile1 atTime:1.0 atThemeImage_EffectType:typ_ThemeImage_EffectType atOffsetW:offset atCount:index atWorH:WorH atIndex:i];
            
            [scenes addObject:scene];
        }
        
        //白图
        {
            RDScene * scene = [[RDScene alloc] init];
            VVAsset * vvasset = [self getVvasset:_fileList[_fileList.count-1] atThemeIndex:Effect_Flick];
            vvasset.fillType = RDImageFillTypeFull;
            vvasset.type = RDAssetTypeImage;
            vvasset.url =  [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Boxed背景图" Type:@"jpg"]];
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( 2, TIMESCALE));
            vvasset.isBlurredBorder = NO;
            [scene.vvAsset addObject:vvasset];
            [scenes addObject:scene];
        }
    }
    else
    {
        m_EndTime = 0.3;
        for (int i = 0; i < _fileList.count; i++) {
            int  currentIndex = (arc4random() % 2) + 1;
            RDFile * tempFile = [_fileList[i] copy];
            [self setFileDuration:tempFile atDurationTIme:4];
            RDScene * scene;
            if( i == (_fileList.count - 1) )
            {
                scene = [[RDScene alloc] init];
                VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:Effect_Flick];
                vvasset.isBlurredBorder = NO;
                //if( tempFile.fileType == kFILEVIDEO  )
                {
                    CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                    CGRect crop = CGRectMake(0, 0, 1, 1);
                    float oldWidth = (m_videoSize.width/m_videoSize.height)*currentsize.height;
                    if( oldWidth < currentsize.width  )
                    {
                        float offtset = oldWidth/currentsize.width;
                        crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                    }
                    else if(  oldWidth > currentsize.width   )
                    {
                        float oldHeihgt = (m_videoSize.height/m_videoSize.width)*currentsize.width;
                        float offtset = oldHeihgt/currentsize.height;
                        crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                    }
                    vvasset.crop = crop;
                }
                [scene.vvAsset addObject:vvasset];
                scene.transition.type = RDVideoTransitionTypeMask;
                scene.transition.maskURL = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/zhuanchang/transition/transition6.jpg"] Type:@""]];
                scene.transition.duration = 2.0;
            }
            else
            {
                
                scene  = [self getScene_Effect:tempFile atIndex:i atEffect:currentIndex atEndingSpecialEffect:Effect_Flick atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
            }
            [scenes addObject:scene];
        }
        //白图
        {
            RDScene * scene = [[RDScene alloc] init];
            VVAsset * vvasset = [self getVvasset:_fileList[_fileList.count-1] atThemeIndex:Effect_Flick];
            vvasset.type = RDAssetTypeImage;
            vvasset.fillType = RDImageFillTypeFull;
            vvasset.url =  [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Boxed背景图" Type:@"jpg"]];
            vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( 2, TIMESCALE));
            vvasset.isBlurredBorder = NO;
            [scene.vvAsset addObject:vvasset];
            [scenes addObject:scene];
        }
    }
    return;
}

#pragma mark-serene

- (NSString *)returnFileThumbImagePath:(RDFile *)file{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [paths objectAtIndex:0];
    
    folderPath = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",@"TmpImages"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:folderPath]){
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *path = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.png",[file.contentURL hash]]];
    UIImage *image = [RDHelpClass getThumbImageWithUrl:file.contentURL];
    
    [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
    return path;
}

#if 1

-(void)GetSerene:(NSMutableArray *) scenes{
    //__block typeof(self) myself = self;
    m_EndTime = 1.0;
    m_CurrrentThemeEffect = Effect_Serene;
    __block NSInteger lastAr = 0;
    WeakSelf(self);
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        StrongSelf(self);
        float off_x = arc4random()%20/100.0;
        float off_y = arc4random()%20/100.0;
        float scale = 0.6;
        CGSize currentsize = [strongSelf getVVAssetSize:nil atFile:obj];
        
        float off_setb = (1 - strongSelf->m_videoSize.height * currentsize.width/currentsize.height/strongSelf->m_videoSize.width * scale)/2.0;
        NSInteger ar = arc4random()%2;
        if(ar == lastAr){
            if(ar == 0){
                ar = 1;
            }else{
                ar = 0;
            }
        }
        lastAr = ar;
        
        CGRect beforFrame = CGRectMake(1 + (ar == 0 ? (off_setb - off_x) : (off_setb + (1-off_setb*2.0))), (ar == 0 ? ((1- scale)/2.0 - off_y) : ((1- scale)/2.0 + off_y)), 1-off_setb*2.0, scale);
        //beforFrame.origin.x = 1+ MIN(beforFrame.origin.x, 1 - beforFrame.size.width);
        
        obj.rectInScene = beforFrame;
    }];
    
    for (NSInteger i = 0; i <= (_fileList.count - 1); i++) {
        RDScene * scene = [[RDScene alloc] init];
        NSMutableArray *items = [[NSMutableArray alloc] init];
        NSInteger arc = i == 0 ? 2 : arc4random()%2+2;
        if(arc == 2){
            for (NSInteger j = 0; j<2; j++) {
                RDFile *file = _fileList[i];
                VVAsset * vvasset = [self getVvasset:file atThemeIndex:2];
                vvasset.fillType = RDImageFillTypeFull;
                vvasset.isBlurredBorder = NO;
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
                vvasset.startTimeInScene = kCMTimeZero;
                if(j == 0){
                    vvasset.rectInVideo = file.rectInScene;
                }else{
                    
                    vvasset.url =  [NSURL fileURLWithPath:[self returnFileThumbImagePath:file]];
                    vvasset.type = RDAssetTypeImage;
                    vvasset.rectInVideo = CGRectMake(file.rectInScene.origin.x, file.rectInScene.origin.y, file.rectInScene.size.width*0.8, file.rectInScene.size.height * 0.8);
                }
                [items addObject:vvasset];
                
            }
        }else{
            for (NSInteger j = 0; j<2; j++) {
                RDFile *file = _fileList[i];
                VVAsset * vvasset = [self getVvasset:file atThemeIndex:2];
                vvasset.fillType = RDImageFillTypeFull;
                vvasset.isBlurredBorder = NO;
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
                vvasset.startTimeInScene = kCMTimeZero;
                if(j == 0){
                    vvasset.rectInVideo = file.rectInScene;
                }else{
                    vvasset.url =  [NSURL fileURLWithPath:[self returnFileThumbImagePath:file]];
                    vvasset.type = RDAssetTypeImage;
                    vvasset.rectInVideo = CGRectMake(file.rectInScene.origin.x, file.rectInScene.origin.y, file.rectInScene.size.width*0.8, file.rectInScene.size.height * 0.8);
                }
                [items addObject:vvasset];
                
            }
            RDFile *file = _fileList[i-1];
            VVAsset * vvasset = [self getVvasset:file atThemeIndex:2];
            vvasset.url =  [NSURL fileURLWithPath:[self returnFileThumbImagePath:file]];
            vvasset.type = RDAssetTypeImage;
            vvasset.isBlurredBorder = NO;
            vvasset.fillType = RDImageFillTypeFull;
            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
            vvasset.startTimeInScene = kCMTimeZero;
            vvasset.rectInVideo = CGRectMake(file.rectInScene.origin.x, file.rectInScene.origin.y, file.rectInScene.size.width*0.8, file.rectInScene.size.height * 0.8);
            [items addObject:vvasset];
        }
       
        if(items.count>0){
            for (NSInteger m = items.count - 1;m>=0;m--){
                VVAsset *  _Nonnull obj = items[m];
                [scene.vvAsset addObject:obj];
            }
            scene.transition.type = RDVideoTransitionTypeLeft;
            scene.transition.duration = 1.0;
            [scenes addObject:scene];
        }
        
    }
    
    
    for (int idx = 0; idx<=(scenes.count - 1); idx++) {
        
        NSMutableArray * _Nonnull item = ((RDScene *)scenes[idx]).vvAsset;
        for (int im = 0; im<=(item.count - 1); im++) {
            
            
            NSMutableArray *animations = [[NSMutableArray alloc] init];
            VVAsset * _Nonnull obj = item[im];
            
            float scale1 = 0.9;
            CGSize currentsize = [self getVVAssetSize:obj atFile:nil];
            //NSLog(@"name:%@ size:%f,%f",obj.url,currentsize.width,currentsize.height);
            float off_set = (1 - m_videoSize.height * currentsize.width/currentsize.height/m_videoSize.width * scale1)/2.0;
            CGRect frame = CGRectMake(off_set, (1 - scale1)/2.0, 1-off_set*2.0, scale1);
            CGRect beforFrame = obj.rectInVideo;
//            CGRect behandFrame = CGRectMake(-scale1, (1 - scale1)/2.0, 1-off_set*2.0, scale1);
            
            
            NSLog(@"场景：%d -->媒体：%d rect:%@",idx,im,NSStringFromCGRect(beforFrame));
            
//            if(im == (item.count - 1)){
//
//                behandFrame = CGRectMake(-scale1, (arc4random()%100/100.0) , 1-off_set*2.0, scale1);//(1 - scale1)/2.0
//
//            }
            UIBezierPath *path = [UIBezierPath bezierPath];
            path.lineCapStyle = kCGLineCapRound;
            path.lineJoinStyle = kCGLineJoinRound;
            [path moveToPoint:CGPointMake(m_videoSize.width*obj.rectInVideo.origin.x, m_videoSize.height*obj.rectInVideo.origin.y)];
            [path addLineToPoint:CGPointMake((arc4random()%2 == 0) ? m_videoSize.width* (obj.rectInVideo.origin.x - 100.0/m_videoSize.width) : m_videoSize.width*(100.0/m_videoSize.width + obj.rectInVideo.origin.x), m_videoSize.height*obj.rectInVideo.origin.y)];
            [path moveToPoint:CGPointMake(m_videoSize.width*obj.rectInVideo.origin.x, m_videoSize.height*obj.rectInVideo.origin.y)];
            
            {
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = 0;
                animate.crop = CGRectMake(0.125, 0.125, 0.75, 0.75);
                animate.saturation = (im == (item.count - 1) ? 1 : 0);
                animate.rect = ( beforFrame);
                [animations addObjectsFromArray:@[animate]];
                
            }
            
            {
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = 1;
                animate.crop = CGRectMake(0.125, 0.125, 0.75, 0.75);
                animate.rect = (im == (item.count - 1) ? frame : CGRectMake(beforFrame.origin.x - 1, beforFrame.origin.y, beforFrame.size.width, beforFrame.size.height));
                
                animate.saturation = (im == (item.count - 1) ? 1 : 0);
                animate.fillScale = 1.0;
                [animations addObjectsFromArray:@[animate]];
                
            }
            
            {
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = 3.0;
                animate.crop = CGRectMake(0, 0, 1, 1);
                animate.saturation = (im == (item.count - 1) ? 1 : 0);
                animate.fillScale = 1.0;
                animate.rect = (im == (item.count - 1) ? frame : CGRectMake(beforFrame.origin.x - 1, beforFrame.origin.y, beforFrame.size.width, beforFrame.size.height));
                [animations addObjectsFromArray:@[animate]];
                
            }
            
            {
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = 4;
                animate.saturation = (im == (item.count - 1) ? 1 : 0);
                animate.fillScale = (im == (item.count - 1) ? 0.9 : 1.0);
                animate.crop = CGRectMake(0, 0, 1, 1);
                animate.rect = (im == (item.count - 1) ? frame : CGRectMake(beforFrame.origin.x - 1, beforFrame.origin.y, beforFrame.size.width, beforFrame.size.height));
                [animations addObjectsFromArray:@[animate]];
            }
            obj.alpha = ((im == (item.count - 1)) ? 1.0 : (im+1)/(float)item.count*0.6);
            obj.animate = animations;
//            [animations enumerateObjectsUsingBlock:^(VVAssetAnimatePosition *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//
//                NSLog(@"idx:%d im:%d point:%@",idx,im, obj.pointsArray);
//            }];
        }
    }
}

//#else

-(void)GetSerene1:(NSMutableArray *) scenes{
    //__block typeof(self) myself = self;
    m_EndTime = 1.0;
    m_CurrrentThemeEffect = Effect_Serene;
    
    [_fileList enumerateObjectsUsingBlock:^(RDFile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        float off_x = arc4random()%100/100.0;
        float off_y = arc4random()%60/100.0;
        float scale = (arc4random()%5 + 2) /10.0;
        CGSize currentsize = [self getVVAssetSize:nil atFile:obj];
        
        float off_setb = (1 - m_videoSize.height * currentsize.width/currentsize.height/m_videoSize.width * scale)/2.0;
        CGRect beforFrame = CGRectMake(off_x, off_y, 1-off_setb*2.0, scale);
        
        obj.rectInScene = beforFrame;
    }];
    
    for (NSInteger i = 0; i <= (_fileList.count - 1); i++) {
        RDScene * scene = [[RDScene alloc] init];
        NSMutableArray *items = [[NSMutableArray alloc] init];
        for (NSInteger j = 0; j<MIN(3, _fileList.count - i); j++) {
            RDFile *file = _fileList[j+i];
            VVAsset * vvasset = [self getVvasset:file atThemeIndex:2];
            if(j != 0){
                vvasset.url =  [NSURL fileURLWithPath:[self returnFileThumbImagePath:file]];
                vvasset.type = RDAssetTypeImage;
            }
            vvasset.fillType = RDImageFillTypeFull;
            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
            vvasset.startTimeInScene = kCMTimeZero;
            vvasset.rectInVideo = file.rectInScene;
            [items addObject:vvasset];
            
        }
        for( int k = 0 ;k< 3 - MIN(3, _fileList.count - i);k++){
            RDFile *file = _fileList[i];
            VVAsset * vvasset = [self getVvasset:file atThemeIndex:2];
            vvasset.fillType = RDImageFillTypeFull;
            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
            vvasset.startTimeInScene = kCMTimeZero;
            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
            vvasset.startTimeInScene = kCMTimeZero;
            vvasset.rectInVideo = file.rectInScene;
            [items addObject:vvasset];

        }
//        for( int k = 0 ;k< 3 - MIN(3, _fileList.count - i);k++){
//            RDFile *file = _fileList[i];
//            VVAsset * vvasset = [self getVvasset:file atThemeIndex:2];
//
//            vvasset.url =  [NSURL fileURLWithPath:[self returnFileThumbImagePath:file]];
//            vvasset.type = RDAssetTypeImage;
//
//            vvasset.fillType = RDImageFillTypeFull;
//            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(4, 600));
//            vvasset.startTimeInScene = kCMTimeZero;
//            {
//                float off_x = arc4random()%100/100.0;
//                float off_y = arc4random()%60/100.0;
//                float scale = (arc4random()%5 + 2) /10.0;
//                CGSize currentsize = [self getVVAssetSize:nil atFile:file];
//
//                float off_setb = (1 - m_videoSize.height * currentsize.width/currentsize.height/m_videoSize.width * scale)/2.0;
//                CGRect beforFrame = CGRectMake(off_x, off_y, 1-off_setb*2.0, scale);
//                //vvasset.rectInVideo = beforFrame;
//            }
//            [items addObject:vvasset];
//        }
        if(items.count>0){
            for (NSInteger m = items.count - 1;m>=0;m--){
                VVAsset *  _Nonnull obj = items[m];
                [scene.vvAsset addObject:obj];
            }
            scene.transition.type = RDVideoTransitionTypeNone;
            scene.transition.duration = 0.2;
            [scenes addObject:scene];
        }
        
    }
    
    
    for (int idx = 0; idx<=(scenes.count - 1); idx++) {
        
        NSMutableArray * _Nonnull item = ((RDScene *)scenes[idx]).vvAsset;
        for (int im = 0; im<=(item.count - 1); im++) {
            
            
            NSMutableArray *animations = [[NSMutableArray alloc] init];
            VVAsset * _Nonnull obj = item[im];
            
            float scale1 = 0.9;
            CGSize currentsize = [self getVVAssetSize:obj atFile:nil];
            
            float off_set = (1 - m_videoSize.height * currentsize.width/currentsize.height/m_videoSize.width * scale1)/2.0;
            CGRect frame = CGRectMake(off_set, (1 - scale1)/2.0, 1-off_set*2.0, scale1);
            CGRect behandFrame = CGRectMake(-scale1, (1 - scale1)/2.0, 1-off_set*2.0, scale1);
            if(im == (item.count - 1)){
                VVAsset * _Nonnull obj = item[im - 2];
                if(obj.rectInVideo.origin.x+obj.rectInVideo.size.width<0.5){
                    behandFrame = CGRectMake(1, (arc4random()%100/100.0), 1-off_set*2.0, scale1);
                }else{
                    behandFrame = CGRectMake(-scale1, (arc4random()%100/100.0) , 1-off_set*2.0, scale1);//(1 - scale1)/2.0
                }
            }
            CGRect beforFrame = im ==(item.count - 1) ? frame : obj.rectInVideo;
            
            UIBezierPath *path = [UIBezierPath bezierPath];
            path.lineCapStyle = kCGLineCapRound;
            path.lineJoinStyle = kCGLineJoinRound;
            [path moveToPoint:CGPointMake(m_videoSize.width*obj.rectInVideo.origin.x, m_videoSize.height*obj.rectInVideo.origin.y)];
            [path addLineToPoint:CGPointMake((arc4random()%2 == 0) ? m_videoSize.width* (obj.rectInVideo.origin.x - 100.0/m_videoSize.width) : m_videoSize.width*(100.0/m_videoSize.width + obj.rectInVideo.origin.x), m_videoSize.height*obj.rectInVideo.origin.y)];
            [path moveToPoint:CGPointMake(m_videoSize.width*obj.rectInVideo.origin.x, m_videoSize.height*obj.rectInVideo.origin.y)];
            NSInteger arc = arc4random()%2;
            {
                CGPoint l_t = CGPointMake(beforFrame.origin.x,beforFrame.origin.y);
                CGPoint l_b = CGPointMake(beforFrame.origin.x,beforFrame.size.height + beforFrame.origin.y);
                CGPoint r_t = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y );
                CGPoint r_b = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y + beforFrame.size.height);
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = 0;
                //animate.saturation = 0.0;
//                animate.rect = ( beforFrame);
                [animate setPointsLeftTop:l_t rightTop:r_t rightBottom:r_b leftBottom:l_b];
                [animations addObjectsFromArray:@[animate]];
                
            }
            float change = ((arc4random()%3 + 3)/100.0);
            
            {
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = 1;
                CGPoint l_t,l_b,r_t,r_b;
                
                if(im == (item.count - 1)){
                    l_t = CGPointMake(frame.origin.x ,frame.origin.y);
                    l_b = CGPointMake(frame.origin.x ,frame.size.height + frame.origin.y);
                    r_t = CGPointMake(frame.origin.x  + frame.size.width,frame.origin.y);
                    r_b = CGPointMake(frame.origin.x  + frame.size.width,frame.origin.y + frame.size.height);
                    
                }else{
                    l_t = CGPointMake(beforFrame.origin.x,beforFrame.origin.y);
                    l_b = CGPointMake(beforFrame.origin.x,beforFrame.size.height + beforFrame.origin.y);
                    r_t = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y);
                    r_b = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y + beforFrame.size.height);
                }
                

                [animate setPointsLeftTop:l_t rightTop:r_t rightBottom:r_b leftBottom:l_b];
//                animate.rect = (im == (item.count - 1) ? frame : beforFrame);
                animate.fillScale = 1.0;
                [animations addObjectsFromArray:@[animate]];
                
            }
            NSArray *points;
            {
                CGPoint l_t,l_b,r_t,r_b;
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = CMTimeGetSeconds(obj.timeRange.duration) - 1.0;
                animate.fillScale = (im == (item.count - 1) ? 1.0 : 1.0);
                if(im == (item.count - 1)){
                    l_t = CGPointMake(frame.origin.x ,frame.origin.y);
                    l_b = CGPointMake(frame.origin.x ,frame.size.height + frame.origin.y);
                    r_t = CGPointMake(frame.origin.x  + frame.size.width,frame.origin.y);
                    r_b = CGPointMake(frame.origin.x  + frame.size.width,frame.origin.y + frame.size.height);
                    if(arc == 0){
                        l_t = CGPointMake(l_t.x, l_t.y + change);
                        l_b = CGPointMake(l_b.x, l_b.y - change);
                    }else{
                        r_t = CGPointMake(r_t.x, r_t.y + change);
                        r_b = CGPointMake(r_b.x, r_b.y - change);
                    }
                    
                    NSLog(@"index%d 右  %zd",idx,arc);
                    
                }else{
                    l_t = CGPointMake(beforFrame.origin.x,beforFrame.origin.y);
                    l_b = CGPointMake(beforFrame.origin.x,beforFrame.size.height + beforFrame.origin.y);
                    r_t = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y);
                    r_b = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y + beforFrame.size.height);
                }
//                animate.rect = (im == (item.count - 1) ? frame : beforFrame);
                [animate setPointsLeftTop:l_t rightTop:r_t rightBottom:r_b leftBottom:l_b];

                if((idx ==(scenes.count - 1))){
                    points = [[NSArray alloc] initWithObjects:[NSValue valueWithCGPoint:l_t],[NSValue valueWithCGPoint:r_t],[NSValue valueWithCGPoint:r_b],[NSValue valueWithCGPoint:l_b], nil];
                }
                [animations addObjectsFromArray:@[animate]];
                
            }
            
            {
                CGPoint l_t,l_b,r_t,r_b;
                VVAssetAnimatePosition *animate= [[VVAssetAnimatePosition alloc] init];
                animate.atTime = CMTimeGetSeconds(obj.timeRange.duration)- ((idx==(scenes.count - 1)) ? 0 : 0.2);
                animate.fillScale = (im == (item.count - 1) ? 0.9 : 1.0);
                
//                animate.rect = (im == (item.count - 1) ? behandFrame : (im == (item.count - 2) ? frame :beforFrame));
                
                if(points){
                    [animate setPointsLeftTop:[points[0] CGPointValue]  rightTop:[points[1] CGPointValue] rightBottom:[points[2] CGPointValue] leftBottom:[points[3] CGPointValue]];
                }else{
                    
                    if(im == (item.count - 1)){
                        l_t = CGPointMake(behandFrame.origin.x ,behandFrame.origin.y);
                        l_b = CGPointMake(behandFrame.origin.x ,behandFrame.size.height + behandFrame.origin.y);
                        r_t = CGPointMake(behandFrame.origin.x  + behandFrame.size.width,behandFrame.origin.y);
                        r_b = CGPointMake(behandFrame.origin.x  + behandFrame.size.width,behandFrame.origin.y  + behandFrame.size.height);
                        
                        if(arc == 0){
                            l_t = CGPointMake(l_t.x, l_t.y + change - (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                            l_b = CGPointMake(l_b.x, l_b.y - change + (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                            r_t = CGPointMake(r_t.x, r_t.y - (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                            r_b = CGPointMake(r_b.x, r_b.y + (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                        }else{
                            r_t = CGPointMake(r_t.x, r_t.y + change - (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                            r_b = CGPointMake(r_b.x, r_b.y - change + (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                            l_t = CGPointMake(l_t.x, l_t.y - (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                            l_b = CGPointMake(l_b.x, l_b.y + (m_videoSize.width >= m_videoSize.height ? 0.4 : 0));
                        }
                        
                    }else if(im == (item.count - 2)){
                        l_t = CGPointMake(frame.origin.x ,frame.origin.y);
                        l_b = CGPointMake(frame.origin.x ,frame.size.height + frame.origin.y);
                        r_t = CGPointMake(frame.origin.x  + frame.size.width,frame.origin.y);
                        r_b = CGPointMake(frame.origin.x  + frame.size.width,frame.origin.y + frame.size.height);
                    }else{
                        l_t = CGPointMake(beforFrame.origin.x,beforFrame.origin.y);
                        l_b = CGPointMake(beforFrame.origin.x,beforFrame.size.height + beforFrame.origin.y);
                        r_t = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y);
                        r_b = CGPointMake(beforFrame.origin.x + beforFrame.size.width,beforFrame.origin.y + beforFrame.size.height);
                    }
                    
                    [animate setPointsLeftTop:l_t rightTop:r_t rightBottom:r_b leftBottom:l_b];
                }
                [animations addObjectsFromArray:@[animate]];
                obj.rectInVideo = (im == (item.count - 2) ? frame :beforFrame);
            }
            //obj.alpha = ((im == (item.count - 1)) ? 1.0 : (im+1)/(float)item.count*0.6);
            obj.animate = animations;
            [animations enumerateObjectsUsingBlock:^(VVAssetAnimatePosition *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSLog(@"idx:%d im:%d point:%@",idx,im, obj.pointsArray);
            }];
        }
    }
}

#endif

#pragma mark-Slice

#if 1

-(void)GetSliceEffect:(NSMutableArray *)scenes{
    
    if( videoResolvPowerType == VideoResolvPower_Portait  )
    {
        [self GetGrammyEffect:scenes];
        return;
    }
    
    
    float fleft = 0.498;
    float fright = 0.502;
    
    float startScale = 1.2;
    float EndScale = 1.0;
    
    NSInteger fCount = _fileList.count;
    NSMutableArray *lists = [NSMutableArray array];
    while (fCount > 6) {
        fCount -= 6;
        NSArray *itemlist = [_fileList subarrayWithRange:NSMakeRange(fCount, 6)];
        [lists addObject:itemlist];
    }
    
    NSArray *itemlist = [_fileList subarrayWithRange:NSMakeRange(0, fCount)];
    [lists addObject:itemlist];
    
    for (int k = 0; k<lists.count; k++) {
        m_CurrrentThemeEffect = Effect_Slice;
        
        float LeftStartTime = 0.0;
        float RightStartTime = 0.0;
        
        RDScene * scene = [[RDScene alloc] init];
        [scenes addObject:scene];
        
        NSArray *iList = lists[k];
        
        for (int i = 0; i < iList.count; i++) {
            int index = arc4random() % 3;
            int ImageEffect = Image_Effect_Enlarge;
            if(index == 2){
                ImageEffect = Image_Effect_BandW;
                index = arc4random() % 2;
            }
            else
                index = i%2;
            
            if(index == 0)
            {
                startScale = 1.1;
                EndScale = 1.0;
            }
            else if(index == 1){
                startScale = 1.0;
                EndScale = 1.1;
            }
            
            RDFile * tempFile = [iList[i] copy];
            CGSize size = [self getVVAssetSize:nil atFile:tempFile];
            
            [self setFileDuration:tempFile atDurationTIme:4];
            float time = [self getFileDuration:tempFile];
            float RightoffsetTime = m_EndTime = time/2.0;
            float LeftoffsetTime = time - m_EndTime;
            
            if( i == 0 )
            {
                //第一个多媒体 左边 全显示  右边 显示右边一半
                {
                    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                    animateInStart.type = AnimationInterpolationTypeLinear;
                    animateInEnd.type = AnimationInterpolationTypeLinear;
                    
                    VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                    vvasset.videoFillType = RDVideoFillTypeFull;
                    vvasset.fillType = RDImageFillTypeFull;
                    vvasset.startTimeInScene = CMTimeMakeWithSeconds( LeftStartTime , TIMESCALE);
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( LeftoffsetTime, TIMESCALE));
                    
                    animateInStart.atTime = 0;
                    [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                    animateInStart.fillScale = startScale;
                    animateInEnd.fillScale = EndScale;
                    CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                    float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*fleft));
                    CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
                    float oldWidth = ((m_videoSize.width*fleft)/m_videoSize.height)*currentsize.height;
                    if( oldWidth < currentsize.width  )
                    {
                        float offtset = oldWidth/currentsize.width;
                        crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                    }
                    else if(  oldWidth > currentsize.width   )
                    {
                        float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
                        float offtset = oldHeihgt/currentsize.height;
                        crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                    }
                    
                    animateInStart.crop = crop;
                    animateInStart.anchorPoint = CGPointMake(0.25, 0.5);
                    animateInEnd.anchorPoint = CGPointMake(0.25, 0.5);
                    animateInEnd.atTime = LeftoffsetTime;
                    animateInEnd.crop = crop;
                    [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                    vvasset.animate = @[animateInStart,animateInEnd];
                    vvasset.isBlurredBorder = NO;
                    [scene.vvAsset addObject:vvasset];//2
                    LeftStartTime += LeftoffsetTime;
                }
                {
                    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                    animateInStart.type = AnimationInterpolationTypeLinear;
                    animateInEnd.type = AnimationInterpolationTypeLinear;
                    VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                    vvasset.videoFillType = RDVideoFillTypeFull;
                    vvasset.startTimeInScene = CMTimeMakeWithSeconds( 0 , TIMESCALE);
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( RightoffsetTime+1.0, TIMESCALE));
                    animateInStart.atTime = 0;
                    
                    CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                    float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*fleft));
                    CGRect crop = CGRectMake( 0.5 ,MAX((1-off_setb), 0),  0.5,off_setb/2.0);
                    
                    if(currentsize.width>currentsize.height){
                        
                        float oldWidth = ((m_videoSize.width*fleft)/m_videoSize.height)*currentsize.height;
                        if( oldWidth < currentsize.width  )
                        {
                            float offtset = oldWidth/currentsize.width;
                            //                    crop = CGRectMake(offtset, 0, (1 - offtset) , 1);
                            //                }
                            //                else if(  oldWidth > currentsize.width   )
                            //                {
                            //                    float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
                            //                    float offtset = oldHeihgt/currentsize.height;
                            //                    crop = CGRectMake(0.5, (1-offtset), 0.5, offtset);
                            crop = CGRectMake((1-offtset), 0, offtset , 1);
                        }
                        else if(  oldWidth > currentsize.width   )
                        {
                            if( tempFile.fileType == kFILEVIDEO )
                            {
                                float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*(currentsize.width);
                                float offtset = oldHeihgt/currentsize.height;
                                crop = CGRectMake(fright, offtset/2.0, fleft, (1-offtset));
                            }
                            else{
                                crop = CGRectMake(fright, 0, fleft , 1);
                            }
                        }
                        
                    }
                    
                    
//                    UIImage *image = [RDHelpClass getFullScreenImageWithUrl:vvasset.url];
//                    CGRect bounds = CGRectMake(image.size.width * crop.origin.x,image.size.height * crop.origin.y,image.size.width * crop.size.width,image.size.height * crop.size.height);
//
//                    if (image.scale > 1.0f) {
//                        bounds = CGRectMake(bounds.origin.x * image.scale,
//                                            bounds.origin.y * image.scale,
//                                            bounds.size.width * image.scale,
//                                            bounds.size.height * image.scale);
//                    }

//                    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, bounds);
//                    UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
//                    CGImageRelease(imageRef);
                    
                    
                    animateInStart.fillScale = startScale;
                    animateInStart.crop = crop;//CGRectMake(0.5, 0, 0.5, 1);
                    animateInEnd.fillScale = EndScale;
                    animateInEnd.crop = crop;//CGRectMake(0.5, 0, 0.5, 1);
                    [animateInStart setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                    //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
                    animateInStart.anchorPoint = CGPointMake(0.75, 0.5);
                    animateInEnd.anchorPoint = CGPointMake(0.75, 0.5);
                    animateInEnd.atTime = RightoffsetTime+1.0;
                    [animateInEnd setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                    vvasset.animate = @[animateInStart,animateInEnd];
                    vvasset.isBlurredBorder = NO;
                    [scene.vvAsset addObject:vvasset];//3
                    RightStartTime += RightoffsetTime+1.0;
                }
            }
            else  if( i >= (iList.count - ((k == (lists.count-1)) ? 2 : 1)) ){
                
                float startTime = (LeftStartTime < RightStartTime )?LeftStartTime:RightStartTime;
                
                if( i == (iList.count-1) && (k == (lists.count-1)) )
                    m_CurrrentThemeEffect = Effect_Grammy;
                
                VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                vvasset.startTimeInScene = CMTimeMakeWithSeconds( startTime , TIMESCALE);
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( time, TIMESCALE));
                m_EndTime = 0.0;
                
                NSArray<VVAssetAnimatePosition*>*  animate1 = [self getImage_Effect:scene atvvasset:vvasset atThemeImage_EffectType:(index+1) atframe:CGRectMake(0, 0, 1, 1) atStartTime:0 atTime:time atstartScale:&startScale atendScale:&EndScale atfile:tempFile atIndex:i atIsEnd: (i == (iList.count-1) && k == (lists.count-1))?YES:NO atThemeIndex:Effect_Slice];
                m_EndTime = 2.0;
                if( tempFile.fileType == kFILEVIDEO )
                {
                    if( size.width <= size.height)
                    {
                        NSMutableArray *arr = [animate1 mutableCopy];
                        VVAsset * vvAsset1 = [self getVvasset:tempFile atThemeIndex:Effect_Slice];
                        vvAsset1.blurIntensity = 0.4;
                        vvAsset1.isBlurredBorder = ((k == (lists.count-1)) ? NO : YES);
                        vvAsset1.animate = [arr copy];
                        vvAsset1.startTimeInScene = CMTimeMakeWithSeconds( startTime , TIMESCALE);
                        vvAsset1.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( time, TIMESCALE));
                        [scene.vvAsset addObject:vvAsset1];
                        
                        
                        float off_setb =  size.width/size.height * (m_videoSize.height/(m_videoSize.width*0.8));
                        CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
                        if( size.width == size.height )
                            crop = CGRectMake(0,0,1,1);
                        [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            obj.crop = crop;
                        }];
                        vvasset.videoFillType = RDVideoFillTypeFit;
                    }else{
                        CGSize size = [self getVVAssetSize:nil atFile:tempFile];
                        float off = (size.width * (m_videoSize.height/m_videoSize.width))/size.height;
                        vvasset.crop = CGRectMake(0, (1- off)/2.0, 1, off);
                        vvasset.videoFillType = RDVideoFillTypeFit;
                        [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            obj.crop = vvasset.crop;
                        }];
                        
                    }
                }
                NSMutableArray *arr = [animate1 mutableCopy];
                vvasset.animate = [arr copy];
                
                [scene.vvAsset addObject:vvasset];
                LeftStartTime = startTime + time;
                RightStartTime = LeftStartTime;
            }
            else  if( size.width > size.height ){
                float  fincrement = (startScale-EndScale)/(RightoffsetTime+1.0);
                {
                    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                    animateInStart.type = AnimationInterpolationTypeLinear;
                    animateInEnd.type = AnimationInterpolationTypeLinear;
                    
                    VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                    vvasset.videoFillType = RDVideoFillTypeFit;
                    vvasset.startTimeInScene = CMTimeMakeWithSeconds( LeftStartTime , TIMESCALE);
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( LeftoffsetTime+1.0, TIMESCALE));
                    animateInStart.atTime = 0;
                    [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                    animateInStart.fillScale = startScale;
                    animateInEnd.fillScale = EndScale;
                    animateInStart.crop = CGRectMake(0, 0, 0.5, 1);
                    animateInStart.anchorPoint = CGPointMake(0.25, 0.5);
                    animateInEnd.anchorPoint = CGPointMake(0.25, 0.5);
                    animateInEnd.crop = CGRectMake(0, 0, 0.5, 1);
                    animateInEnd.atTime = LeftoffsetTime+1.0;
                    
                    if( ImageEffect == Image_Effect_BandW )
                    {
                        animateInStart.saturation = 0.0;
                        animateInEnd.saturation = 0.0;
                    }
                    [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                    vvasset.animate = @[animateInStart,animateInEnd];
                    [scene.vvAsset addObject:vvasset];
                    LeftStartTime += LeftoffsetTime+1.0;
                    NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
                }
                {
                    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                    animateInStart.type = AnimationInterpolationTypeLinear;
                    animateInEnd.type = AnimationInterpolationTypeLinear;
                    VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                    vvasset.videoFillType = RDVideoFillTypeFit;
                    vvasset.startTimeInScene = CMTimeMakeWithSeconds( RightStartTime , TIMESCALE);
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( RightoffsetTime + 1.0, TIMESCALE));
                    animateInStart.atTime = 0;
                    animateInStart.fillScale = startScale - fincrement;
                    animateInStart.crop = CGRectMake(0.5, 0, 0.5, 1);
                    animateInEnd.fillScale = EndScale;
                    animateInEnd.crop = CGRectMake(0.5, 0, 0.5, 1);
                    [animateInStart setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                    //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
                    animateInStart.anchorPoint = CGPointMake(0.75, 0.5);
                    animateInEnd.anchorPoint = CGPointMake(0.75, 0.5);
                    animateInEnd.atTime = RightoffsetTime+1.0;
                    [animateInEnd setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                    vvasset.animate = @[animateInStart,animateInEnd];
                    [scene.vvAsset addObject:vvasset];
                    RightStartTime += RightoffsetTime-1.0;
                    
                    NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
                }
                {
                    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                    animateInStart.type = AnimationInterpolationTypeLinear;
                    animateInEnd.type = AnimationInterpolationTypeLinear;
                    VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                    vvasset.startTimeInScene = CMTimeMakeWithSeconds( RightStartTime , TIMESCALE);
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( 1.0, TIMESCALE));
                    animateInStart.atTime = 0;
                    animateInStart.fillScale = EndScale + fincrement*2;
                    animateInEnd.fillScale = EndScale + fincrement;
                    [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(0, 1)];
                    //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
                    animateInStart.anchorPoint = CGPointMake(0.5, 0.5);
                    animateInEnd.anchorPoint = CGPointMake(0.5, 0.5);
                    animateInEnd.atTime = 1.0;
                    [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(0, 1)];
                    vvasset.animate = @[animateInStart,animateInEnd];
                    [scene.vvAsset addObject:vvasset];
                    RightStartTime += 2.0;
                    NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
                }
            }
            else
            {
                if( LeftStartTime < RightStartTime )
                {
                    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                    animateInStart.type = AnimationInterpolationTypeLinear;
                    animateInEnd.type = AnimationInterpolationTypeLinear;
                    VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                    vvasset.startTimeInScene = CMTimeMakeWithSeconds( LeftStartTime , TIMESCALE);
                    vvasset.videoFillType = RDVideoFillTypeFit;
                    vvasset.fillType = RDImageFillTypeFull;
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( LeftoffsetTime, TIMESCALE));
                    animateInStart.atTime = 0;
                    //if( tempFile.fileType == kFILEVIDEO  )
                    {
                        CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                        CGRect crop = CGRectMake( 0 ,0,  1,1);
                        float oldWidth = (m_videoSize.width*fleft/m_videoSize.height)*currentsize.height;
                        if( oldWidth < currentsize.width  )
                        {
                            float offtset = oldWidth/currentsize.width;
                            crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                        }
                        else if(  oldWidth > currentsize.width   )
                        {
                            float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
                            float offtset = oldHeihgt/currentsize.height;
                            crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                        }
                        animateInStart.crop = crop;
                        animateInEnd.crop = crop;
                    }
                    [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                    animateInStart.fillScale = startScale;
                    animateInEnd.fillScale = EndScale;
                    animateInStart.anchorPoint = CGPointMake(0.25, 0.5);
                    animateInEnd.anchorPoint = CGPointMake(0.25, 0.5);
                    animateInEnd.atTime = LeftoffsetTime;
                    if( ImageEffect == Image_Effect_BandW )
                    {
                        animateInStart.saturation = 0.0;
                        animateInEnd.saturation = 0.0;
                    }
                    [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                    vvasset.animate = @[animateInStart,animateInEnd];
                    vvasset.isBlurredBorder = NO;
                    [scene.vvAsset addObject:vvasset];//1
                    LeftStartTime += LeftoffsetTime;
                    NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
                }
                else
                {
                    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                    animateInStart.type = AnimationInterpolationTypeLinear;
                    animateInEnd.type = AnimationInterpolationTypeLinear;
                    VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                    vvasset.videoFillType = RDVideoFillTypeFit;
                    vvasset.fillType = RDImageFillTypeFull;
                    vvasset.startTimeInScene = CMTimeMakeWithSeconds( RightStartTime , TIMESCALE);
                    vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( RightoffsetTime, TIMESCALE));
                    animateInStart.atTime = 0;
                    animateInStart.fillScale = startScale;
                    animateInEnd.fillScale = EndScale;
                    
                    //if( tempFile.fileType == kFILEVIDEO  )
                    {
                        CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                        CGRect crop = CGRectMake( 0 ,0,  1,1);
                        float oldWidth = (m_videoSize.width*fleft/m_videoSize.height)*currentsize.height;
                        if( oldWidth < currentsize.width  )
                        {
                            float offtset = oldWidth/currentsize.width;
                            crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                        }
                        else if(  oldWidth > currentsize.width   )
                        {
                            float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
                            float offtset = oldHeihgt/currentsize.height;
                            crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                        }
                        
                        animateInStart.crop = crop;
                        animateInEnd.crop = crop;
                    }
                    
                    if( ImageEffect == Image_Effect_BandW )
                    {
                        animateInStart.saturation = 0.0;
                        animateInEnd.saturation = 0.0;
                    }
                    [animateInStart setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                    //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
                    animateInStart.anchorPoint = CGPointMake(0.75, 0.5);
                    animateInEnd.anchorPoint = CGPointMake(0.75, 0.5);
                    animateInEnd.atTime = RightoffsetTime;
                    [animateInEnd setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                    vvasset.animate = @[animateInStart,animateInEnd];
                    vvasset.isBlurredBorder = NO;
                    [scene.vvAsset addObject:vvasset];//1
                    RightStartTime += RightoffsetTime;
                    NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
                }
            }
        }//第二个for循环结束
        
    }//第一个for循环结束
    
    //    //结束闪黑
    //    {
    //        RDFile * tempFile = [_fileList[_fileList.count - 1] copy];
    //        tempFile.imageDurationTime = CMTimeMakeWithSeconds(  1 , TIMESCALE);
    //        RDScene * scene1 = [self FlashBlackHandle:tempFile atEffect:1];
    //        [scenes addObject:scene1];
    //    }
}

#else

-(void)GetSliceEffect:(NSMutableArray *)scenes{
    
    if( videoResolvPowerType == VideoResolvPower_Portait  )
    {
        [self GetGrammyEffect:scenes];
        return;
    }
    
    m_CurrrentThemeEffect = Effect_Slice;
    RDScene * scene = [[RDScene alloc] init];
    [scenes addObject:scene];
    float LeftStartTime = 0.0;
    float RightStartTime = 0.0;
    float fleft = 0.498;
    float fright = 0.502;
    
    float startScale = 1.2;
    float EndScale = 1.0;
    
    for (int i = 0; i < _fileList.count; i++) {
        int index = arc4random() % 3;
        int ImageEffect = Image_Effect_Enlarge;
        if(index == 2){
            ImageEffect = Image_Effect_BandW;
            index = arc4random() % 2;
        }
        else
            index = i%2;
        
        if(index == 0)
        {
            startScale = 1.1;
            EndScale = 1.0;
        }
        else if(index == 1){
            startScale = 1.0;
            EndScale = 1.1;
        }
        
        RDFile * tempFile = [_fileList[i] copy];
        CGSize size = [self getVVAssetSize:nil atFile:tempFile];
        
        [self setFileDuration:tempFile atDurationTIme:4];
        float time = [self getFileDuration:tempFile];
        float RightoffsetTime = m_EndTime = time/2.0;
        float LeftoffsetTime = time - m_EndTime;
    
        if( i == 0 )
        {
            //第一个多媒体 左边 全显示  右边 显示右边一半
            {
                VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                animateInStart.type = AnimationInterpolationTypeLinear;
                animateInEnd.type = AnimationInterpolationTypeLinear;
                
                VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                vvasset.videoFillType = RDVideoFillTypeFull;
                vvasset.fillType = RDImageFillTypeFull;
                vvasset.startTimeInScene = CMTimeMakeWithSeconds( LeftStartTime , TIMESCALE);
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( LeftoffsetTime, TIMESCALE));
                
                animateInStart.atTime = 0;
                [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                animateInStart.fillScale = startScale;
                animateInEnd.fillScale = EndScale;
                CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*fleft));
                CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
                float oldWidth = ((m_videoSize.width*fleft)/m_videoSize.height)*currentsize.height;
                if( oldWidth < currentsize.width  )
                {
                    float offtset = oldWidth/currentsize.width;
                    crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                }
                else if(  oldWidth > currentsize.width   )
                {
                    float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
                    float offtset = oldHeihgt/currentsize.height;
                    crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                }

                animateInStart.crop = crop;
                animateInStart.anchorPoint = CGPointMake(0.25, 0.5);
                animateInEnd.anchorPoint = CGPointMake(0.25, 0.5);
                animateInEnd.atTime = LeftoffsetTime;
                animateInEnd.crop = crop;
                [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
                vvasset.animate = @[animateInStart,animateInEnd];
                vvasset.isBlurredBorder = NO;
                [scene.vvAsset addObject:vvasset];
                LeftStartTime += LeftoffsetTime;
            }
            {
                VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                animateInStart.type = AnimationInterpolationTypeLinear;
                animateInEnd.type = AnimationInterpolationTypeLinear;
                VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
                vvasset.videoFillType = RDVideoFillTypeFull;
                vvasset.startTimeInScene = CMTimeMakeWithSeconds( 0 , TIMESCALE);
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( RightoffsetTime+1.0, TIMESCALE));
                animateInStart.atTime = 0;
                
                CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*fleft));
                CGRect crop = CGRectMake( 0.5 ,(1-off_setb),  0.5,off_setb/2.0);
                float oldWidth = ((m_videoSize.width*fleft)/m_videoSize.height)*currentsize.height;
                if( oldWidth < currentsize.width  )
                {
                    float offtset = oldWidth/currentsize.width;
//                    crop = CGRectMake(offtset, 0, (1 - offtset) , 1);
//                }
//                else if(  oldWidth > currentsize.width   )
//                {
//                    float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
//                    float offtset = oldHeihgt/currentsize.height;
//                    crop = CGRectMake(0.5, (1-offtset), 0.5, offtset);
                    crop = CGRectMake((1-offtset), 0, offtset , 1);
                }
                else if(  oldWidth > currentsize.width   )
                {
                    if( tempFile.fileType == kFILEVIDEO )
                    {
                        float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*(currentsize.width);
                        float offtset = oldHeihgt/currentsize.height;
                        crop = CGRectMake(fright, offtset/2.0, fleft, (1-offtset));
                    }
                    else{
                        crop = CGRectMake(fright, 0, fleft , 1);
                    }
                }
                
                animateInStart.fillScale = startScale;
                animateInStart.crop = crop;//CGRectMake(0.5, 0, 0.5, 1);
                animateInEnd.fillScale = EndScale;
                animateInEnd.crop = crop;//CGRectMake(0.5, 0, 0.5, 1);
                [animateInStart setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
                animateInStart.anchorPoint = CGPointMake(0.75, 0.5);
                animateInEnd.anchorPoint = CGPointMake(0.75, 0.5);
                animateInEnd.atTime = RightoffsetTime+1.0;
                [animateInEnd setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
                vvasset.animate = @[animateInStart,animateInEnd];
                vvasset.isBlurredBorder = NO;
                [scene.vvAsset addObject:vvasset];
                RightStartTime += RightoffsetTime+1.0;
            }
        }
        else  if( i >= (_fileList.count-2) ){

            float startTime = (LeftStartTime < RightStartTime )?LeftStartTime:RightStartTime;

            if( i == (_fileList.count-1)  )
                m_CurrrentThemeEffect = Effect_Grammy;

            VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
            vvasset.startTimeInScene = CMTimeMakeWithSeconds( startTime , TIMESCALE);
            vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( time, TIMESCALE));
            m_EndTime = 0.0;
            NSArray<VVAssetAnimatePosition*>*  animate1 = [self getImage_Effect:scene atvvasset:vvasset atThemeImage_EffectType:(index+1) atframe:CGRectMake(0, 0, 1, 1) atStartTime:0 atTime:time atstartScale:&startScale atendScale:&EndScale atfile:tempFile atIndex:i atIsEnd: (i == (_fileList.count-1))?YES:NO atThemeIndex:Effect_Slice];
            m_EndTime = 2.0;
            NSMutableArray *arr = [animate1 mutableCopy];
            vvasset.animate = [arr copy];
            if( tempFile.fileType == kFILEVIDEO )
            {
                if( size.width <= size.height )
                {
                    NSMutableArray *arr = [animate1 mutableCopy];
                    VVAsset * vvAsset1 = [self getVvasset:tempFile atThemeIndex:Effect_Slice];
                    vvAsset1.blurIntensity = 0.4;
                    vvAsset1.isBlurredBorder = NO;
                    vvAsset1.animate = [arr copy];
                    vvAsset1.startTimeInScene = CMTimeMakeWithSeconds( startTime , TIMESCALE);
                    vvAsset1.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( time, TIMESCALE));
                    [scene.vvAsset addObject:vvAsset1];
                    
                    
                    float off_setb =  size.width/size.height * (m_videoSize.height/(m_videoSize.width*0.8));
                    CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
                    if( size.width == size.height )
                        crop = CGRectMake(0,0,1,1);
                    [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        obj.crop = crop;
                    }];
                    vvasset.videoFillType = RDVideoFillTypeFit;
                }
            }
            [scene.vvAsset addObject:vvasset];
            LeftStartTime = startTime + time;
            RightStartTime = LeftStartTime;
        }
        else  if( size.width > size.height ){
           float  fincrement = (startScale-EndScale)/(RightoffsetTime+1.0);
           {
               VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
               VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                animateInStart.type = AnimationInterpolationTypeLinear;
                animateInEnd.type = AnimationInterpolationTypeLinear;

               VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
               vvasset.videoFillType = RDVideoFillTypeFit;
               vvasset.startTimeInScene = CMTimeMakeWithSeconds( LeftStartTime , TIMESCALE);
               vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( LeftoffsetTime+1.0, TIMESCALE));
               animateInStart.atTime = 0;
               [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
               animateInStart.fillScale = startScale;
               animateInEnd.fillScale = EndScale;
               animateInStart.crop = CGRectMake(0, 0, 0.5, 1);
               animateInStart.anchorPoint = CGPointMake(0.25, 0.5);
               animateInEnd.anchorPoint = CGPointMake(0.25, 0.5);
               animateInEnd.crop = CGRectMake(0, 0, 0.5, 1);
               animateInEnd.atTime = LeftoffsetTime+1.0;

               if( ImageEffect == Image_Effect_BandW )
               {
                   animateInStart.saturation = 0.0;
                   animateInEnd.saturation = 0.0;
               }
               [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
               vvasset.animate = @[animateInStart,animateInEnd];
               [scene.vvAsset addObject:vvasset];
               LeftStartTime += LeftoffsetTime+1.0;
               NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
           }
           {
               VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
               VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
               animateInStart.type = AnimationInterpolationTypeLinear;
               animateInEnd.type = AnimationInterpolationTypeLinear;
               VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
               vvasset.videoFillType = RDVideoFillTypeFit;
               vvasset.startTimeInScene = CMTimeMakeWithSeconds( RightStartTime , TIMESCALE);
               vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( RightoffsetTime + 1.0, TIMESCALE));
               animateInStart.atTime = 0;
               animateInStart.fillScale = startScale - fincrement;
               animateInStart.crop = CGRectMake(0.5, 0, 0.5, 1);
               animateInEnd.fillScale = EndScale;
               animateInEnd.crop = CGRectMake(0.5, 0, 0.5, 1);
               [animateInStart setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
               //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
               animateInStart.anchorPoint = CGPointMake(0.75, 0.5);
               animateInEnd.anchorPoint = CGPointMake(0.75, 0.5);
               animateInEnd.atTime = RightoffsetTime+1.0;
               [animateInEnd setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
               vvasset.animate = @[animateInStart,animateInEnd];
               [scene.vvAsset addObject:vvasset];
               RightStartTime += RightoffsetTime-1.0;
               
               NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
           }
           {
               VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
               VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
               animateInStart.type = AnimationInterpolationTypeLinear;
               animateInEnd.type = AnimationInterpolationTypeLinear;
               VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
               vvasset.startTimeInScene = CMTimeMakeWithSeconds( RightStartTime , TIMESCALE);
               vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( 1.0, TIMESCALE));
               animateInStart.atTime = 0;
               animateInStart.fillScale = EndScale + fincrement*2;
               animateInEnd.fillScale = EndScale + fincrement;
               [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(0, 1)];
               //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
               animateInStart.anchorPoint = CGPointMake(0.5, 0.5);
               animateInEnd.anchorPoint = CGPointMake(0.5, 0.5);
               animateInEnd.atTime = 1.0;
               [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(0, 1)];
               vvasset.animate = @[animateInStart,animateInEnd];
               [scene.vvAsset addObject:vvasset];
               RightStartTime += 2.0;
               NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
           }
       }
      else
      {
          if( LeftStartTime < RightStartTime )
          {
              VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
              VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
              animateInStart.type = AnimationInterpolationTypeLinear;
              animateInEnd.type = AnimationInterpolationTypeLinear;
              VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
              vvasset.startTimeInScene = CMTimeMakeWithSeconds( LeftStartTime , TIMESCALE);
              vvasset.videoFillType = RDVideoFillTypeFit;
              vvasset.fillType = RDImageFillTypeFull;
              vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( LeftoffsetTime, TIMESCALE));
              animateInStart.atTime = 0;
              //if( tempFile.fileType == kFILEVIDEO  )
              {
                  CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                  CGRect crop = CGRectMake( 0 ,0,  1,1);
                  float oldWidth = (m_videoSize.width*fleft/m_videoSize.height)*currentsize.height;
                  if( oldWidth < currentsize.width  )
                  {
                      float offtset = oldWidth/currentsize.width;
                      crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                  }
                  else if(  oldWidth > currentsize.width   )
                  {
                      float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
                      float offtset = oldHeihgt/currentsize.height;
                      crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                  }
                  animateInStart.crop = crop;
                  animateInEnd.crop = crop;
              }
              [animateInStart setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
              animateInStart.fillScale = startScale;
              animateInEnd.fillScale = EndScale;
              animateInStart.anchorPoint = CGPointMake(0.25, 0.5);
              animateInEnd.anchorPoint = CGPointMake(0.25, 0.5);
              animateInEnd.atTime = LeftoffsetTime;
              if( ImageEffect == Image_Effect_BandW )
              {
                  animateInStart.saturation = 0.0;
                  animateInEnd.saturation = 0.0;
              }
              [animateInEnd setPointsLeftTop:CGPointMake(0, 0) rightTop:CGPointMake(fleft, 0) rightBottom:CGPointMake(fleft, 1) leftBottom:CGPointMake(0, 1)];
              vvasset.animate = @[animateInStart,animateInEnd];
              vvasset.isBlurredBorder = NO;
              [scene.vvAsset addObject:vvasset];
              LeftStartTime += LeftoffsetTime;
              NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
          }
          else
          {
              VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
              VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
              animateInStart.type = AnimationInterpolationTypeLinear;
              animateInEnd.type = AnimationInterpolationTypeLinear;
              VVAsset * vvasset = [self getVvasset:tempFile atThemeIndex:4];
              vvasset.videoFillType = RDVideoFillTypeFit;
              vvasset.fillType = RDImageFillTypeFull;
              vvasset.startTimeInScene = CMTimeMakeWithSeconds( RightStartTime , TIMESCALE);
              vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( RightoffsetTime, TIMESCALE));
              animateInStart.atTime = 0;
              animateInStart.fillScale = startScale;
              animateInEnd.fillScale = EndScale;
              
              //if( tempFile.fileType == kFILEVIDEO  )
              {
                  CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                  CGRect crop = CGRectMake( 0 ,0,  1,1);
                  float oldWidth = (m_videoSize.width*fleft/m_videoSize.height)*currentsize.height;
                  if( oldWidth < currentsize.width  )
                  {
                      float offtset = oldWidth/currentsize.width;
                      crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                  }
                  else if(  oldWidth > currentsize.width   )
                  {
                      float oldHeihgt = (m_videoSize.height/(m_videoSize.width*fleft))*currentsize.width;
                      float offtset = oldHeihgt/currentsize.height;
                      crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                  }
              
                  animateInStart.crop = crop;
                  animateInEnd.crop = crop;
              }
              
              if( ImageEffect == Image_Effect_BandW )
              {
                  animateInStart.saturation = 0.0;
                  animateInEnd.saturation = 0.0;
              }
              [animateInStart setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
              //animateInStart.crop = CGRectMake((1 - 0.3)/2.0, (1 - 0.3)/2.0, 0.3, 0.3);
              animateInStart.anchorPoint = CGPointMake(0.75, 0.5);
              animateInEnd.anchorPoint = CGPointMake(0.75, 0.5);
              animateInEnd.atTime = RightoffsetTime;
              [animateInEnd setPointsLeftTop:CGPointMake(fright, 0) rightTop:CGPointMake(1, 0) rightBottom:CGPointMake(1, 1) leftBottom:CGPointMake(fright, 1)];
              vvasset.animate = @[animateInStart,animateInEnd];
              vvasset.isBlurredBorder = NO;
              [scene.vvAsset addObject:vvasset];
              RightStartTime += RightoffsetTime;
              NSLog(@"%d-->vvasset.startTimeInScene:%f",i,CMTimeGetSeconds(vvasset.startTimeInScene));
          }
      }
    }
//    //结束闪黑
//    {
//        RDFile * tempFile = [_fileList[_fileList.count - 1] copy];
//        tempFile.imageDurationTime = CMTimeMakeWithSeconds(  1 , TIMESCALE);
//        RDScene * scene1 = [self FlashBlackHandle:tempFile atEffect:1];
//        [scenes addObject:scene1];
//    }
}
#endif


#pragma mark Raw特效
- (void)GetRawEffect:(NSMutableArray *)scenes{
    m_EndTime = 1.0;
    m_CurrrentThemeEffect = Effect_Raw;
    for (int i = 0; i < _fileList.count; i++) {
        
        RDFile * tempFile = [_fileList[i] copy];
        [self setFileDuration:tempFile atDurationTIme:4.0];
        RDScene * scene;
        
        scene  = [self getScene_Effect:tempFile atIndex:i atEffect:Image_Effect_Narrow atEndingSpecialEffect:Effect_Raw atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        if(i == _fileList.count - 1){
            scene.transition.type = RDVideoTransitionTypeBlinkBlack;
            scene.transition.duration = 1.0;
        }
        [scenes addObject:scene];
    }
    
    //结束淡入
    {
        RDFile * tempFile = [_fileList[_fileList.count - 1] copy];
        [self setFileDuration:tempFile atDurationTIme:m_EndTime];
        RDScene * scene = [self FlashBlackHandle:tempFile atEffect:2];
        [scenes addObject:scene];
    }
}
#pragma mark-Sunny

- (void)GetSunnyEffect:(NSMutableArray *)scenes{
    m_EndTime = 1.0;
    m_CurrrentThemeEffect = Effect_Sunny;
    for (int i = 0; i < _fileList.count; i++) {
        
        RDFile * tempFile = [_fileList[i] copy];
        [self setFileDuration:tempFile atDurationTIme:4.0];
        RDScene * scene;
        
        scene  = [self getScene_Effect:tempFile atIndex:i atEffect:Image_Effect_Narrow atEndingSpecialEffect:Effect_Sunny atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];

//        scene.transition.maskURL = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/zhuanchang/transition/transition7.jpg"] Type:@""]];
        scene.transition.duration = 1.5;
        if(i<_fileList.count-1){
            
            RDFile * tempFile1 = [_fileList[i+1] copy];
            float dura = CMTimeGetSeconds(tempFile.imageDurationTime);
            float dura1 = CMTimeGetSeconds(tempFile1.imageDurationTime);
            if(tempFile.fileType == kFILEVIDEO){
                dura = CMTimeGetSeconds(tempFile.videoDurationTime);
            }
            if(tempFile1.fileType == kFILEVIDEO){
                dura1 = CMTimeGetSeconds(tempFile1.videoDurationTime);
            }
            
            scene.transition.duration = MIN(MIN(dura1/2.0, dura/2.0), 1.5);
            NSLog(@"transition.duration:%f",scene.transition.duration);
        }
        int idx = 0;
        NSString *key = [NSString stringWithFormat:@"%zd-%d",Effect_Sunny,i];
        if([[m_SunnyEffects allKeys] containsObject:key]){
            idx = [m_SunnyEffects[key] intValue];
        }else{
            idx = arc4random()%60;
            int number = 0;
            NSInteger item = idx%7 - 3;
            NSString *name = ((RDScene *)[scenes lastObject]).transition.maskURL.absoluteString.lastPathComponent;
            NSScanner *scanner = [NSScanner scannerWithString:name];
            [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
            [scanner scanInt:&number];
            while (number == item) {
                idx = arc4random()%60;
                item = idx%7 - 3;
            }
            [m_SunnyEffects setObject:[NSNumber numberWithInt:idx] forKey:key];
        }
        
        if(idx%7 == 0){
            scene.transition.type = RDVideoTransitionTypeFade;
        }else if(idx%7 == 1){
            scene.transition.type = RDVideoTransitionTypeBlinkWhite;
        }else if(idx%7 == 2){
            scene.transition.type = RDVideoTransitionTypeGrid;
        }else {

            if(i == (_fileList.count-1)){
                scene.transition.maskURL = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"transitions/transition_quick/%@%d.jpg",m_videoSize.width>m_videoSize.height ? @"l_transition" : @"transition",6] Type:@""]];
            }else{
                scene.transition.maskURL = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"transitions/transition_quick/%@%d.jpg",m_videoSize.width>m_videoSize.height ? @"l_transition" : @"transition",(idx%7 - 3)] Type:@""]];
                
            }
        }
        //file_%d
        [scenes addObject:scene];
    }
    
    
    //结束白色关闭动画
    {
        VVAsset * vvassetWhite = [[VVAsset alloc] init];
        vvassetWhite.url = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"whiteBlack" Type:@"png"]];
        vvassetWhite.type         = RDAssetTypeImage;
        vvassetWhite.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(2, 600));
        vvassetWhite.speed        = 1;
        vvassetWhite.fillType     = RDImageFillTypeFit;
        vvassetWhite.rotate = 0;
        vvassetWhite.isVerticalMirror = NO;
        vvassetWhite.isHorizontalMirror = NO;
        RDScene *scene1 = [[RDScene alloc] init];
        if(m_videoSize.width>m_videoSize.height){
            vvassetWhite.crop = CGRectMake(0, 0, 1, 9/16.0);
        }
        [scene1.vvAsset addObject:vvassetWhite];
        
        [scenes addObject:scene1];
    }

    
}

#pragma mark-Jolly
-(void)GetJolly:(NSMutableArray *) scenes{
    m_CurrrentThemeEffect = Effect_Jolly;
    [self GetActionEffect:scenes];
}
#pragma mark-Snappy
-(void)GetSnappyEffect:(NSMutableArray *) scenes{
    m_CurrrentThemeEffect = Effect_Snappy;
    for (int i = 0; i < _fileList.count; i++) {
        
        RDFile * tempFile = [_fileList[i] copy];
        [self setFileDuration:tempFile atDurationTIme:(tempFile.fileType == RDAssetTypeImage ? 1.0 : MIN(5, CMTimeGetSeconds(tempFile.videoDurationTime)))];//CMTimeGetSeconds(tempFile.videoDurationTime)
        RDScene * scene;
        
        scene  = [self getScene_Effect:tempFile atIndex:i atEffect:Image_Effect_Narrow atEndingSpecialEffect:Effect_Snappy atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        [scenes addObject:scene];
    }
    for (int i = (int)(_fileList.count - 2); i >=0; i--) {
        
        RDFile * tempFile = [_fileList[i] copy];
        [self setFileDuration:tempFile atDurationTIme:0.3];
        RDScene * scene  = [self getScene_Effect:tempFile atIndex:i + (int)_fileList.count atEffect:Image_Effect_Narrow atEndingSpecialEffect:Effect_Snappy atIsLast: (i == (_fileList.count-1))?YES:NO scenes:scenes];
        [scenes addObject:scene];
    }
}
#pragma mark-Over
-(void)GetOverEffect:(NSMutableArray *) scenes{
    
    [self GetSerene1:scenes];
}

#pragma mark-结尾转场特效处理
-(RDScene *) FlashBlackHandle:(RDFile *) file
                     atEffect:(Effect) EffectIndex
{
    RDScene * scene = [[RDScene alloc] init];
//    VVAsset * vvasset = [self getVvasset:file atThemeIndex:EffectIndex];
//    vvasset.fillType = RDImageFillTypeAspectFill;
//    float time = [self getFileDuration:file];
    
    //Boxed if( EffectIndex == Effect_Boxed )
    {
       
        VVAsset* vvassetWhite = [[VVAsset alloc] init];
        vvassetWhite.type = RDAssetTypeVideo;
        vvassetWhite.videoFillType = RDVideoFillTypeFull;
        vvassetWhite.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(m_EndTime, 600));
        vvassetWhite.speed        = 1;
        vvassetWhite.volume       = 0;
        vvassetWhite.rotate       = 0;
        vvassetWhite.isVerticalMirror = NO;
        vvassetWhite.isHorizontalMirror = NO;
        vvassetWhite.crop = CGRectMake(0, 0, 1, 1);
        vvassetWhite.url =  [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"27_b" Type:@"mp4"]];
        vvassetWhite.startTimeInScene = kCMTimeZero;
        [scene.vvAsset addObject:vvassetWhite];
    }
    
    
//    vvasset.startTimeInScene = kCMTimeZero;
    
    //设置Boxed背景图
//    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
//    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
//    animateInStart.atTime = 0;
//
//    CGRect frame = CGRectMake(0, 0, 1,1);
//    if( EffectIndex == Effect_Boxed )
//        frame = CGRectMake(0.125, 0.125, 0.75, 0.75);
//
//    animateInStart.rect = frame;
//    animateInEnd.atTime = time;
//    animateInEnd.rect = frame;
    
//    vvasset.animate = [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
//    [scene.vvAsset addObject:vvasset];
    return scene;
}
#pragma mark-图片转换
-(UIImage *)cropSquareImage:(UIImage *)image rect:(CGRect)rect{
    
    CGImageRef sourceImageRef = [image CGImage];//将UIImage转换成CGImageRef
    
    CGFloat _imageWidth = image.size.width;// * image.scale;
    CGFloat _imageHeight = image.size.height;// * image.scale;
    
    CGRect r = CGRectMake(rect.origin.x *_imageWidth, rect.origin.y * _imageHeight, _imageWidth*rect.size.width, _imageHeight*rect.size.height);
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, r);//按照给定的矩形区域进行剪裁
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    if (newImageRef) {
        CGImageRelease(newImageRef);
    }
    
    return newImage;
}
#pragma mark-获取图片视频文件的播放时长
- (float)getFileDuration:(RDFile *)file{
    if(file.fileType == kFILEVIDEO){
        CMTimeRange timeRange = kCMTimeRangeZero;
        if(file.isReverse){
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
            }else{
                timeRange = file.reverseVideoTimeRange;
            }
            if(CMTimeCompare(timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                timeRange = file.reverseVideoTrimTimeRange;
            }
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
            }else{
                timeRange = file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                timeRange = file.videoTrimTimeRange;
            }
        }
        return CMTimeGetSeconds(timeRange.duration);
    }else
        return CMTimeGetSeconds(file.imageDurationTime);
}
#pragma mark-设置图片视频文件播放时长
- (void)setFileDuration:(RDFile *)file
         atDurationTIme:(float) Duration
{
    if(file.fileType == kFILEVIDEO)
    {
        CMTimeRange timeRange = kCMTimeRangeZero;
        if(file.isReverse){
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                 file.reverseDurationTime =  CMTimeMakeWithSeconds( Duration , TIMESCALE);
            }else{
                file.reverseVideoTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( Duration , TIMESCALE));
            }
            if(CMTimeCompare(timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                file.reverseVideoTrimTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( Duration , TIMESCALE));;
            }
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
               CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
            }else{
                file.videoTimeRange  = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( Duration , TIMESCALE));;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                file.videoTrimTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( Duration , TIMESCALE));;
            }
        }
    }
    else if( file.fileType == kFILEIMAGE )
        file.imageDurationTime = CMTimeMakeWithSeconds(  Duration , TIMESCALE);
}
#pragma mark-获取多媒体的分辨率
-(CGSize) getVVAssetSize:(VVAsset *) vvasset
                  atFile:(RDFile *) file
{
    CGSize size;
    if( file )
    {
        if( file.fileType == kFILEVIDEO )
        {
            AVURLAsset *asset;
            asset = [AVURLAsset assetWithURL:file.contentURL];
            size = [RDHelpClass getVideoSizeForTrack:asset];
        }
        else
            size = [RDHelpClass getFullScreenImageWithUrl:file.contentURL].size;
    }
    else
    {
        if(vvasset.type == RDAssetTypeVideo)
        {
            AVURLAsset *asset;
            asset = [AVURLAsset assetWithURL:vvasset.url];
            size = [RDHelpClass getVideoSizeForTrack:asset];
        }
        else
            size = [RDHelpClass getFullScreenImageWithUrl:vvasset.url].size;
    }
    return size;
}

#pragma mark-获取场景
- (RDScene *)getScene_Effect:(RDFile *) file
                     atIndex:(int) index
                    atEffect:(ThemeImage_EffectType) EffectType
       atEndingSpecialEffect:(Effect) EffectIndex
                    atIsLast:(bool) IsLast
                    scenes:(NSMutableArray *)scenes
{
    m_Islast = IsLast;
    m_CurrrentRotate = 0;
    __block BOOL lastEndAnimationRotate = NO;
    __block BOOL LASTEndAnmiationBlur = NO;
    [((RDScene *)[scenes lastObject]).vvAsset enumerateObjectsUsingBlock:^(VVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.animate lastObject].rotate !=0){
            lastEndAnimationRotate = YES;
        }
        if( [obj.animate lastObject].blur != nil )
        {
            LASTEndAnmiationBlur = YES;
        }
    }];
    RDScene * scene = [[RDScene alloc] init];
    
    float time = [self getFileDuration:file];
    
    RDFile * tempFile = [file copy];
    //结尾特效
    ThemeImage_EffectType endImageEffectCurrent;
    int cindex = 0;
    
    VVAsset * vvassetWhite = nil;
    
    
    if( EffectIndex == Effect_Snappy)
    {
        
        
        CGSize size = [self getVVAssetSize:nil atFile:file];
        float scale1 = 0.8;
        float off_set = (1 - m_videoSize.height * size.width/size.height/m_videoSize.width * scale1)/2.0;
        CGRect frame = CGRectMake(off_set, (1 - scale1)/2.0, 1-off_set*2.0, scale1);
        
        
        
        float off_setb =  size.width/size.height * (m_videoSize.height/(m_videoSize.width));
        CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
        if(size.height/size.width<m_videoSize.height/m_videoSize.width){
            off_set = (1 - m_videoSize.width * size.height/size.width/m_videoSize.height * scale1)/2.0;
            frame = CGRectMake((1 - scale1)/2.0,off_set, scale1, 1-off_set*2.0);
            
            off_setb =  size.width/size.height * (m_videoSize.width/(m_videoSize.height));
            crop = CGRectMake((1-off_setb)/2.0, 0,off_setb,1);
        }
        
        float w = 10/m_videoSize.width;
        float h = 10/m_videoSize.height;

        CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
        if( file.fileType == kFILEVIDEO  )
        {
            //CGRect crop = CGRectMake(0, 0, 1, 1);
            float oldWidth = (m_videoSize.width/m_videoSize.height)*currentsize.height;
            if( oldWidth < currentsize.width  )
            {
                float offtset = oldWidth/currentsize.width;
                crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
            }
            else if(  oldWidth > currentsize.width   )
            {
                float oldHeihgt = (m_videoSize.height/m_videoSize.width)*currentsize.width;
                float offtset = oldHeihgt/currentsize.height;
                crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
            }
        }
        
        VVAsset * blackvvasset = [self getVvasset:file atThemeIndex:EffectIndex];
        blackvvasset.fillType = RDImageFillTypeAspectFill;
        blackvvasset.videoFillType = RDVideoFillTypeFull;
        blackvvasset.alpha = 0.4;
        blackvvasset.crop = crop;
        [scene.vvAsset addObject:blackvvasset];
        
        vvassetWhite = [[VVAsset alloc] init];
        vvassetWhite.url = [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"whiteBlack" Type:@"png"]];
        vvassetWhite.type         = RDAssetTypeImage;
        vvassetWhite.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( [self getFileDuration:file]  , TIMESCALE));
        vvassetWhite.speed        = file.speed;
        vvassetWhite.rotate = file.rotate;
        vvassetWhite.isVerticalMirror = file.isVerticalMirror;
        vvassetWhite.isHorizontalMirror = file.isHorizontalMirror;
        vvassetWhite.fillType = RDImageFillTypeFull;
        
        {
            
            VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
            animateInStart.rect = CGRectMake(0, 0, 1, 1);
            animateInEnd.rect = CGRectMake(0, 0, 1, 1);
            animateInStart.atTime = 0;
            animateInEnd.atTime = CMTimeGetSeconds(vvassetWhite.timeRange.duration);
            
            {
                [animateInStart setPointsLeftTop:CGPointMake(frame.origin.x - w                         , frame.origin.y - h)
                                        rightTop:CGPointMake(frame.origin.x + CGRectGetWidth(frame) + w , frame.origin.y - h)
                                     rightBottom:CGPointMake(frame.origin.x + CGRectGetWidth(frame) + w , frame.origin.y + CGRectGetHeight(frame) + h)
                                      leftBottom:CGPointMake(frame.origin.x - w                         , frame.origin.y + CGRectGetHeight(frame) + h)];
                
                [animateInEnd setPointsLeftTop:CGPointMake(frame.origin.x - w                         , frame.origin.y - h)
                                      rightTop:CGPointMake(frame.origin.x + CGRectGetWidth(frame) + w , frame.origin.y - h)
                                   rightBottom:CGPointMake(frame.origin.x + CGRectGetWidth(frame) + w , frame.origin.y + CGRectGetHeight(frame) + h)
                                    leftBottom:CGPointMake(frame.origin.x - w                         , frame.origin.y + CGRectGetHeight(frame) + h)];
                
            }
            
            vvassetWhite.animate = @[animateInStart,animateInEnd];
        }
        
        [scene.vvAsset addObject:vvassetWhite];
        
        
        VVAsset * vvasset = [self getVvasset:file atThemeIndex:EffectIndex];
        vvasset.isBlurredBorder = NO;
        vvasset.videoFillType = RDVideoFillTypeFull;
        vvasset.fillType = RDImageFillTypeFull;
        
        {
            
            if(lastEndAnimationRotate){
                NSMutableArray *vanimations = [[NSMutableArray alloc] init];
                
                VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                animateInStart.atTime = m_EndTime;
                animateInEnd.atTime = [self getFileDuration:file];
                [animateInStart setPointsLeftTop:CGPointMake(frame.origin.x                         , frame.origin.y)
                                        rightTop:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y)
                                     rightBottom:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y + CGRectGetHeight(frame))
                                      leftBottom:CGPointMake(frame.origin.x                         , frame.origin.y + CGRectGetHeight(frame))];
                
                [animateInEnd setPointsLeftTop:CGPointMake(frame.origin.x                         , frame.origin.y)
                                      rightTop:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y)
                                   rightBottom:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y + CGRectGetHeight(frame))
                                    leftBottom:CGPointMake(frame.origin.x                         , frame.origin.y + CGRectGetHeight(frame))];
                    
                
                
                VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
                VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
                
                animateInStart1.atTime = 0;
                animateInEnd1.atTime = m_EndTime;
                animateInStart1.rotate = -15;
                animateInEnd1.rotate = 0;
                [vanimations addObjectsFromArray:@[animateInStart,animateInEnd]];
                [vanimations addObjectsFromArray:@[animateInStart1,animateInEnd1]];
                vvasset.animate = [vanimations mutableCopy];
                
            }else{
                VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
                VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
                
                animateInStart.atTime = 0;
                animateInEnd.atTime = [self getFileDuration:file];;
                [animateInStart setPointsLeftTop:CGPointMake(frame.origin.x                         , frame.origin.y)
                                        rightTop:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y)
                                     rightBottom:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y + CGRectGetHeight(frame))
                                      leftBottom:CGPointMake(frame.origin.x                         , frame.origin.y + CGRectGetHeight(frame))];
                
                [animateInEnd setPointsLeftTop:CGPointMake(frame.origin.x                         , frame.origin.y)
                                      rightTop:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y)
                                   rightBottom:CGPointMake(frame.origin.x + CGRectGetWidth(frame) , frame.origin.y + CGRectGetHeight(frame))
                                    leftBottom:CGPointMake(frame.origin.x                         , frame.origin.y + CGRectGetHeight(frame))];
                    
                vvasset.animate = @[animateInStart,animateInEnd];
            }
            
        }
        [scene.vvAsset addObject:vvasset];
        return scene;
    }
    
    NSArray<VVAssetAnimatePosition*>* animate1;
    NSArray<VVAssetAnimatePosition*>* animate2;
    
    //Boxed
    if( EffectIndex == Effect_Boxed )
    {
        vvassetWhite = [[VVAsset alloc] init];
        vvassetWhite.type = RDAssetTypeImage;
        vvassetWhite.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(   [self getFileDuration:file] , TIMESCALE));
        vvassetWhite.speed        = file.speed;
        vvassetWhite.fillType     = RDImageFillTypeFit;
        
        vvassetWhite.fillType = RDImageFillTypeFull;
        vvassetWhite.startTimeInScene = kCMTimeZero;
        
        //设置Boxed背景图
        VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
        VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
        animateInStart.atTime = 0;
        
        CGRect frame = CGRectMake(0, 0, 1, 1);
        animateInStart.rect = frame;
        animateInEnd.atTime = time;
        animateInEnd.rect = frame;
        
        vvassetWhite.url =  [NSURL fileURLWithPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/Quik/Boxed背景图" Type:@"jpg"]];
        vvassetWhite.animate = [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        vvassetWhite.startTimeInScene = kCMTimeZero;
        [scene.vvAsset addObject:vvassetWhite];
    }
    
    VVAsset * vvasset = [self getVvasset:file atThemeIndex:EffectIndex];
    VVAsset * vvasset1 = nil;
  
    
    if( EffectIndex == Effect_Sunny)
    {
        [scene.vvAsset addObject:vvasset];
        scene.transition.type = RDVideoTransitionTypeMask;
        scene.transition.duration = 1.3;
        
    }
    if( EffectIndex == Effect_Raw )
    {
        vvasset.rectInVideo = CGRectMake(0.125, 0.125, 0.75, 0.75);
        vvasset.fillType = RDImageFillTypeFit;
        vvasset.videoFillType = RDVideoFillTypeFit;
        vvasset.isBlurredBorder = NO;
        VVAsset * vvassetBlack = [self getVvasset:file atThemeIndex:EffectIndex];
        vvassetBlack.fillType = RDImageFillTypeAspectFill;
        vvassetBlack.isBlurredBorder = NO;
        vvassetBlack.brightness = 0.1;
        vvassetBlack.alpha = 0.4;
        vvassetBlack.contrast = 1.0;
        //设置Boxed背景图
        VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
        VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
        animateInStart1.atTime = 0;
        
        
        animateInStart1.fillScale = 1.4;
        animateInEnd1.atTime = time;
        animateInEnd1.fillScale = 1.0;
        
        CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
        if( file.fileType == kFILEVIDEO  )
        {
            CGRect crop = CGRectMake(0, 0, 1, 1);
            float oldWidth = (m_videoSize.width/m_videoSize.height)*currentsize.height;
            if( oldWidth < currentsize.width  )
            {
                float offtset = oldWidth/currentsize.width;
                crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
            }
            else if(  oldWidth > currentsize.width   )
            {
                float oldHeihgt = (m_videoSize.height/m_videoSize.width)*currentsize.width;
                float offtset = oldHeihgt/currentsize.height;
                crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
            }
            animateInStart1.crop = crop;
            animateInEnd1.crop = crop;
        }
        
        vvassetBlack.animate = [NSMutableArray arrayWithObjects:animateInStart1,animateInEnd1, nil];
        [scene.vvAsset addObject:vvassetBlack];
        
        [self setFileDuration:file atDurationTIme:time];
        
        VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
        VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
        animateInStart.atTime = 0;
        animateInStart.fillScale = 0.9;
        animateInEnd.atTime = time;
        animateInEnd.fillScale = 0.8;
        vvasset.animate = [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        vvasset.startTimeInScene = kCMTimeZero;
        
        [scene.vvAsset addObject:vvasset];
        return scene;
    }
    
    CGRect frame;
    if( EffectIndex == Effect_Boxed){
        frame = CGRectMake(0.125, 0.125, 0.75, 0.75);
        vvasset.isBlurredBorder = NO;
    }
    else
        frame = CGRectMake(0., 0, 1, 1);
    float startScale = 1.0;
    float endScale  = 1.0;

    if( (!IsLast) && (EffectIndex == Effect_Epic) )
    {
        animate1 = [self getImage_Effect:scene atvvasset:vvasset atThemeImage_EffectType:EffectType atframe:frame atStartTime: 0 atTime:time atstartScale:&startScale atendScale:&endScale atfile:file atIndex:index atIsEnd:NO atThemeIndex:EffectIndex];

        if( ( file.fileType == kFILEVIDEO ) && ( videoResolvPowerType != VideoResolvPower_Portait ) )
        {
            CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
            if( currentsize.width <= currentsize.height )
            {
                NSMutableArray *arr = [animate1 mutableCopy];
                [arr addObjectsFromArray:animate2];
                VVAsset * vvAsset1 = [self getVvasset:file atThemeIndex:EffectIndex];
                vvAsset1.blurIntensity = 0.4;
                vvAsset1.startTimeInScene = kCMTimeZero;
                vvAsset1.isBlurredBorder = NO;
                vvAsset1.animate = [arr copy];
                [scene.vvAsset addObject:vvAsset1];
                
                
                float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*0.8));
                CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
                if( currentsize.width == currentsize.height )
                    crop = CGRectMake(0,0,1,1);
                [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.crop = crop;
                }];
                [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.crop = crop;
                }];
                vvasset.videoFillType = RDVideoFillTypeFit;
            }else{
                float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*0.8));
                CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
                if( currentsize.width/currentsize.height < (m_videoSize.height/(m_videoSize.width*0.8)))
                    crop = CGRectMake(0,0,1,1);
                [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.crop = crop;
                }];
                [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.crop = crop;
                }];
                vvasset.videoFillType = RDVideoFillTypeFit;
            }
            
            NSMutableArray *arr = [animate1 mutableCopy];
            vvasset.videoFillType = RDVideoFillTypeFit;
            vvasset.animate = [arr copy];
            vvasset.startTimeInScene = kCMTimeZero;
            scene.transition.type     = RDVideoTransitionTypeFade;
            scene.transition.duration = m_EndTime;
            [scene.vvAsset addObject:vvasset];
        }
        else {
            if( file.fileType == kFILEVIDEO  )
            {
                CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                CGRect crop = CGRectMake(0, 0, 1, 1);
                float oldWidth = (m_videoSize.width/m_videoSize.height)*currentsize.height;
                if( oldWidth < currentsize.width  )
                {
                    float offtset = oldWidth/currentsize.width;
                    crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                }
                else if(  oldWidth > currentsize.width   )
                {
                    float oldHeihgt = (m_videoSize.height/m_videoSize.width)*currentsize.width;
                    float offtset = oldHeihgt/currentsize.height;
                    crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                }
                [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.crop = crop;
                }];
            }
            
            NSMutableArray *arr = [animate1 mutableCopy];
            vvasset.isBlurredBorder = NO;
            vvasset.animate = [arr copy];
            vvasset.startTimeInScene = kCMTimeZero;
            scene.transition.type     = RDVideoTransitionTypeFade;
            scene.transition.duration = m_EndTime;
            [scene.vvAsset addObject:vvasset];
        }
        return scene;
    }
    
//    if (!IsLast) {
//        file.imageDurationTime = CMTimeMakeWithSeconds( (time > m_EndTime)? (time - m_EndTime): (time/2) , TIMESCALE);
//
//    }
    
    //Lapse
    if( ( EffectIndex == Effect_Lapse ) && ( IsLast ) )
    {
        m_EndTime = 2;
        m_CurrrentThemeEffect = Effect_Lapse;
        cindex = Image_Effect_Enlarge;
        time = time+m_EndTime;
        vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( time , TIMESCALE));
        
        animate1 = [self getImage_Effect:scene atvvasset:vvasset  atThemeImage_EffectType:cindex atframe:frame atStartTime: 0 atTime:time-m_EndTime atstartScale:&startScale atendScale:&endScale atfile:tempFile atIndex:index atIsEnd:NO atThemeIndex:Effect_Lapse];
        
        animate2 = [self getImage_Effect:scene atvvasset:vvasset  atThemeImage_EffectType:cindex atframe:frame atStartTime: time-m_EndTime atTime:m_EndTime atstartScale:&startScale atendScale:&endScale atfile:tempFile atIndex:index atIsEnd:YES atThemeIndex:Effect_Lapse];
        
        if( file.fileType == kFILEVIDEO )
        {
            CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
            CGRect crop = CGRectMake(0, 0, 1, 1);
            float oldWidth = (m_videoSize.width/m_videoSize.height)*currentsize.height;
            if( oldWidth < currentsize.width  )
            {
                float offtset = oldWidth/currentsize.width;
                crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
            }
            else if(  oldWidth > currentsize.width   )
            {
                float oldHeihgt = (m_videoSize.height/m_videoSize.width)*currentsize.width;
                float offtset = oldHeihgt/currentsize.height;
                crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
            }
            [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.crop = crop;
            }];
            [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.crop = crop;
            }];
        }
        
//        scene.transition.type     = RDVideoTransitionTypeFade;
//        scene.transition.duration = m_EndTime;
        [animate1 lastObject].atTime = time-m_EndTime;
        
        NSMutableArray *arr = [animate1 mutableCopy];
        [arr addObjectsFromArray:animate2];
        
        vvasset.animate = [arr copy];
        vvasset.startTimeInScene = kCMTimeZero;
        [scene.vvAsset addObject:vvasset];
        
        return scene;
    }
    
    if( ( ( EffectIndex == Effect_Grammy )
         || ( EffectIndex == Effect_Action)
         || ( EffectIndex == Effect_Boxed)
         || ( EffectIndex == Effect_Epic))
       && ( IsLast ) )
    {
        m_EndTime = 0.0;
        if( Effect_Boxed == EffectIndex )
            m_EndTime = 1.0;
    }
    
    if( EffectType !=  Image_Effect_Default)
        animate1 = [self getImage_Effect:scene atvvasset:vvasset atThemeImage_EffectType:EffectType atframe:frame atStartTime: lastEndAnimationRotate  ? m_EndTime : 0 atTime:time atstartScale:&startScale atendScale:&endScale atfile:file atIndex:index atIsEnd:NO atThemeIndex:EffectIndex];
    else
    {
        //无任何动作 为默认展示图片
        //file.imageDurationTime = CMTimeMakeWithSeconds( time , TIMESCALE);
         animate1 = [self getImage_Effect:scene atvvasset:vvasset atThemeImage_EffectType:EffectType atframe:frame atStartTime: lastEndAnimationRotate  ? m_EndTime : 0 atTime:time atstartScale:&startScale atendScale:&endScale atfile:file atIndex:index atIsEnd:NO atThemeIndex:EffectIndex];
        startScale = 1.0;
        endScale = 1.0;
    }
    
    if( EffectIndex == Effect_Boxed){
        vvasset.fillType = RDImageFillTypeFit;//RDImageFillTypeAspectFill
        vvasset.videoFillType = RDVideoFillTypeFit;
        float scale_va = 0.75;
        CGSize currentsize = [self getVVAssetSize:nil atFile:file];
        float off_set = 0;
        if(currentsize.height/currentsize.width >= m_videoSize.height/m_videoSize.width){
            scale_va = 0.75;
            off_set = MAX(0.125, (1 - m_videoSize.height * currentsize.width/currentsize.height/m_videoSize.width * scale_va)/2.0);
            frame = CGRectMake(off_set, (1 - scale_va)/2.0, 1-off_set*2.0, scale_va);
        }else{
            scale_va = 0.8;
            off_set = MAX(0.1, (1 - m_videoSize.width * currentsize.height/currentsize.width/m_videoSize.height * scale_va)/2.0);
            frame = CGRectMake((1 - scale_va)/2.0, off_set, scale_va, 1-off_set*2.0);
        }
        NSMutableArray *vanimations;
        VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
        VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
        
        animateInStart.atTime = 0;
        animateInStart.fillScale = 1.3;
        animateInStart.rect = frame;
        animateInStart.crop = CGRectMake(0, 0, 1, 1);
        
        animateInEnd.atTime = time - (m_EndTime+0.2);
        animateInEnd.fillScale = 1.0;
        animateInEnd.rect = frame;
        animateInEnd.crop = CGRectMake(0, 0, 1, 1);
        
        if (index<(_fileList.count - 1)) {
            
            CGSize bsize = [self getVVAssetSize:nil atFile:_fileList[index+1]];
            
            float off_h = currentsize.width/currentsize.height * (bsize.height/bsize.width);
            float off_w = currentsize.height/currentsize.width * (bsize.width/bsize.height);
            
            
            float off_set1;
            CGRect rect ;
            float scale_vb = 0.75;
            if(bsize.height/bsize.width >= m_videoSize.height/m_videoSize.width){
//                scale_va = 0.75;
                off_set1 = MAX(0.125, (1 - m_videoSize.height * bsize.width/bsize.height/m_videoSize.width * scale_vb)/2.0);
                rect = CGRectMake(off_set1, (1 - scale_vb)/2.0, 1-off_set1*2.0, scale_vb);
            }else{
                scale_vb = 0.8;
//                off_set1 = MAX(0.1, (1 - m_videoSize.width * bsize.height/bsize.width/m_videoSize.height * scale_vb)/2.0);
                rect = CGRectMake((1 - scale_vb)/2.0, off_set, scale_vb, 1-off_set*2.0);
            }
            //VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
            animateInEnd.atTime = time - (m_EndTime+0.2);
            animateInEnd.rect = frame;
            animateInEnd.crop = CGRectMake(0, 0, 1, 1);
            
            animateInEnd1.crop = CGRectMake(0, (1-off_h)/2.0, 1, off_h);
            if(currentsize.height/currentsize.width >= bsize.height/bsize.width){
                animateInEnd1.crop = CGRectMake(0, (1-off_h)/2.0, 1, off_h);
            }else{
                animateInEnd1.crop = CGRectMake((1-off_w)/2.0, 0, off_w, 1);
            }
            animateInEnd1.atTime = time - 0.2;
            animateInEnd1.rect = rect;
            
            
            //VVAssetAnimatePosition *animateInStart2 = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd2 = [[VVAssetAnimatePosition alloc] init];
            
            animateInEnd1.atTime = time - 0.2;
            animateInEnd1.crop = CGRectMake(0, (1-off_h)/2.0, 1, off_h);
            if(currentsize.height/currentsize.width >= bsize.height/bsize.width){
                animateInEnd1.crop = CGRectMake(0, (1-off_h)/2.0, 1, off_h);
            }else{
                animateInEnd1.crop = CGRectMake((1-off_w)/2.0, 0, off_w, 1);
            }
            animateInEnd1.rect = animateInEnd1.rect;
            animateInEnd1.rect = rect;
            
            animateInEnd2.atTime = time;
            animateInEnd2.crop = CGRectMake(0, (1-off_h)/2.0, 1, off_h);
            if(currentsize.height/currentsize.width >= bsize.height/bsize.width){
                animateInEnd2.crop = CGRectMake(0, (1-off_h)/2.0, 1, off_h);
            }else{
                animateInEnd2.crop = CGRectMake((1-off_w)/2.0, 0, off_w, 1);
            }
            animateInEnd2.rect = rect;
            
            
            vanimations = [@[animateInStart,animateInEnd] mutableCopy];
            [vanimations addObjectsFromArray:@[animateInEnd1]];
            [vanimations addObjectsFromArray:@[animateInEnd2]];
            
            
            
        }else{
            VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
            
            animateInStart1.atTime = time - (m_EndTime + 0.2);
            animateInStart1.opacity = 1;
            animateInStart1.rect = frame;
            
            animateInEnd1.atTime = time- 0.2;
            animateInEnd1.opacity = 0;
            animateInEnd1.rect = frame;
            
            VVAssetAnimatePosition *animateInStart2 = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd2 = [[VVAssetAnimatePosition alloc] init];
            
            animateInStart2.atTime = time - 0.2;
            animateInStart2.opacity = 0;
            animateInStart2.rect = frame;
            
            animateInEnd2.atTime = time;
            animateInEnd2.opacity = 0;
            animateInEnd2.rect = frame;
            
            vanimations = [@[animateInStart,animateInEnd] mutableCopy];
            [vanimations addObjectsFromArray:@[animateInStart1,animateInEnd1]];
            [vanimations addObjectsFromArray:@[animateInStart2,animateInEnd2]];
        }
        animate1 = vanimations;
        
        
        
    }
//    else{
//        frame = CGRectMake(0., 0, 1, 1);
//        if( EffectType !=  Image_Effect_Default)
//            animate1 = [self getImage_Effect:scene atvvasset:vvasset atThemeImage_EffectType:EffectType atframe:frame atStartTime: lastEndAnimationRotate  ? m_EndTime : 0 atTime:time atstartScale:&startScale atendScale:&endScale atfile:file atIndex:index atIsEnd:NO atThemeIndex:EffectIndex];
//        else
//        {
//            //无任何动作 为默认展示图片
//            file.imageDurationTime = CMTimeMakeWithSeconds( time , TIMESCALE);
//            startScale = 1.0;
//            endScale = 1.0;
//            VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
//            VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
//            animateInStart.atTime = 0;
//            animateInStart.rect = frame;
//            animateInEnd.atTime = time;
//            animateInEnd.rect = frame;
//            vvasset.animate = [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
//            vvasset.startTimeInScene = kCMTimeZero;
//
//            [scene.vvAsset addObject:vvasset];
//        }
//    }
    
    if(lastEndAnimationRotate){
        NSMutableArray *vanimations = [[NSMutableArray alloc] init];
        VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
        VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
        
        animateInStart1.atTime = 0;
        animateInEnd1.atTime = m_EndTime;
        animateInStart1.rotate = -15;
        animateInEnd1.rotate = 0;
        [vanimations addObjectsFromArray:animate1];
        [vanimations addObjectsFromArray:@[animateInStart1,animateInEnd1]];
        animate1 = vanimations;
    }
    
    if( LASTEndAnmiationBlur )
    {
        NSMutableArray *vanimations = [[NSMutableArray alloc] init];
        VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
        VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
        animateInStart1.atTime = 0;
        animateInEnd1.atTime = m_EndTime;
        RDAssetBlur * StartBlur = [[RDAssetBlur alloc] init];
        StartBlur.type = RDAssetBlurNormal;
        StartBlur.intensity = 1.0;
        RDAssetBlur * EndBlur = [[RDAssetBlur alloc] init];
        EndBlur.type = RDAssetBlurNormal;
        EndBlur.intensity = 1.0;
        animateInStart1.blur = StartBlur;
        animateInEnd1.blur = EndBlur;
        
        [animate1 firstObject].atTime = m_EndTime;
        
        [vanimations addObjectsFromArray:animate1];
        [vanimations addObjectsFromArray:@[animateInStart1,animateInEnd1]];
        animate1 = vanimations;
         m_CurrentCindxe = Image_Effect_Default;
    }
    
    //结尾
    //tempFile.imageDurationTime = CMTimeMakeWithSeconds( (time > m_EndTime)? m_EndTime: (time/2) , TIMESCALE);
    {
        //最后一张图片的处理 Grammy Action Boxed
        if( ( ( EffectIndex == Effect_Grammy )
             || ( EffectIndex == Effect_Action)
             || ( EffectIndex == Effect_Boxed)
             || ( EffectIndex == Effect_Epic))
             && ( IsLast ) )
        {
            m_EndTime = 1.0;
            if( EffectIndex == Effect_Boxed  )
            {
                NSString *key = [NSString stringWithFormat:@"%zd-%d",EffectIndex,index];
                if([[m_EndAnimationEffects allKeys] containsObject:key]){
                    cindex = [m_EndAnimationEffects[key] intValue];
                }else{
                    cindex = arc4random() % 2 + 1;
                    if(IsLast)
                        cindex = Image_Effect_Fade;
                    [m_EndAnimationEffects setObject:[NSNumber numberWithInt:cindex] forKey:key];
                }
            }
            else{
                if( ( file.fileType == kFILEIMAGE ) || ( EffectIndex == Effect_Boxed ) ||  ( EffectIndex == Effect_Slice ) || (EffectIndex == Effect_Flick) || ( videoResolvPowerType == VideoResolvPower_Portait )   )
                {
                    CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                    if( file.fileType == kFILEVIDEO  )
                    {
                        CGRect crop = CGRectMake(0, 0, 1, 1);
                        float oldWidth = (m_videoSize.width/m_videoSize.height)*currentsize.height;
                        if( oldWidth < currentsize.width  )
                        {
                            float offtset = oldWidth/currentsize.width;
                            crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
                        }
                        else if(  oldWidth > currentsize.width   )
                        {
                            float oldHeihgt = (m_videoSize.height/m_videoSize.width)*currentsize.width;
                            float offtset = oldHeihgt/currentsize.height;
                            crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
                        }
                        [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            obj.crop = crop;
                        }];
                        [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            obj.crop = crop;
                        }];
                    }
                    NSMutableArray *arr = [animate1 mutableCopy];
                    [arr addObjectsFromArray:animate2];
                    vvasset.animate = [arr copy];
                    vvasset.isBlurredBorder = NO;
                    vvasset.startTimeInScene = kCMTimeZero;
                    [scene.vvAsset addObject:vvasset];
                }
                else
                {
                    CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
                    if( currentsize.width <= currentsize.height )
                    {
                        NSMutableArray *arr = [animate1 mutableCopy];
                        [arr addObjectsFromArray:animate2];
                        VVAsset * vvAsset1 = [self getVvasset:file atThemeIndex:EffectIndex];
                        vvAsset1.blurIntensity = 0.4;
                        vvAsset1.startTimeInScene = kCMTimeZero;
                        vvAsset1.isBlurredBorder = NO;
                        vvAsset1.animate = [arr copy];
                        [scene.vvAsset addObject:vvAsset1];
        
                        float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*0.8));
                        CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
                        if( currentsize.width == currentsize.height )
                            crop = CGRectMake(0,0,1,1);
                        [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            obj.crop = crop;
                        }];
                        [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            obj.crop = crop;
                        }];
                        vvasset.videoFillType = RDVideoFillTypeFit;
                    }
                    NSMutableArray *arr1 = [animate1 mutableCopy];
                    [arr1 addObjectsFromArray:animate2];
                    vvasset.animate = [arr1 copy];
                    vvasset.startTimeInScene = kCMTimeZero;
                    [scene.vvAsset addObject:vvasset];
                }
                return scene;
            }
        }
        else if( EffectIndex == Effect_Grammy )//Grammy
        {
            NSString *key = [NSString stringWithFormat:@"%zd-%d",EffectIndex,index];
            if([[m_EndAnimationEffects allKeys] containsObject:key]){
                
                cindex = [m_EndAnimationEffects[key] intValue];
            }else{
                NSArray *list;
                
                if( file.fileType == kFILEIMAGE )
                    list = @[[NSNumber numberWithInt:Image_Effect_Enlarge]
                             ,[NSNumber numberWithInt:Image_Effect_Narrow]
                             ,[NSNumber numberWithInt:Image_Effect_BandW]
                             ,[NSNumber numberWithInt:Image_Effect_ProEnlarge]
                             ,[NSNumber numberWithInt:Image_Effect_vague]
                             ,[NSNumber numberWithInt:Image_Effect_EnlargeVague]
                             ,[NSNumber numberWithInt:Image_Effect_Fade]];
                else
                    list = @[ [NSNumber numberWithInt: Image_Effect_Fade]
                              ,[NSNumber numberWithInt:Image_Effect_FlickerAndWhite]
                              ,[NSNumber numberWithInt:Image_Effect_EnlargeVague]
                              ,[NSNumber numberWithInt:Image_Effect_vague]];
                //随机获取 图片结尾特效
                cindex = arc4random() % list.count;
                //效果不能和前一个相同 且不能小于0
                endImageEffectCurrent = [list[cindex] intValue];
                cindex = (endImageEffectCurrent == EffectType)?( cindex-1 ):cindex;
                cindex = (int)(cindex<0)?(list.count-1):cindex;
                endImageEffectCurrent = [list[cindex] intValue];
                cindex = endImageEffectCurrent;
                [m_EndAnimationEffects setObject:[NSNumber numberWithInt:cindex] forKey:key];
            }
        }
        else if( EffectIndex == Effect_Action )//Action
        {
            
            
            NSString *key = [NSString stringWithFormat:@"%zd-%d",EffectIndex,index];
            if([[m_EndAnimationEffects allKeys] containsObject:key]){
                
                cindex = [m_EndAnimationEffects[key] intValue];
            }else{
                NSArray *list;
                
                if( tempFile.fileType == kFILEIMAGE )
                    list = @[[NSNumber numberWithInt:Image_Effect_Enlarge]
                             ,[NSNumber numberWithInt:Image_Effect_LeftPush]
                             ,[NSNumber numberWithInt:Image_Effect_RotateEnlarge]
                             ,[NSNumber numberWithInt:Image_Effect_ProEnlarge]
                             ,[NSNumber numberWithInt:Image_Effect_RightPush]];
                else
                    list = @[[NSNumber numberWithInt:Image_Effect_ProEnlarge]
                             ,[NSNumber numberWithInt:Image_Effect_FlashBlack]
                             ,[NSNumber numberWithInt:Image_Effect_FlickerAndWhite]
                             ,[NSNumber numberWithInt:Image_Effect_Fade]];
                //随机获取 图片结尾特效
                cindex =  arc4random() % (list.count);
                //效果不能和前一个相同 且不能小于0
                if(cindex == EffectType)
                    cindex += 1;
                cindex = (cindex == (list.count) ? 0 : cindex);
                
                int dCindex = cindex;
                
                endImageEffectCurrent = [list[cindex] intValue];
                cindex = endImageEffectCurrent;
                
                if( m_oldcindex == cindex )
                {
                    if( cindex == Image_Effect_RotateEnlarge )
                        cindex = Image_Effect_RightPush;
                    else
                    {
                        cindex = dCindex - 1;
                        cindex = (int)((cindex >= 0)?cindex:(list.count-1));
                        endImageEffectCurrent = [list[cindex] intValue];
                        cindex = endImageEffectCurrent;
                    }
                }
                [m_EndAnimationEffects setObject:[NSNumber numberWithInt:cindex] forKey:key];
            }
            
            NSLog(@"key:%@ index:%d",key,cindex);
            m_oldcindex = cindex;
           //cindex = Image_Effect_ProEnlarge;
        }
        else if( EffectIndex == Effect_Boxed )
        {
            //随机获取 图片结尾特效
            NSString *key = [NSString stringWithFormat:@"%zd-%d",EffectIndex,index];
            if([[m_EndAnimationEffects allKeys] containsObject:key]){
                
                cindex = [m_EndAnimationEffects[key] intValue];
            }else{
                cindex = arc4random() % 2 + 1;
                if(IsLast)
                    cindex = Image_Effect_Fade;
                [m_EndAnimationEffects setObject:[NSNumber numberWithInt:cindex] forKey:key];
            }
//            else if( cindex == 1 )
//                cindex = Image_Effect_Enlarge;
        }
        else if( EffectIndex == Effect_Flick )
        {
            NSString *key = [NSString stringWithFormat:@"%zd-%d",EffectIndex,index];
            if([[m_EndAnimationEffects allKeys] containsObject:key]){
                
                cindex = [m_EndAnimationEffects[key] intValue];
            }else{
                cindex = arc4random() % 5;
                if( 0 == cindex )
                    cindex = Image_Effect_FlickerAndWhite;
                else if( 1 == cindex )
                    cindex = Image_Effect_Enlarge;
                else if( 2 == cindex )
                    cindex = Image_Effect_BandW;
                else if( 3 == cindex )
                    cindex = Image_Effect_TransitionTypeInvert;
                else if( 4 == cindex )
                    cindex = Image_Effect_BlinkWhiteGray;
                
                if( cindex == m_oldcindex )
                {
                    if( 0==cindex )
                        cindex = Image_Effect_BlinkWhiteGray;
                    else{
                        cindex--;
                        
                        if( 0 == cindex )
                            cindex = Image_Effect_FlickerAndWhite;
                        else if( 1 == cindex )
                            cindex = Image_Effect_Enlarge;
                        else if( 2 == cindex )
                            cindex = Image_Effect_BandW;
                        else if( 3 == cindex )
                            cindex = Image_Effect_TransitionTypeInvert;
                        else if( 4 == cindex )
                            cindex = Image_Effect_BlinkWhiteGray;
                    }
                    [m_EndAnimationEffects setObject:[NSNumber numberWithInt:cindex] forKey:key];
                }
            }
            
            
            m_oldcindex = cindex;
        }
        else if( ( IsLast) && ( EffectIndex == Effect_Epic ) )
        {
            cindex = Image_Effect_PushDown;
            if(  tempFile.fileType == kFILEVIDEO  )
                cindex = Image_Effect_Fade;
        }
        else if( EffectIndex == Effect_Lapse )
        {
            m_CurrrentThemeEffect = Effect_Lapse;
            
            NSString *key = [NSString stringWithFormat:@"%zd-%d",EffectIndex,index];
            if([[m_EndAnimationEffects allKeys] containsObject:key]){
                
                cindex = [m_EndAnimationEffects[key] intValue];
            }else{
                NSArray *list;
                
                if(   tempFile.fileType == kFILEIMAGE   )
                    list = @[[NSNumber numberWithInt:Image_Effect_LeftPush]
                             ,[NSNumber numberWithInt:Image_Effect_RightPush]
                             ,[NSNumber numberWithInt:Image_Effect_Enlarge]
                             ,[NSNumber numberWithInt:Image_Effect_Fade]];
                else
                    list = @[[NSNumber numberWithInt:Image_Effect_Fade]
                             ,[NSNumber numberWithInt:Image_Effect_FlickerAndWhite]];
                
                cindex = arc4random()%(list.count);
                NSInteger Findex = cindex;
                endImageEffectCurrent = [list[cindex] intValue];
                if( endImageEffectCurrent == m_oldcindex )
                {
                    NSInteger b = list.count-1;
                    Findex--;
                    Findex = (Findex == (-1) ) ? b : Findex;
                    endImageEffectCurrent = [list[Findex] intValue];
                }
                
                cindex = endImageEffectCurrent;
                
                [m_EndAnimationEffects setObject:[NSNumber numberWithInt:cindex] forKey:key];
                
            }
            
            
            m_oldcindex = cindex;
            
            m_CurrentCindxe = cindex;
        }
        
        animate2 = [self getImage_Effect:scene atvvasset:vvasset  atThemeImage_EffectType:cindex atframe:frame atStartTime: (time > m_EndTime)? (time - m_EndTime) : (time/2) atTime:time atstartScale:&startScale atendScale:&endScale atfile:tempFile atIndex:index atIsEnd:YES atThemeIndex:EffectIndex];
    }
    if(EffectType == Image_Effect_PushUp || EffectType == Image_Effect_PushDown){
        CGRect rect = [animate1 lastObject].crop;
        [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.crop = rect;
        }];
    }
    
    if( ( file.fileType == kFILEIMAGE ) || ( EffectIndex == Effect_Boxed ) ||  ( EffectIndex == Effect_Slice ) || (EffectIndex == Effect_Flick) || ( videoResolvPowerType == VideoResolvPower_Portait )  )
    {
        CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
        if( (file.fileType == kFILEVIDEO) && ( EffectIndex != Effect_Boxed )   )
        {
            CGRect crop = CGRectMake(0, 0, 1, 1);
            float oldWidth = (m_videoSize.width/m_videoSize.height)*currentsize.height;
            if( oldWidth < currentsize.width  )
            {
                float offtset = oldWidth/currentsize.width;
                crop = CGRectMake((1-offtset)/2.0, 0, offtset , 1);
            }
            else if(  oldWidth > currentsize.width   )
            {
                float oldHeihgt = (m_videoSize.height/m_videoSize.width)*currentsize.width;
                float offtset = oldHeihgt/currentsize.height;
                crop = CGRectMake(0, (1-offtset)/2.0, 1, offtset);
            }
            [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.crop = crop;
            }];
            [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.crop = crop;
            }];
        }
        NSMutableArray *arr = [animate1 mutableCopy];
        [arr addObjectsFromArray:animate2];
        vvasset.animate = [arr copy];
        vvasset.isBlurredBorder = NO;
        vvasset.startTimeInScene = kCMTimeZero;
        [scene.vvAsset addObject:vvasset];
    }
    else
    {
        CGSize currentsize = [self getVVAssetSize:nil atFile:tempFile];
        if( currentsize.width <= currentsize.height )
        {
            NSMutableArray *arr = [animate1 mutableCopy];
            [arr addObjectsFromArray:animate2];
            VVAsset * vvAsset1 = [self getVvasset:file atThemeIndex:EffectIndex];
            vvAsset1.blurIntensity = 0.5;
            vvAsset1.startTimeInScene = kCMTimeZero;
            vvAsset1.isBlurredBorder = NO;
            vvAsset1.animate = [arr copy];
            [scene.vvAsset addObject:vvAsset1];
            
            
            float off_setb =  currentsize.width/currentsize.height * (m_videoSize.height/(m_videoSize.width*0.8));
            CGRect crop = CGRectMake( 0 ,(1-off_setb)/2.0,  1,off_setb);
            if( currentsize.width == currentsize.height )
                crop = CGRectMake(0,0,1,1);
            [animate2 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.crop = crop;
            }];
            [animate1 enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.crop = crop;
            }];
            vvasset.videoFillType = RDVideoFillTypeFit;
        }
       
        NSMutableArray *arr1 = [animate1 mutableCopy];
        [arr1 addObjectsFromArray:animate2];
        vvasset.animate = [arr1 copy];
        
        vvasset.startTimeInScene = kCMTimeZero;
        [scene.vvAsset addObject:vvasset];
    }
    
    if( vvasset1 != nil )
        [scene.vvAsset addObject:vvasset1];
    return scene;
}

#pragma mark-获取多媒体
-(VVAsset*) getVvasset:(RDFile *) file
          atThemeIndex:(Effect) ThemeIndex
{
    VVAsset* vvasset = [[VVAsset alloc] init];
    
    vvasset.url = file.contentURL;
    
    if(file.fileType == kFILEVIDEO){
        vvasset.type = RDAssetTypeVideo;
        vvasset.videoActualTimeRange = file.videoActualTimeRange;
        
        {
            CGSize imagesize =  [self getVVAssetSize:nil atFile:file];
            if( imagesize.width <= imagesize.height )
                vvasset.isBlurredBorder = YES;
        }
        
        if(file.isReverse){
            vvasset.url = file.reverseVideoURL;
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
            }else{
                vvasset.timeRange = file.reverseVideoTimeRange;
            }
            if(CMTimeCompare(vvasset.timeRange.duration, file.reverseVideoTrimTimeRange.duration) == 1 && CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration)>0){
                vvasset.timeRange = file.reverseVideoTrimTimeRange;
            }
        }
        else{
            if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange)) {
                vvasset.timeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
            }else{
                vvasset.timeRange = file.videoTimeRange;
            }
            if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && CMTimeCompare(vvasset.timeRange.duration, file.videoTrimTimeRange.duration) == 1){
                vvasset.timeRange = file.videoTrimTimeRange;
            }
        }
        vvasset.speed        = file.speed;
        vvasset.volume       = file.videoVolume;
        if( ThemeIndex != Effect_Boxed   )
            vvasset.videoFillType = RDVideoFillTypeFull;
        else
            vvasset.videoFillType = RDVideoFillTypeFit;

    }else{
        vvasset.type         = RDAssetTypeImage;
        vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(   [self getFileDuration:file] , TIMESCALE));
        vvasset.speed        = file.speed;
        if( ThemeIndex != Effect_Boxed )
            vvasset.fillType     = RDImageFillTypeAspectFill;
        else
            vvasset.fillType     = RDImageFillTypeFit;
    }
    vvasset.rotate = file.rotate;
    vvasset.isVerticalMirror = file.isVerticalMirror;
    vvasset.isHorizontalMirror = file.isHorizontalMirror;
    vvasset.crop = file.crop;
    vvasset.volume = 0.0;
    return  vvasset;
}

#pragma mark-图片效果 获取
-(NSArray<VVAssetAnimatePosition*>*)getImage_Effect:(RDScene *) scene
                                          atvvasset:(VVAsset *) vvasset
                            atThemeImage_EffectType:(ThemeImage_EffectType) Image_Effect
                                            atframe:(CGRect) frame
                                        atStartTime:(float) StartTime
                                             atTime:(float) time
                                       atstartScale:(float *) startScale
                                         atendScale:(float *) endScale
                                             atfile:(RDFile *) file
                                            atIndex:(int) index
                                            atIsEnd:(bool) IsEnd
                                       atThemeIndex:(int) ThemeIndex
{
    //NSLog(@"====>>startScale: %f    startScale : %f",*startScale,*endScale);
    NSArray<VVAssetAnimatePosition*>* animate;
    
    VVAssetImage_EffectType CurrentEffectType = VVAssetImage_Effect_Default;
    bool isGetSpeEffect = NO;
    
//    if( IsEnd )
//    {
        (*startScale) = (*endScale);
//    }
    
    switch ( Image_Effect ) {
        case Image_Effect_Default://默认
        {
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
        }
            break;
            //放大
        case Image_Effect_Enlarge:
        {
            
            [self adjZoom:YES atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
            if(IsEnd){
                scene.transition.type     = RDVideoTransitionTypeFade;
                scene.transition.duration = m_EndTime;
            }
        }
            break;
            //缩小
        case Image_Effect_Narrow:
        {
            [self adjZoom:NO atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
            if(IsEnd){
                scene.transition.type     = RDVideoTransitionTypeFade;
                scene.transition.duration = m_EndTime;
            }
            
        }
            break;
            //下推
        case Image_Effect_PushDown:
        {
            CurrentEffectType = VVAssetImage_Effect_PushDown;
            isGetSpeEffect = YES;
        }
            break;
            //上推
        case Image_Effect_PushUp:
        {
            CurrentEffectType = VVAssetImage_Effect_PushUp;
            isGetSpeEffect = YES;
        }
            break;
            //黑白
        case Image_Effect_BandW:
        {
            int EfectIndex1 = (arc4random() % 2 + 1);
            
            if( EfectIndex1 == Image_Effect_Enlarge )
            {
                [self adjZoom:YES atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
//                EfectIndex1 =  VVAssetImage_Effect_Default;
            }
            else if( EfectIndex1 == Image_Effect_Narrow )
            {
                [self adjZoom:NO atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
//                EfectIndex1 =  VVAssetImage_Effect_Default;
            }
            else{
                startScale = endScale;
//                EfectIndex1--;
            }
            
            vvasset.saturation = 0.0;
            CurrentEffectType = VVAssetImage_Effect_BandW;
            if(IsEnd){
                scene.transition.type     = RDVideoTransitionTypeFade;
                scene.transition.duration = m_EndTime;
            }
            isGetSpeEffect = YES;
        }
            break;
            //闪黑
        case Image_Effect_FlashBlack:
        {
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
            
            scene.transition.type     = RDVideoTransitionTypeBlinkBlack;
            scene.transition.duration = m_EndTime;
            // scene.transition.maskURL  = [NSURL fileURLWithPath:[kE2ETransPath stringByAppendingString:@"/007.JPG"]];
        }
            break;
            //淡入
        case Image_Effect_Fade:
        {
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
            
            scene.transition.type     = RDVideoTransitionTypeFade;
            scene.transition.duration = m_EndTime;
            //scene.transition.maskURL  = [NSURL fileURLWithPath:[kE2ETransPath stringByAppendingString:@"/007.JPG"]];
        }
            break;
            //放大旋转
        case Image_Effect_RotateEnlarge:
        {
            [self adjZoom:YES atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
            CurrentEffectType = VVAssetImage_Effect_RotateZoom;
            isGetSpeEffect = YES;
            scene.transition.type     = RDVideoTransitionTypeFade;
            scene.transition.duration = m_EndTime;
        }
            break;
            //左推
        case Image_Effect_LeftPush:
        {
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
            
            scene.transition.type     = RDVideoTransitionTypeLeft;
            scene.transition.duration = m_EndTime*2;
            //scene.transition.maskURL  = [NSURL fileURLWithPath:[kE2ETransPath stringByAppendingString:@"/007.JPG"]];
        }
            break;
            //右推
        case Image_Effect_RightPush:
        {
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
            
            scene.transition.type     = RDVideoTransitionTypeRight;
            scene.transition.duration = m_EndTime*2;
            //scene.transition.maskURL  = [NSURL fileURLWithPath:[kE2ETransPath stringByAppendingString:@"/007.JPG"]];
        }
            break;
            //放大 边界改变
        case Image_Effect_EnlargeSideChange:
        {
            [self adjZoom:YES atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
            CurrentEffectType = VVAssetImage_Effect_ZOOM;
            isGetSpeEffect = YES;
        }
            break;
            //渐进放大
        case Image_Effect_ProEnlarge:
        {
            [self adjZoom:YES atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
            
            CurrentEffectType = VVAssetImage_Effect_ProEnlarge;
            isGetSpeEffect = YES;
            
            scene.transition.type     = RDVideoTransitionTypeFade;
            scene.transition.duration = m_EndTime;
            //scene.transition.maskURL  = [NSURL fileURLWithPath:[kE2ETransPath stringByAppendingString:@"/007.JPG"]];
        }
            break;
        //上下左右推然后放大
        case Image_Effect_PushProEnlarge:
        {
            float startTime = 0.2;
            float fTime = time - m_EndTime;
            
            isGetSpeEffect = NO;
            VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
            animateInStart.atTime = 0;
            float pushSpan = 0.25;
            if(vvasset.type == RDAssetTypeImage){
                
               CGSize imageSize = [self getVVAssetSize:vvasset atFile:nil];
                if(imageSize.width < imageSize.height){
                    pushSpan = ((imageSize.height - (imageSize.height * m_videoSize.height/m_videoSize.width))/2.0)/imageSize.height;
                }
            }
            int x = arc4random()%2;
            
            float Offset =  (x%2 == 0 ? 0.0 : pushSpan) - (x%2 == 0 ? pushSpan : 0.0);
            
            animateInStart.rect = CGRectMake(0, x%2 == 0 ? pushSpan : 0.0, 1, 1);
            animateInEnd.atTime = fTime - startTime;
            animateInEnd.rect = CGRectMake(0, (x%2 == 0 ? pushSpan : 0.0) + Offset, 1, 1);
            
            VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
            animateInStart1.atTime = fTime - startTime;
            animateInStart1.fillScale = 1.0;
            animateInStart1.rotate = 0;
            animateInStart1.rect = CGRectMake(0, (x%2 == 0 ? pushSpan : 0.0) + Offset, 1, 1);
            animateInEnd1.atTime = fTime;
            animateInEnd1.fillScale = 1.4;
            animateInEnd1.rect = CGRectMake(0, (x%2 == 0 ? 0.0 : pushSpan), 1, 1);
            //animateInEnd1.rotate = 2;
            //CurrrentRotate = animateInEnd1.rotate;
            
            (*startScale) = 1.4;
            (*endScale) = 1.4;
            animate = [NSMutableArray arrayWithObjects:animateInStart,animateInEnd,animateInStart1,animateInEnd1, nil];
        }
            break;
        //闪白
        case Image_Effect_FlickerAndWhite:
        {
            CurrentEffectType = VVAssetImage_Effect_Default;
            isGetSpeEffect = YES;
            
            scene.transition.type     = RDVideoTransitionTypeBlinkWhite;
            scene.transition.duration = m_EndTime;
        }
            break;
        //模糊
        case Image_Effect_vague:
        {
            CurrentEffectType = VVAssetImage_Effect_vague;
            isGetSpeEffect = YES;
 
        }
            break;
        //模糊 放大
        case Image_Effect_EnlargeVague:
        {
            CurrentEffectType = VVAssetImage_Effect_vague;
            isGetSpeEffect = YES;
            [self adjZoom:YES atIsEnd:IsEnd atStartScale:startScale atEndScale: endScale];
        }
            break;
        //闪白-黑白/反色-反色/黑白-黑白
        case Image_Effect_TransitionTypeInvert:
        {
            scene.transition.type     = RDVideoTransitionTypeBlinkWhiteInvert;
            scene.transition.duration = m_EndTime;
        }
            break;
        //闪白-中间白色/上下黑白-中间白色/上下原图-原图
        case Image_Effect_BlinkWhiteGray:
        {
            scene.transition.type     = RDVideoTransitionTypeBlinkWhiteGray;
            scene.transition.duration = m_EndTime;
        }
            break;
        //鱼眼
        case Image_Effect_BulgeDistortion:
        {
            scene.transition.type     = RDVideoTransitionTypeBulgeDistortion;
            scene.transition.duration = m_EndTime;
        }
            break;
        default:
            break;
    }
    
    if(isGetSpeEffect)
        animate =[self getGrammyArray:vvasset Effect:CurrentEffectType Size:&frame atTimeStart: StartTime  atTimeEnd:  StartTime + ((StartTime==0)?([self getFileDuration:file]-m_EndTime):m_EndTime)  atStart:(*startScale)
                                atEnd:(*endScale)   atIsAccelerate: (IsEnd)?YES:NO  ];
    if( Image_Effect_BandW == Image_Effect )
    {
        [animate enumerateObjectsUsingBlock:^(VVAssetAnimatePosition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.saturation = 0.0;
        }];
    }
    
    return animate;
}

#pragma mark-缩放倍数调整
-(void)adjZoom:(bool)    IsEnlarge
       atIsEnd:(bool)    IsEnd
  atStartScale:(float *) StartScale
    atEndScale:(float *) EndScale
{
    if( IsEnlarge )
    {
        //放大
        if( IsEnd )
        {
            if( m_CurrrentThemeEffect == Effect_Grammy )
            {
                if( ((*EndScale) <= 1.3) && ( (*EndScale) > 1.2  ) )//1.3
                    (*EndScale) = 1.7;
                else if( ( (*EndScale) <= 1.2 ) && ( (*EndScale) > 1.1 ) )//1.2
                    (*EndScale) = 1.6;
                else
                    (*EndScale) = 1.3;//1.0
            }
            else
            {
                if( ((*EndScale) <= 1.4) && ( (*EndScale) > 1.3  ) )//1.4
                    (*EndScale) = 1.7;
                else if( ( (*EndScale) <= 1.3 ) && ( (*EndScale) > 1.2 ) )//1.3
                    (*EndScale) = 1.6;
                else
                    (*EndScale) = 1.3;//1.0
            }
        }
        else{
            if( m_CurrrentThemeEffect == Effect_Grammy )
            {
                (*StartScale) = 1.0;
                (*EndScale) = 1.2;
            }
            else
            {
                (*StartScale) = 1.0;
                (*EndScale) = 1.4;
            }
        }
    }
    else
    {
        //缩小
        if( IsEnd )
        {
            if( m_CurrrentThemeEffect == Effect_Grammy )
            {
                if( ((*EndScale) <= 1.3) && ( (*EndScale) > 1.2  ) )//1.3
                    (*EndScale) = 1.2;
                else if( ( (*EndScale) <= 1.1 ) && ( (*EndScale) > 1.0 ) )//1.2
                    (*EndScale) = 1.0;
                else
                    (*EndScale) = 1.0;//1.0
            }
            else
            {
                if( ((*EndScale) <= 1.4) && ( (*EndScale) > 1.3  ) )//1.4
                    (*EndScale) = 1.2;
                else if( ( (*EndScale) <= 1.3 ) && ( (*EndScale) > 1.2 ) )//1.3
                    (*EndScale) = 1.0;
                else
                (*EndScale) = 1.0;//1.0
            }
        }
        else{
            if( m_CurrrentThemeEffect == Effect_Grammy )
            {
                (*StartScale) = 1.5;
                (*EndScale) = 1.3;
            }
            else
            {
                (*StartScale) = 1.7;
                (*EndScale) = 1.3;
            }
        }
    }
}

#pragma mark-动画特效获取
-(NSArray<VVAssetAnimatePosition*>*)getGrammyArray: (VVAsset *) vvasset
                                            Effect:(VVAssetImage_EffectType) index
                                              Size:(CGRect * ) frame
                                       atTimeStart:(float) TimeStart
                                         atTimeEnd:(float) TimeEnd
                                           atStart:(float) StartScale
                                             atEnd:(float) EndScale
                                    atIsAccelerate:(bool)  IsAccelerate
{
    
//    if( (StartScale == EndScale) && (VVAssetImage_Effect_Default == index || (VVAssetImage_Effect_ZOOM == index))  )
//    {
//        int b = 0;
//    }
    NSArray<VVAssetAnimatePosition*>* animate;
    
    VVAssetAnimatePosition *animateInStart = [[VVAssetAnimatePosition alloc] init];
    VVAssetAnimatePosition *animateInEnd = [[VVAssetAnimatePosition alloc] init];
    if( IsAccelerate )
    {
        animateInStart.type = AnimationInterpolationTypeAccelerateDecelerate;
        animateInEnd.type = AnimationInterpolationTypeAccelerateDecelerate;
    }
    
    if( m_CurrrentThemeEffect == Effect_Lapse )
    {
        if( m_Islast )
        {
          if( IsAccelerate )
          {
              animateInStart.saturation = 0.2;
              animateInEnd.saturation = 0.0;
              
              animateInStart.opacity = 0.8;
              animateInEnd.opacity = 0.0;
          }
          else
          {
              animateInStart.saturation = 1.0;
              animateInEnd.saturation = 0.2;
              animateInStart.opacity = 1.0;
              animateInEnd.opacity = 0.8;
          }
        }else
        {
            if( IsAccelerate  && (  ( m_CurrentCindxe == Image_Effect_LeftPush ) || ( m_CurrentCindxe ==  Image_Effect_RightPush )) )
            {
                RDAssetBlur * StartBlur = [[RDAssetBlur alloc] init];
                StartBlur.type = RDAssetBlurNormal;
                StartBlur.intensity = 1.0;
                
                RDAssetBlur * EndBlur = [[RDAssetBlur alloc] init];
                EndBlur.type = RDAssetBlurNormal;
                EndBlur.intensity = 1.0;
                animateInStart.blur = StartBlur;
                animateInEnd.blur = EndBlur;
            }
        }
    }
    
    if(m_Islast)
    {
        if( m_CurrrentThemeEffect == Effect_Grammy )
        {
                animateInStart.opacity = 1.0;
                animateInEnd.opacity = 0.1;
        }
        if( m_CurrrentThemeEffect == Effect_Action )
        {
                RDAssetBlur * StartBlur = [[RDAssetBlur alloc] init];
                StartBlur.type = RDAssetBlurNormal;
                StartBlur.intensity = 0.0;
                
                RDAssetBlur * EndBlur = [[RDAssetBlur alloc] init];
                EndBlur.type = RDAssetBlurNormal;
                EndBlur.intensity = 1.0;
                animateInStart.blur = StartBlur;
                animateInEnd.blur = EndBlur;
                animateInStart.opacity = 1.0;
                animateInEnd.opacity = 0.1;
        }
    }
    
    animateInStart.atTime = TimeStart;
    animateInStart.rect = (*frame);
    animateInStart.fillScale = StartScale;
    animateInStart.rotate = m_CurrrentRotate;
    
    animateInEnd.atTime = TimeEnd;
    animateInEnd.rect = (*frame);
    animateInEnd.fillScale = EndScale;
    animateInEnd.rotate = m_CurrrentRotate;    
    
    switch (index) {
        case VVAssetImage_Effect_Default:
        {
            animate = [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
            //缩放
        case VVAssetImage_Effect_ZOOM:
        {
            float StartScale_Offset =  (StartScale - 1.0)/2.0 * ((*frame).size.width/1.0);
            float EneScale_Offset = (EndScale - 1.0)/2.0 * ((*frame).size.width/1.0);
            
            animateInStart.rect = CGRectMake((*frame).origin.x - StartScale_Offset, (*frame).origin.y - StartScale_Offset, (*frame).size.width  + StartScale_Offset*2.0, (*frame).size.height + StartScale_Offset*2.0 );
            animateInEnd.rect = CGRectMake((*frame).origin.x - EneScale_Offset, (*frame).origin.y  - EneScale_Offset, (*frame).size.width + EneScale_Offset*2.0, (*frame).size.height + EneScale_Offset*2.0);
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
            //下推
        case VVAssetImage_Effect_PushDown:
        {
            
            animateInStart.fillScale = 1.0;
            animateInEnd.fillScale = 1.0;
            vvasset.fillType = RDImageFillTypeAspectFill;
            float off_set = 0;
            CGSize imagesize = [self getVVAssetSize:vvasset atFile:nil];
            off_set = m_videoSize.height/m_videoSize.width * imagesize.width/imagesize.height;
            float value = 1;
//            float v = pow(MAX(m_videoSize,m_videoSize), 2) * 2;
//            value = MIN(imagesize.width, imagesize.height)/sqrt(v);
//
            if(imagesize.width<imagesize.height){
                animateInStart.crop = CGRectMake(0, 0, 1, 1);
                if( m_CurrrentThemeEffect ==  Effect_Action)
                    animateInEnd.crop = CGRectMake(0, -(1-off_set*value)/3.0, 1,1 );//off_set*value
                else if(  m_CurrrentThemeEffect ==  Effect_Grammy )
                    animateInEnd.crop = CGRectMake(0, -(1-off_set*value)/25, 1,1 );//off_set*value
                else if( m_CurrrentThemeEffect ==  Effect_Epic)
                        animateInEnd.crop = CGRectMake(0, -(1-off_set*value)/2.0, 1,1 );//off_set*value
                else
                    animateInEnd.crop = CGRectMake(0, -(1-off_set*value)/25, 1,1 );//off_set*value
            }
            if( m_CurrrentThemeEffect ==  Effect_Epic)
            {
                animateInStart.type = AnimationInterpolationTypeAccelerateDecelerate;
                animateInEnd.type = AnimationInterpolationTypeAccelerateDecelerate;
            }
            else
            {
                animateInStart.type = AnimationInterpolationTypeLinear;
                animateInEnd.type = AnimationInterpolationTypeLinear;
            }
            animateInStart.rect = CGRectMake( (*frame).origin.x,  0 , (*frame).size.width, (*frame).size.height);
            animateInEnd.rect = CGRectMake( (*frame).origin.x,   0  , (*frame).size.width, (*frame).size.height);
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
            //上推
        case VVAssetImage_Effect_PushUp:
        {
            float off_set = 0;
            CGSize imagesize = [self getVVAssetSize:vvasset atFile:nil];
            off_set = m_videoSize.height/m_videoSize.width * imagesize.width/imagesize.height;
            float value = 1;// = imagesize.width/imagesize.height;
            
            //float v = pow(MAX(m_videoSize,m_videoSize), 2) * 2;
            //value = MIN(imagesize.width, imagesize.height)/sqrt(v);
            
            if(imagesize.width<imagesize.height){
                animateInEnd.crop = CGRectMake(0, 0, 1, 1);
                if( m_CurrrentThemeEffect ==  Effect_Action)
                    animateInStart.crop = CGRectMake(0, -(1-off_set*value)/3.0, 1, 1);//
                else if(  m_CurrrentThemeEffect ==  Effect_Grammy )
                    animateInStart.crop = CGRectMake(0, -(1-off_set*value)/25, 1, 1);//
                else if( m_CurrrentThemeEffect ==  Effect_Epic)
                {
                    animateInStart.crop = CGRectMake(0, -(1-off_set*value)/2.0, 1,1 );//
                }
                else
                    animateInStart.crop = CGRectMake(0, -(1-off_set*value)/10, 1, 1);//
            }
            if( m_CurrrentThemeEffect ==  Effect_Epic)
            {
                animateInStart.type = AnimationInterpolationTypeAccelerateDecelerate;
                animateInEnd.type = AnimationInterpolationTypeAccelerateDecelerate;
            }
            else
            {
                animateInStart.type = AnimationInterpolationTypeLinear;
                animateInEnd.type = AnimationInterpolationTypeLinear;
            }
            animateInStart.rect = CGRectMake( (*frame).origin.x,  0 , (*frame).size.width, (*frame).size.height);
            animateInEnd.rect = CGRectMake( (*frame).origin.x,   0  , (*frame).size.width, (*frame).size.height);
            //animateInStart.rect = CGRectMake( (*frame).origin.x, (*frame).origin.y -(*frame).size.height, (*frame).size.width, (*frame).size.height);
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
            //旋转
        case VVAssetImage_Effect_RotateZoom:
        {
//            float StartScale_Offset =  (StartScale - 1.0)/2.0 * ((*frame).size.width/1.0);
            float EneScale_Offset = (EndScale - 1.0)/2.0 * ((*frame).size.width/1.0);
//            CGSize imagesize = [self getVVAssetSize:vvasset atFile:nil];
            animateInStart.fillScale = StartScale;//imagesize.height/imagesize.width;
            animateInEnd.fillScale = EndScale;
//            animateInStart.rect = CGRectMake((*frame).origin.x - StartScale_Offset, (*frame).origin.y - StartScale_Offset, (*frame).size.width  + StartScale_Offset*2.0, (*frame).size.height + StartScale_Offset*2.0 );
            animateInEnd.rect = CGRectMake((*frame).origin.x - EneScale_Offset, (*frame).origin.y  - EneScale_Offset, (*frame).size.width + EneScale_Offset*2.0, (*frame).size.height + EneScale_Offset*2.0);
            
            animateInStart.rotate = 0;
            animateInEnd.rotate = 30;
            
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
            
        }
            break;
            //渐进放大
        case VVAssetImage_Effect_ProEnlarge:
        {
            float scale = EndScale - StartScale;
            float time = TimeEnd - TimeStart;
            
            animateInStart.atTime = TimeStart;
            animateInStart.fillScale = StartScale;
            animateInStart.rect = (*frame);
            animateInEnd.atTime = 0.5/10.0 * time +  TimeStart;
            animateInEnd.fillScale = StartScale+ scale * ( (10.0/3.0)/10.0 );
            animateInEnd.rect = (*frame);
            
            VVAssetAnimatePosition *animateInStart1 = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd1 = [[VVAssetAnimatePosition alloc] init];
            animateInStart1.atTime = 4.5/10.0 * time +  TimeStart;
            animateInStart1.fillScale = StartScale + scale * ( (10.0/3.0)/10.0 );
            animateInStart1.rect = (*frame);
            animateInEnd1.atTime = 5.0/10.0 * time +  TimeStart;
            animateInEnd1.fillScale = StartScale + scale * ( 2*(10.0/3.0)/10.0 );
            animateInEnd1.rect = (*frame);
            if( IsAccelerate )
            {
                animateInStart1.type = AnimationInterpolationTypeAccelerateDecelerate;
                animateInEnd1.type = AnimationInterpolationTypeAccelerateDecelerate;
            }
            
            VVAssetAnimatePosition *animateInStart2 = [[VVAssetAnimatePosition alloc] init];
            VVAssetAnimatePosition *animateInEnd2 = [[VVAssetAnimatePosition alloc] init];
            animateInStart2.atTime = 9.5/10.0 * time +  TimeStart;
            animateInStart2.fillScale = StartScale + scale * ( 2*(10.0/3.0)/10.0 );
            animateInStart2.rect = (*frame);
            animateInEnd2.atTime = 10.0/10.0 * time +  TimeStart;
            animateInEnd2.fillScale = StartScale + scale * ( 3*(10.0/3.0)/10.0 );
            animateInEnd2.rect = (*frame);
            if( IsAccelerate )
            {
                animateInStart2.type = AnimationInterpolationTypeAccelerateDecelerate;
                animateInEnd2.type = AnimationInterpolationTypeAccelerateDecelerate;
            }
            
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd,animateInStart1,animateInEnd1,
                        animateInStart2,animateInEnd2,nil];
        }
            break;
        //左移 缩小  移到中心位置
        case VVAssetImage_Effect_LeftShift:
        //右移 缩小  移到中心位置
        case VVAssetImage_Effect_RightShift:
        //中心缩小  移动到中心位置
        case VVAssetImage_Effect_CentralReduction:
        {
            if( VVAssetImage_Effect_LeftShift == index )
                animateInStart.rect = CGRectMake(-0.5, -0.5, 1.0, 2.0);
            else if( VVAssetImage_Effect_RightShift == index )
                animateInStart.rect = CGRectMake(0.5, -0.5, 1.0, 2.0);
            else if( VVAssetImage_Effect_CentralReduction == index )
                animateInStart.rect = CGRectMake(-0.5, -0.5, 2.0, 2.0);
            animateInStart.opacity = 0.6;
            
            animateInEnd.rect = CGRectMake(1/4.0, 1/4.0, 0.5, 0.5);
            animateInEnd.opacity = 1.0;
            animate = [NSMutableArray arrayWithObjects:animateInStart, animateInEnd, nil];
        }
            break;
        //用于 图片分段推进 整体向下推
        case VVAssetImage_Effect_PushDown1:
        {
            
            animateInStart.saturation = 0.0;
            animateInEnd.saturation = 0.0;
            if( (*frame).size.height == 1.0 )
                animateInEnd.rect = CGRectMake( (*frame).origin.x, (*frame).size.height , (*frame).size.width, (*frame).size.height);
            else
                animateInEnd.rect = CGRectMake( -(*frame).size.width, (*frame).origin.y, (*frame).size.width,(*frame).size.height);
           
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
        case VVAssetImage_Effect_PushUp1:
        {
            animateInStart.saturation = 0.0;
            animateInEnd.saturation = 0.0;
            if( (*frame).size.height == 1.0 )
                animateInStart.rect = CGRectMake( (*frame).origin.x, -(*frame).size.height ,(*frame).size.width, (*frame).size.height);
            else
                animateInStart.rect = CGRectMake( (*frame).size.width, (*frame).origin.y, (*frame).size.width,(*frame).size.height);
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
        //用于 图片分段推进 整体向上推
        case VVAssetImage_Effect_PushUp2:
        {   animateInStart.saturation = 0.0;
            if( (*frame).size.height == 1.0 )
                animateInStart.rect = CGRectMake( (*frame).origin.x, (*frame).size.height , (*frame).size.width, (*frame).size.height);
            else
                animateInStart.rect = CGRectMake( -(*frame).size.width, (*frame).origin.y, (*frame).size.width,(*frame).size.height);
            animateInEnd.saturation = 0.0;
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
        case VVAssetImage_Effect_PushDown2:
        {
            animateInStart.saturation = 0.0;
            animateInEnd.saturation = 0.0;
            if( (*frame).size.height == 1.0 )
                animateInEnd.rect = CGRectMake( (*frame).origin.x, -(*frame).size.height ,(*frame).size.width, (*frame).size.height);
            else
                animateInEnd.rect = CGRectMake( (*frame).size.width, (*frame).origin.y, (*frame).size.width,(*frame).size.height);
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
        //模糊
        case VVAssetImage_Effect_vague:
        {
            RDAssetBlur * StartBlur = [[RDAssetBlur alloc] init];
            StartBlur.type = RDAssetBlurNormal;
            StartBlur.intensity = 0.0;
            
            RDAssetBlur * EndBlur = [[RDAssetBlur alloc] init];
            EndBlur.type = RDAssetBlurNormal;
            EndBlur.intensity = 1.0;
            animateInStart.blur = StartBlur;
            animateInEnd.blur = EndBlur;
            
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
        //黑白
        case VVAssetImage_Effect_BandW:
        {
            animateInStart.saturation = 1.0;
            animateInEnd.saturation = 0.0;
            animate =  [NSMutableArray arrayWithObjects:animateInStart,animateInEnd, nil];
        }
            break;
        default:
            break;
    }
    
    return animate;
}

#pragma mark-推动效果 获取 上下左右分段推动
-(void) GetVVAssetEffect:(RDScene *) scene
                  atFile:(RDFile *)  file
             atTimeStart:(float) fTimeStart
               atTimeEnd:(float) fTimeEnd
 atThemeImage_EffectType:(ThemeImage_EffectType) Image_EffectType
               atOffsetW:(float) fOffsetW
                 atCount:(int) count
                  atWorH:(bool) isWidth
                 atIndex:(int) index
{
    if( count > 18 )
        count = 18;
    
    CGSize size = [self getVVAssetSize:nil atFile:file];
    
//    float time = [self getFileDuration:file];
    float fProportionWidth = 1.0;
    float fProprtionHeight = 1.0;
    
    bool isBlackEdgeWidthZreo = NO;
    bool isBlackEdgeHeightZreo = NO;
    
    if( videoResolvPowerType == VideoResolvPower_Film )
    {
        fProportionWidth = 16.0;
        fProprtionHeight = 9.0;
    }
    else if(  videoResolvPowerType == VideoResolvPower_Portait  )
    {
        fProportionWidth = 9.0;
        fProprtionHeight = 16.0;
    }
    
    //黑边比例
    float fBlackEdgeWidth = 0.0;
    float fBlackEdgeHeight = 0.0;
    fBlackEdgeWidth =  (fProportionWidth - ( size.width/size.height ) * fProprtionHeight)/fProportionWidth /(count*2.0) + ((  videoResolvPowerType == VideoResolvPower_Film  )?(0.001/2.0):0.0);
    fBlackEdgeHeight =  (fProprtionHeight - ( size.height/size.width ) * fProportionWidth)/fProprtionHeight /(count*2.0) + ((  videoResolvPowerType == VideoResolvPower_Portait  )?(0.001/2.0):0.0);
    if( fBlackEdgeWidth < 0 )
        fBlackEdgeWidth = 0.0;
    if( fBlackEdgeHeight < 0 )
        fBlackEdgeHeight = 0.0;
    
    if (isBlackEdgeWidthZreo) {
        fBlackEdgeWidth = fBlackEdgeWidth;
    }
    
    if (isBlackEdgeHeightZreo) {
        fBlackEdgeHeight = fBlackEdgeHeight;
    }
    
    VVAssetImage_EffectType down;
    if( Image_Effect_PiecewiseUp == Image_EffectType )
        down =  VVAssetImage_Effect_PushDown2;
    else
        down =  VVAssetImage_Effect_PushDown1;
    
    float startTimeOffset = (fTimeEnd - fTimeStart)/((float)count);
    int fHalfCount = ((float)count - 1)/2.0;
    float CropOffsetX = 1.0/ ((isWidth)?((float)count):1.0);
    float CropOffsetY = 1.0/ ((!isWidth)?((float)count):1.0);
    
    if(isWidth)
    {
        fBlackEdgeHeight = 0.0;
    }
    else
        fBlackEdgeWidth = 0.0;
    
    float OffsetW = 0;
    float OffsetH = 0;
    
    if (isWidth)
        OffsetW = fOffsetW;
    else
        OffsetH = fOffsetW;
    
    RDFile * TempFile;
    if( file.fileType == kFILEVIDEO )
       TempFile = [self GetThumImage:file atIndex:index atIsEnd:true ];
    else
        TempFile = file;
    
    for (int i = 0; i < count; i++) {
        VVAsset * vvasset = [self getVvasset:TempFile atThemeIndex:Effect_Boxed];
        vvasset.isBlurredBorder = NO;
        vvasset.startTimeInScene =  CMTimeMakeWithSeconds( fTimeStart , TIMESCALE);
        vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( (fTimeEnd - fTimeStart), TIMESCALE));
        NSArray<VVAssetAnimatePosition*>* animate;
        int ix = (isWidth)?i:0;
        int iy = (!isWidth)?i:0;
        CGRect frame;
        if( i < fHalfCount )
            frame  = CGRectMake( CropOffsetX*ix+fBlackEdgeWidth*2.0
                                *(fHalfCount-ix)+((((count%2)==0))?fBlackEdgeWidth:0) - OffsetW,
                                CropOffsetY*iy+fBlackEdgeHeight*2.0
                                *(fHalfCount-iy)+((((count%2)==0))?fBlackEdgeHeight:0) - OffsetH,
                                CropOffsetX,
                                CropOffsetY);
        else
            frame = CGRectMake(
                               CropOffsetX*ix-fBlackEdgeWidth*2.0
                               *((((count%2)==0)?(ix-1):ix)-fHalfCount)
                               -((((count%2)==0))?fBlackEdgeWidth:0) - OffsetW,
                               CropOffsetY*iy-fBlackEdgeHeight*2.0
                               *((((count%2)==0)?(iy-1):iy)-fHalfCount)
                               -((((count%2)== 0))? fBlackEdgeHeight:0) - OffsetH,
                               CropOffsetX,
                               CropOffsetY);
        if( (count%2) == 0 )
        {
            if( fHalfCount == i )
            {
                frame  = CGRectMake( CropOffsetX*ix +  fBlackEdgeWidth - OffsetW,
                                    CropOffsetY*iy +  fBlackEdgeHeight - OffsetH,
                                    CropOffsetX,
                                    CropOffsetY);
            }
            else if( (fHalfCount+1) == i )
            {
                frame = CGRectMake( CropOffsetX*ix - fBlackEdgeWidth - OffsetW,
                                   CropOffsetY*iy - fBlackEdgeHeight - OffsetH,
                                   CropOffsetX,
                                   CropOffsetY);
            }
        }
        vvasset.crop = CGRectMake(CropOffsetX*ix, CropOffsetY*iy, CropOffsetX, CropOffsetY);
        float TimeStart = fTimeStart;
        float TimeEnd = startTimeOffset*(i+1) + fTimeStart;
//        float StartScale = 1.0;
//        float EndScale = 1.0;
        animate = [self getGrammyArray:vvasset Effect:down Size:&frame  atTimeStart: TimeStart   atTimeEnd:  TimeEnd atStart:1.0 atEnd:1.0  atIsAccelerate: YES  ];
        {
            [animate firstObject].crop = CGRectMake(CropOffsetX*ix, CropOffsetY*iy, CropOffsetX, CropOffsetY);
            [animate lastObject].crop = CGRectMake(CropOffsetX*ix, CropOffsetY*iy, CropOffsetX, CropOffsetY);
            
            NSMutableArray *arr = [animate mutableCopy];
            vvasset.animate = [arr copy];
            [scene.vvAsset addObject:vvasset];
        }
    }
}

-(void)GetPushEffect:(RDScene *) scene
              atFile:(RDFile *)  file
              atTime:(float) Time
atThemeImage_EffectType:(ThemeImage_EffectType) Image_EffectType
           atOffsetW:(float) fOffsetW
             atCount:(int) count
              atWorH:(bool) isWidth
             atIndex:(int) index
{
    if( count > 18 )
        count = 18;
    
    CGSize size = [self getVVAssetSize:nil atFile:file];
    
    float time = [self getFileDuration:file];
    float fProportionWidth = 1.0;
    float fProprtionHeight = 1.0;
    
    bool isBlackEdgeWidthZreo = NO;
    bool isBlackEdgeHeightZreo = NO;
    
    if( videoResolvPowerType == VideoResolvPower_Film )
    {
        fProportionWidth = 16.0;
        fProprtionHeight = 9.0;
    }
    else if(  videoResolvPowerType == VideoResolvPower_Portait  )
    {
        fProportionWidth = 9.0;
        fProprtionHeight = 16.0;
    }
    
    //黑边比例
    float fBlackEdgeWidth = 0.0;
    float fBlackEdgeHeight = 0.0;
    fBlackEdgeWidth =  (fProportionWidth - ( size.width/size.height ) * fProprtionHeight)/fProportionWidth /(count*2.0) + ((  videoResolvPowerType == VideoResolvPower_Film  )?(0.001/2.0):0.0);
    fBlackEdgeHeight =  (fProprtionHeight - ( size.height/size.width ) * fProportionWidth)/fProprtionHeight /(count*2.0) + ((  videoResolvPowerType == VideoResolvPower_Portait  )?(0.001/2.0):0.0);
    if( fBlackEdgeWidth < 0 )
        fBlackEdgeWidth = 0.0;
    if( fBlackEdgeHeight < 0 )
        fBlackEdgeHeight = 0.0;
    
    if (isBlackEdgeWidthZreo) {
        fBlackEdgeWidth = fBlackEdgeWidth;
    }
    
    if (isBlackEdgeHeightZreo) {
        fBlackEdgeHeight = fBlackEdgeHeight;
    }
    
    VVAssetImage_EffectType up;
//    VVAssetImage_EffectType down;
    if( Image_Effect_PiecewiseUp == Image_EffectType )
        up = VVAssetImage_Effect_PushUp2;
    else
        up = VVAssetImage_Effect_PushUp1;
    
    float startTimeOffset = Time/((float)count);
    int fHalfCount = ((float)count - 1)/2.0;
    float CropOffsetX = 1.0/ ((isWidth)?((float)count):1.0);
    float CropOffsetY = 1.0/ ((!isWidth)?((float)count):1.0);
    
    if(isWidth)
    {
        fBlackEdgeHeight = 0.0;
    }
    else
        fBlackEdgeWidth = 0.0;
    
    float OffsetW = 0;
    float OffsetH = 0;
    
    if (isWidth)
        OffsetW = fOffsetW;
    else
        OffsetH = fOffsetW;
    
    RDFile * TempFile;
    if( file.fileType == kFILEVIDEO )
        TempFile = [self GetThumImage:file atIndex:index atIsEnd:false ];
    else
        TempFile = file;
    
    for (int i = 0; i < count; i++) {
        VVAsset * vvasset = [self getVvasset:TempFile atThemeIndex:Effect_Boxed];
        vvasset.isBlurredBorder = NO;
        NSArray<VVAssetAnimatePosition*>* animate;
        int ix = (isWidth)?i:0;
        int iy = (!isWidth)?i:0;
        
        CGRect frame;
        if( i < fHalfCount )
            frame  = CGRectMake( CropOffsetX*ix+fBlackEdgeWidth*2.0
                                *(fHalfCount-ix)+((((count%2)==0))?fBlackEdgeWidth:0) - OffsetW,
                                CropOffsetY*iy+fBlackEdgeHeight*2.0
                                *(fHalfCount-iy)+((((count%2)==0))?fBlackEdgeHeight:0) - OffsetH,
                                CropOffsetX,
                                CropOffsetY);
        else
            frame = CGRectMake(
                               CropOffsetX*ix-fBlackEdgeWidth*2.0
                               *((((count%2)==0)?(ix-1):ix)-fHalfCount)
                               -((((count%2)==0))?fBlackEdgeWidth:0) - OffsetW,
                               CropOffsetY*iy-fBlackEdgeHeight*2.0
                               *((((count%2)==0)?(iy-1):iy)-fHalfCount)
                               -((((count%2)== 0))? fBlackEdgeHeight:0) - OffsetH,
                               CropOffsetX,
                               CropOffsetY);
        if( (count%2) == 0 )
        {
            if( fHalfCount == i )
            {
                frame  = CGRectMake( CropOffsetX*ix +  fBlackEdgeWidth - OffsetW,
                                    CropOffsetY*iy +  fBlackEdgeHeight - OffsetH,
                                    CropOffsetX,
                                    CropOffsetY);
            }
            else if( (fHalfCount+1) == i )
            {
                frame = CGRectMake( CropOffsetX*ix - fBlackEdgeWidth - OffsetW,
                                   CropOffsetY*iy - fBlackEdgeHeight - OffsetH,
                                   CropOffsetX,
                                   CropOffsetY);
            }
        }
        vvasset.crop = CGRectMake(CropOffsetX*ix, CropOffsetY*iy, CropOffsetX, CropOffsetY);
        
        float TimeStart = 0;
        float TimeEnd = startTimeOffset*(i+1);
        animate = [self getGrammyArray:vvasset Effect:up Size:&frame  atTimeStart: TimeStart   atTimeEnd:  TimeEnd atStart:1.0 atEnd:1.0  atIsAccelerate: NO  ];
        {
            [animate firstObject].crop = CGRectMake(CropOffsetX*ix, CropOffsetY*iy, CropOffsetX, CropOffsetY);
            [animate lastObject].crop = CGRectMake(CropOffsetX*ix, CropOffsetY*iy, CropOffsetX, CropOffsetY);
            NSMutableArray *arr = [animate mutableCopy];
            vvasset.animate = [arr copy];
            [scene.vvAsset addObject:vvasset];
        }
    }
    
    {
        CGRect frame = CGRectMake(  - OffsetW,  - OffsetH, 1.0, 1.0);
        VVAsset * vvasset = [self getVvasset:file atThemeIndex:Effect_Boxed];
        vvasset.isBlurredBorder = NO;
        vvasset.startTimeInScene =  CMTimeMakeWithSeconds( startTimeOffset*((float)count) , TIMESCALE);
        vvasset.timeRange    = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( time -  startTimeOffset*((float)count), TIMESCALE));
        NSArray<VVAssetAnimatePosition*>* animate = [self getGrammyArray:vvasset Effect:VVAssetImage_Effect_Default Size:&frame atTimeStart: 0   atTimeEnd: time  atStart:1.2 atEnd:1.0  atIsAccelerate: NO  ];
        NSMutableArray *arr = [animate mutableCopy];
        vvasset.animate = [arr copy];
        [scene.vvAsset addObject:vvasset];
    }
}

#pragma mark-获取视频第一帧图像
-(RDFile *)GetThumImage:(RDFile*) OriginalFile
                atIndex:(int) index
                atIsEnd:(bool) isEnd
{
    RDFile * file = [[RDFile alloc] init];
    file.fileType = kFILEIMAGE;
    file.imageDurationTime = CMTimeMakeWithSeconds(   [self getFileDuration:OriginalFile] , TIMESCALE);
    file.speed = OriginalFile.speed;
    file.rotate = OriginalFile.rotate;
    file.isVerticalMirror = OriginalFile.isVerticalMirror;
    file.isHorizontalMirror = OriginalFile.isHorizontalMirror;
    file.crop = OriginalFile.crop;

    AVURLAsset *asset = [AVURLAsset assetWithURL:OriginalFile.contentURL];
    UIImage * image1;
    
    if( isEnd )
        image1 = [RDHelpClass  assetGetThumImage:[self getFileDuration:OriginalFile] url:OriginalFile.contentURL urlAsset:asset];
    else
        image1 = [RDHelpClass  assetGetThumImage:0 url:OriginalFile.contentURL urlAsset:asset];
    
    NSString *path = [RDHelpClass pathInCacheDirectory:@"QuikImage"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *photoPath;
    
    if(isEnd)
    {
         photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image_video1_%@.jpg",[NSString stringWithFormat:@"%d",index]]];
    }
    else{
       photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image_video_%@.jpg",[NSString stringWithFormat:@"%d",index]]];
    }
    
    NSData* imagedata = UIImageJPEGRepresentation(image1, 1.0);
    unlink([photoPath UTF8String]);
    [[NSFileManager defaultManager] createFileAtPath:photoPath contents:imagedata attributes:nil];
    
    file.contentURL = [NSURL fileURLWithPath:photoPath];
    return file;
}

@end

