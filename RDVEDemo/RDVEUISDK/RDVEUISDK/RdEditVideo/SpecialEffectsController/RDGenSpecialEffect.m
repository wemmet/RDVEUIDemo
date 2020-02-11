//
//  RDGenSpecialEffect.m
//  RDVEUISDK
//
//  Created by apple on 2018/12/25.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGenSpecialEffect.h"


@implementation RDGenSpecialEffect
/**倒序地址生成
 */
+(NSString *)ExportURL:(RDFile *)file
{
    NSString * exportPath = nil;
    {
        NSURL *url = file.contentURL;
        if([RDHelpClass isSystemPhotoUrl:url]){
            NSString *urlstr = [NSString stringWithFormat:@"%@",url];
            NSInteger loca = [urlstr rangeOfString:@"id="].location+3;
            NSInteger len = [urlstr rangeOfString:@"&ext"].location - loca;
            
            NSString *fileName = [urlstr substringWithRange:NSMakeRange(loca, len)];
            exportPath= [fileName stringByAppendingString:@"_reverseFile.mp4"];
            exportPath = [kRDDraftDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"/Reverse/%@",exportPath]];
            
        }else{
            exportPath= [[[[url absoluteString] lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"_reverseFile.mp4"];
            exportPath = [kRDDraftDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"/Reverse/%@",exportPath]];
        }
        NSFileManager *manager = [NSFileManager defaultManager];
        if(![manager fileExistsAtPath:kRDDraftDirectory]){
            [manager createDirectoryAtPath:kRDDraftDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *reverseFolderPath = [kRDDraftDirectory stringByAppendingPathComponent:@"/Reverse"];
        if(![manager fileExistsAtPath:reverseFolderPath]){
            [manager createDirectoryAtPath:reverseFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return exportPath;
}

+( void )refreshVideoTimeEffectType:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile *)file atscene:(RDScene *)scene atTimeRange:(CMTimeRange) TimeRange atIsRemove:(BOOL) IsRemove
{
    CMTimeRange  effectTimeRange;
    if( CMTimeGetSeconds(TimeRange.duration) )
    {
        effectTimeRange = TimeRange;
    }
    else
    {
        AVURLAsset *asset;
        if (file.fileTimeFilterType == kTimeFilterTyp_Reverse) {
            asset = [AVURLAsset assetWithURL:file.reverseVideoURL];
            effectTimeRange = CMTimeRangeMake(file.videoTrimTimeRange.start, file.videoTrimTimeRange.duration);
        }else {
            asset = [AVURLAsset assetWithURL:file.contentURL];
            Float64 duration = CMTimeGetSeconds(file.videoTrimTimeRange.duration);
            effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(duration/2.0 - (duration/5.0/2.0), TIMESCALE), CMTimeMakeWithSeconds(duration/5.0, TIMESCALE));
        }
        
        if(CMTimeCompare(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), asset.duration) == 1){
            effectTimeRange.duration = CMTimeSubtract(asset.duration, effectTimeRange.start);
        }
    }
   
    
    switch (file.fileTimeFilterType) {
        case kTimeFilterTyp_None:
        {
            CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.videoTrimTimeRange.duration);
            RDScene *s1 = [[RDScene alloc] init];
            NSMutableArray      * scenes1 = [NSMutableArray array];
            for ( int i = 0; i < scene.vvAsset.count; i++) {
                [scenes1 addObject:scene.vvAsset[i]];
            }
            if( scenes != nil )
            {
                if( IsRemove )
                    [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    VVAsset *vvAsset = [scenes1[i] copy];
                    vvAsset.videoActualTimeRange = file.videoActualTimeRange;
                    vvAsset.url = file.contentURL;
                    vvAsset.type = RDAssetTypeVideo;
                    vvAsset.timeRange = videoTimeRange;
                    vvAsset.speed = 1;
                    [s1.vvAsset addObject:vvAsset];
                }
            }
            else
            {
                scenes = [[NSMutableArray alloc] init];
                VVAsset *vvAsset = [[VVAsset alloc] init];
                vvAsset.videoActualTimeRange = file.videoActualTimeRange;
                vvAsset.url = file.contentURL;
                vvAsset.type = RDAssetTypeVideo;
                vvAsset.timeRange = videoTimeRange;
                vvAsset.speed = 1;
                [s1.vvAsset addObject:vvAsset];
            }
            
            [scenes1 removeAllObjects];
            scenes1 = nil;
            
            file.timeEffectSceneCount = 0;
            [scenes addObject:s1];
        }
            break;
        case kTimeFilterTyp_Slow:
        {
            RDScene * s1 = [[RDScene alloc] init];
            RDScene * s2 = [[RDScene alloc] init];
            RDScene * s3 = [[RDScene alloc] init];
            
            
            NSMutableArray      * scenes1 = [NSMutableArray array];
            RDScene* e1 = scene;
            for ( int i = 0; i < e1.vvAsset.count; i++) {
                [scenes1 addObject:e1.vvAsset[i]];
            }
            if( scenes != nil )
            {
                if( IsRemove )
                    [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    [RDGenSpecialEffect TimeEffectTypeSlow:effectTimeRange atVVAsset:( (VVAsset*)scenes1[i] ) atS1:s1 atS2:s2 atS3:s3 atFile:file];
                }
            }
            else
            {
                scenes = [[NSMutableArray alloc] init];
                [RDGenSpecialEffect TimeEffectTypeSlow:effectTimeRange atVVAsset:nil atS1:s1 atS2:s2 atS3:s3 atFile:file];
            }
            [scenes1 removeAllObjects];
            scenes1 = nil;
            file.timeEffectSceneCount = 0;
            if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s1];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s2];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s3];
                file.timeEffectSceneCount++;
            }
        }
            break;
            
        case kTimeFilterTyp_Repeat:
        {
            RDScene * s1 = [[RDScene alloc] init];
            RDScene * s2 = [[RDScene alloc] init];
            RDScene * r2 = [[RDScene alloc] init];
            RDScene * s3 = [[RDScene alloc] init];
            RDScene * r3 = [[RDScene alloc] init];
            RDScene * s4 = [[RDScene alloc] init];
            RDScene * s5 = [[RDScene alloc] init];
            
            NSMutableArray      * scenes1 = [NSMutableArray array];
            RDScene* e1 = scene;
            for ( int i = 0; i < e1.vvAsset.count; i++) {
                [scenes1 addObject:e1.vvAsset[i]];
            }
            if( scenes != nil )
            {
                if( IsRemove )
                    [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    [RDGenSpecialEffect TimeEffectTypeRepeat:effectTimeRange atVVAsset:( (VVAsset*)scenes1[i] )  atS1:s1 atS2:s2 atr2:r2 atS3:s3 atr3:r3 atS4:s4 atS5:s5 atFile:file];
                }
            }
            else
            {
                scenes = [[NSMutableArray alloc] init];
                [RDGenSpecialEffect TimeEffectTypeRepeat:effectTimeRange atVVAsset:nil  atS1:s1 atS2:s2 atr2:r2 atS3:s3 atr3:r3 atS4:s4 atS5:s5 atFile:file];
            }
            [scenes1 removeAllObjects];
            scenes1 = nil;
            
            file.timeEffectSceneCount = 0;
            if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s1];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s2];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(r2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:r2];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s3];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(r3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:r3];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(s4.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s4];
                file.timeEffectSceneCount++;
            }
            
            if (CMTimeGetSeconds(s5.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s5];
                file.timeEffectSceneCount++;
            }
        }
            break;
            
        case kTimeFilterTyp_Reverse:
        {
            RDScene * s1 = [[RDScene alloc] init];
            RDScene * s2 = [[RDScene alloc] init];
            RDScene * s3 = [[RDScene alloc] init];
            
            NSMutableArray      * scenes1 = [NSMutableArray array];
            RDScene* e1 = scene;
            for ( int i = 0; i < e1.vvAsset.count; i++) {
                [scenes1 addObject:e1.vvAsset[i]];
            }
            if( scenes != nil )
            {
                if( IsRemove )
                    [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    [RDGenSpecialEffect TimeEffectTypeReverse:effectTimeRange atVVAsset:( (VVAsset*)scenes1[i] ) atS1:s1 atS2:s2 atS3:s3 atFile:file];
                }
            }
            else
            {
                scenes = [[NSMutableArray alloc] init];
                [RDGenSpecialEffect TimeEffectTypeReverse:effectTimeRange atVVAsset:nil atS1:s1 atS2:s2 atS3:s3 atFile:file];
            }
            [scenes1 removeAllObjects];
            scenes1 = nil;
            if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s1];
            }
            
            if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s2];
            }
            
            if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s3];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark- 快动作
+(void)TimeEffectTypeQuick:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                      atS1:(RDScene *)s1 atS2:(RDScene *)s2 atS3:(RDScene *)s3 atFile:(RDFile*) file
{
    CMTimeRange videoTimeRange = CMTimeRangeMake(file.videoTrimTimeRange.start, file.videoTrimTimeRange.duration);
    VVAsset *vvAsset1;
    if( timevvAsset )
        vvAsset1 = [timevvAsset copy];
    else
        vvAsset1 = [[VVAsset alloc] init];
    vvAsset1.url = file.contentURL;
    vvAsset1.type = RDAssetTypeVideo;
    vvAsset1.videoActualTimeRange = file.videoActualTimeRange;
    CMTimeRange      timeRange1 = CMTimeRangeMake(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1.0));
    vvAsset1.timeRange = timeRange1;
    vvAsset1.speed = 1;            [s1.vvAsset addObject:vvAsset1];
    
    VVAsset *vvAsset2;
    if( timevvAsset )
        vvAsset2 = [timevvAsset copy];
    else
        vvAsset2 = [[VVAsset alloc] init];
    vvAsset2.url = file.contentURL;
    vvAsset2.type = RDAssetTypeVideo;
    vvAsset2.videoActualTimeRange = file.videoActualTimeRange;
    
    CMTime timeStart = CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1));
    
    
    timeStart = CMTimeMultiplyByFloat64( CMTimeMake(CMTimeGetSeconds(timeStart) - CMTimeGetSeconds(effectTimeRange.duration)/2.0, TIMESCALE)  ,1.0 );
    
    CMTimeRange  timeRange2 =  CMTimeRangeMake( timeStart , CMTimeMultiplyByFloat64( CMTimeMake(CMTimeGetSeconds(effectTimeRange.duration)*2.0, TIMESCALE), 2.0*1));
    vvAsset2.timeRange = timeRange2;
    
    vvAsset2.speed = 5.0*1;
    [s2.vvAsset addObject:vvAsset2];
    
    VVAsset *vvAsset3;
    if( timevvAsset )
        vvAsset3 = [timevvAsset copy];
    else
        vvAsset3 = [[VVAsset alloc] init];
    vvAsset3.url = file.contentURL;
    vvAsset3.type = RDAssetTypeVideo;
    vvAsset3.videoActualTimeRange = file.videoActualTimeRange;
    CMTimeRange      timeRange3 =  CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)),CMTimeSubtract(videoTimeRange.duration, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)));
    vvAsset3.timeRange = timeRange3;
    vvAsset3.speed = 1;
    [s3.vvAsset addObject:vvAsset3];
}

+(void)TimeEffectTypeQuick:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile*) file;
{
    
}

/**慢动作 单个多媒体生成
 */
+( void )TimeEffectTypeSlow:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile *)file
{
    RDScene * s1 = [[RDScene alloc] init];
    RDScene * s2 = [[RDScene alloc] init];
    RDScene * s3 = [[RDScene alloc] init];
    
    
    
    if(scenes)
    {
        [RDGenSpecialEffect TimeEffectTypeSlow:effectTimeRange atVVAsset:timevvAsset atS1:s1 atS2:s2 atS3:s3 atFile:file];
    }
    else
    {
        scenes = [NSMutableArray array];
        [RDGenSpecialEffect TimeEffectTypeSlow:effectTimeRange atVVAsset:nil atS1:s1 atS2:s2 atS3:s3 atFile:file];
    }
    
    if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s1];
    }
    
    if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s2];
    }
    
    if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s3];
    }
}

#pragma mark- 慢动作
+( void )TimeEffectTypeSlow:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                       atS1:(RDScene *)s1 atS2:(RDScene *)s2 atS3:(RDScene *)s3 atFile:(RDFile*) file
{
    CMTimeRange videoTimeRange;
    NSURL *videoUrl;
    if(file.isReverse){
        videoUrl = file.reverseVideoURL;
        if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange) || CMTimeRangeEqual(file.reverseVideoTimeRange, kCMTimeRangeInvalid)) {
            videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
        }else{
            videoTimeRange = file.reverseVideoTimeRange;
        }
        if(CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration) > 0){
            videoTimeRange = file.reverseVideoTrimTimeRange;
        }
    }
    else{
        videoUrl = file.contentURL;
        if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange) || CMTimeRangeEqual(kCMTimeRangeInvalid, file.videoTimeRange)) {
            videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
        }else{
            videoTimeRange = file.videoTimeRange;
        }
        if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && !CMTimeRangeEqual(file.videoTrimTimeRange, kCMTimeRangeInvalid)){
            videoTimeRange = file.videoTrimTimeRange;
        }
    }
    VVAsset *vvAsset1;
    if( timevvAsset )
        vvAsset1 = [timevvAsset copy];
    else
        vvAsset1 = [[VVAsset alloc] init];
    vvAsset1.url = videoUrl;
    vvAsset1.type = RDAssetTypeVideo;
    vvAsset1.videoActualTimeRange = file.videoActualTimeRange;
    CMTimeRange      timeRange1 = CMTimeRangeMake(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1.0));
    vvAsset1.timeRange = timeRange1;
    vvAsset1.speed = 1;
    [s1.vvAsset addObject:vvAsset1];
    
    VVAsset *vvAsset2;
    if( timevvAsset )
        vvAsset2 = [timevvAsset copy];
    else
        vvAsset2 = [[VVAsset alloc] init];
    vvAsset2.url = videoUrl;
    vvAsset2.type = RDAssetTypeVideo;
    vvAsset2.videoActualTimeRange = file.videoActualTimeRange;
    CMTimeRange      timeRange2 =  CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1)) , CMTimeMakeWithSeconds(CMTimeGetSeconds(effectTimeRange.duration)*0.5, TIMESCALE));
    vvAsset2.timeRange = timeRange2;
    vvAsset2.speed = 0.5;
    [s2.vvAsset addObject:vvAsset2];
    
    VVAsset *vvAsset3;
    if( timevvAsset )
        vvAsset3 = [timevvAsset copy];
    else
        vvAsset3 = [[VVAsset alloc] init];
    vvAsset3.url = videoUrl;
    vvAsset3.type = RDAssetTypeVideo;
    vvAsset3.videoActualTimeRange = file.videoActualTimeRange;
    CMTimeRange      timeRange3 =  CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)),CMTimeSubtract(videoTimeRange.duration, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)));
    vvAsset3.timeRange = timeRange3;
    vvAsset3.speed = 1;
    [s3.vvAsset addObject:vvAsset3];
    
}
/**反复 单个多媒体生成
 */
+( void )TimeEffectTypeRepeat:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile*) file
{
    RDScene * s1 = [[RDScene alloc] init];
    RDScene * s2 = [[RDScene alloc] init];
    RDScene * r2 = [[RDScene alloc] init];
    RDScene * s3 = [[RDScene alloc] init];
    RDScene * r3 = [[RDScene alloc] init];
    RDScene * s4 = [[RDScene alloc] init];
    RDScene * s5 = [[RDScene alloc] init];
    
    if(scenes)
    {
        [RDGenSpecialEffect TimeEffectTypeRepeat:effectTimeRange atVVAsset:timevvAsset  atS1:s1 atS2:s2 atr2:r2 atS3:s3 atr3:r3 atS4:s4 atS5:s5 atFile:file];
    }
    else
    {
        scenes = [NSMutableArray array];
        [RDGenSpecialEffect TimeEffectTypeRepeat:effectTimeRange atVVAsset:nil  atS1:s1 atS2:s2 atr2:r2 atS3:s3 atr3:r3 atS4:s4 atS5:s5 atFile:file];
    }
    
    if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s1];
    }
    
    if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s2];
    }
    
    if (CMTimeGetSeconds(r2.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:r2];
    }
    
    if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s3];
    }
    
    if (CMTimeGetSeconds(r3.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:r3];
    }
    
    if (CMTimeGetSeconds(s4.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s4];
    }
    
    if (CMTimeGetSeconds(s5.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s5];
    }
}
#pragma mark- 反复
+(void)TimeEffectTypeRepeat:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                       atS1:(RDScene *)s1 atS2:(RDScene *)s2 atr2:(RDScene *)r2
                       atS3:(RDScene *)s3 atr3:(RDScene *)r3
                       atS4:(RDScene *)s4 atS5:(RDScene *)s5  atFile:(RDFile*) file
{
    CMTimeRange videoTimeRange;
    NSURL *videoUrl;
    NSURL *reverseVideoUrl;
    if(file.isReverse){
        videoUrl = file.reverseVideoURL;
        reverseVideoUrl = file.contentURL;
        if (CMTimeRangeEqual(kCMTimeRangeZero, file.reverseVideoTimeRange) || CMTimeRangeEqual(file.reverseVideoTimeRange, kCMTimeRangeInvalid)) {
            videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.reverseDurationTime);
        }else{
            videoTimeRange = file.reverseVideoTimeRange;
        }
        if(CMTimeGetSeconds(file.reverseVideoTrimTimeRange.duration) > 0){
            videoTimeRange = file.reverseVideoTrimTimeRange;
        }
    }
    else{
        videoUrl = file.contentURL;
        reverseVideoUrl = file.reverseVideoURL;
        if (CMTimeRangeEqual(kCMTimeRangeZero, file.videoTimeRange) || CMTimeRangeEqual(kCMTimeRangeInvalid, file.videoTimeRange)) {
            videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.videoDurationTime);
        }else{
            videoTimeRange = file.videoTimeRange;
        }
        if(!CMTimeRangeEqual(kCMTimeRangeZero, file.videoTrimTimeRange) && !CMTimeRangeEqual(file.videoTrimTimeRange, kCMTimeRangeInvalid)){
            videoTimeRange = file.videoTrimTimeRange;
        }
    }
    AVURLAsset* asset = [AVURLAsset assetWithURL:file.reverseVideoURL];
    VVAsset *vvAsset1;
    if( timevvAsset )
        vvAsset1 = [timevvAsset copy];
    else
        vvAsset1 = [[VVAsset alloc] init];
    vvAsset1.url = videoUrl;
    vvAsset1.type = RDAssetTypeVideo;
    vvAsset1.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset1.speed = 1;
    //vvAsset1.volume = 0.0;
    vvAsset1.timeRange = CMTimeRangeMake(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, vvAsset1.speed));
    [s1.vvAsset addObject:vvAsset1];
    
    VVAsset *vvAsset2;
    if( timevvAsset )
        vvAsset2 = [timevvAsset copy];
    else
        vvAsset2 = [[VVAsset alloc] init];
    vvAsset2.url = videoUrl;
    vvAsset2.type = RDAssetTypeVideo;
    vvAsset2.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset2.speed = 5.0;
    if( vvAsset2.volume >0 )
        vvAsset2.volume = 0.5;
    vvAsset2.timeRange = CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1)) , CMTimeMultiplyByFloat64(effectTimeRange.duration, 1));
    [s2.vvAsset addObject:vvAsset2];
    
    //逆序
    VVAsset *vvAsset_r2;
    if( timevvAsset )
        vvAsset_r2 = [timevvAsset copy];
    else
        vvAsset_r2 = [[VVAsset alloc] init];
    vvAsset_r2.url = reverseVideoUrl;
    vvAsset_r2.type = RDAssetTypeVideo;
    vvAsset_r2.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset_r2.timeRange = CMTimeRangeMake(CMTimeSubtract(asset.duration, CMTimeAdd(effectTimeRange.start, effectTimeRange.duration)), effectTimeRange.duration);
    vvAsset_r2.speed = 5.0;
    if( vvAsset_r2.volume >0 )
        vvAsset_r2.volume = 0.5;
    [r2.vvAsset addObject:vvAsset_r2];
    
    VVAsset *vvAsset3;
    if( timevvAsset )
        vvAsset3 = [timevvAsset copy];
    else
        vvAsset3 = [[VVAsset alloc] init];
    vvAsset3.url = videoUrl;
    vvAsset3.type = RDAssetTypeVideo;
    vvAsset3.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset3.timeRange = CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1)) , CMTimeMultiplyByFloat64(effectTimeRange.duration, 1));
    vvAsset3.speed = 5.0;
    if( vvAsset3.volume >0 )
        vvAsset3.volume = 0.5;
    [s3.vvAsset addObject:vvAsset3];
    
    //逆序
    VVAsset *vvAsset_r3;
    if( timevvAsset )
        vvAsset_r3 = [timevvAsset copy];
    else
        vvAsset_r3 = [[VVAsset alloc] init];
    vvAsset_r3.url = reverseVideoUrl;
    vvAsset_r3.type = RDAssetTypeVideo;
    vvAsset_r3.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset_r3.timeRange = CMTimeRangeMake(CMTimeSubtract(asset.duration, CMTimeAdd(effectTimeRange.start, effectTimeRange.duration)), effectTimeRange.duration);
    vvAsset_r3.speed = 5.0;
    if( vvAsset_r3.volume >0 )
        vvAsset_r3.volume = 0.5;
    [r3.vvAsset addObject:vvAsset_r3];
    
    VVAsset *vvAsset4;
    if( timevvAsset )
        vvAsset4 = [timevvAsset copy];
    else
        vvAsset4 = [[VVAsset alloc] init];
    vvAsset4.url = videoUrl;
    vvAsset4.type = RDAssetTypeVideo;
    vvAsset4.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset4.timeRange = CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1)) , CMTimeMultiplyByFloat64(effectTimeRange.duration, 1));
    vvAsset4.speed = 5.0;
    if( vvAsset4.volume >0 )
        vvAsset4.volume = 0.5;
    [s4.vvAsset addObject:vvAsset4];
    
    VVAsset *vvAsset5;
    if( timevvAsset )
        vvAsset5 = [timevvAsset copy];
    else
        vvAsset5 = [[VVAsset alloc] init];
    vvAsset5.url = videoUrl;
    vvAsset5.type = RDAssetTypeVideo;
    vvAsset5.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset5.timeRange = CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)),CMTimeSubtract(videoTimeRange.duration, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)));
    vvAsset5.speed = 1;
    //vvAsset5.volume = 0.0;
    [s5.vvAsset addObject:vvAsset5];
}
/**倒序 单个多媒体生成
 */
+( void )TimeEffectTypeReverse:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile*) file
{
    RDScene * s1 = [[RDScene alloc] init];
    RDScene * s2 = [[RDScene alloc] init];
    RDScene * s3 = [[RDScene alloc] init];
    
    if(scenes)
    {
        [RDGenSpecialEffect TimeEffectTypeReverse:effectTimeRange atVVAsset:timevvAsset atS1:s1 atS2:s2 atS3:s3 atFile:file];
    }
    else
    {
        scenes = [NSMutableArray array];
        [RDGenSpecialEffect TimeEffectTypeReverse:effectTimeRange atVVAsset:nil atS1:s1 atS2:s2 atS3:s3 atFile:file];
    }
    
    if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s1];
    }
    
    if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s2];
    }
    
    if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
        [scenes addObject:s3];
    }
}

#pragma mark- 倒序
+(void)TimeEffectTypeReverse:(CMTimeRange)effectTimeRange atVVAsset:(VVAsset *)timevvAsset
                        atS1:(RDScene *)s1 atS2:(RDScene *)s2 atS3:(RDScene *)s3  atFile:(RDFile*) file
{
    CMTimeRange videoTimeRange = CMTimeRangeMake(file.videoTrimTimeRange.start, file.videoTrimTimeRange.duration);
    AVURLAsset* asset = [AVURLAsset assetWithURL:file.reverseVideoURL];
    NSLog(@"asset.duration:%@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, asset.duration)));
    
    VVAsset *vvAsset1;
    if( timevvAsset )
        vvAsset1 = [timevvAsset copy];
    else
        vvAsset1 = [[VVAsset alloc] init];
    vvAsset1.url = file.contentURL;
    vvAsset1.type = RDAssetTypeVideo;
    vvAsset1.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset1.timeRange = CMTimeRangeMake(videoTimeRange.start, CMTimeMultiplyByFloat64(effectTimeRange.start, 1));
    vvAsset1.speed = 1;
    [s1.vvAsset addObject:vvAsset1];
    
    VVAsset *vvAsset2;
    if( timevvAsset )
        vvAsset2 = [timevvAsset copy];
    else
        vvAsset2 = [[VVAsset alloc] init];
    //vvAsset2.url = _reverseVideoURL;
    vvAsset2.url = file.reverseVideoURL;
    vvAsset2.type = RDAssetTypeVideo;
    vvAsset2.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset2.timeRange = CMTimeRangeMake(CMTimeSubtract(asset.duration, CMTimeAdd(effectTimeRange.start, effectTimeRange.duration)), effectTimeRange.duration);
    [s2.vvAsset addObject:vvAsset2];
    
    VVAsset *vvAsset3 ;
    if( timevvAsset )
        vvAsset3 = [timevvAsset copy];
    else
        vvAsset3 = [[VVAsset alloc] init];
    vvAsset3.url = file.contentURL;
    vvAsset3.type = RDAssetTypeVideo;
    vvAsset3.videoActualTimeRange = file.videoActualTimeRange;
    vvAsset3.timeRange = CMTimeRangeMake(CMTimeAdd(videoTimeRange.start, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)), CMTimeSubtract(videoTimeRange.duration, CMTimeMultiplyByFloat64(CMTimeAdd(effectTimeRange.start, effectTimeRange.duration), 1)));
    vvAsset3.speed = 1;
    [s3.vvAsset addObject:vvAsset3];
}

/**生成时间特效
 */
+(void)refreshVideoTimeEffectType:(TimeFilterType)timeEffectType timeEffectTimeRange:(CMTimeRange)effectTimeRange atscenes:(NSMutableArray<RDScene *>*)scenes atFile:(RDFile*) file
{
    switch (timeEffectType) {
        case kTimeFilterTyp_None:
        {
            CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, file.videoTrimTimeRange.duration);
            RDScene *s1 = [[RDScene alloc] init];
            NSMutableArray* scenes1 = [NSMutableArray array];
            RDScene* e1 = scenes[0];
            for ( int i = 0; i < e1.vvAsset.count; i++) {
                [scenes1 addObject:e1.vvAsset[i]];
            }
            if(scenes)
            {
                [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    VVAsset *vvAsset = [scenes1[i] copy];
                    vvAsset.url = file.contentURL;
                    vvAsset.type = RDAssetTypeVideo;
                    vvAsset.videoActualTimeRange = file.videoActualTimeRange;
                    vvAsset.timeRange = videoTimeRange;
                    vvAsset.speed = 1;
                    [s1.vvAsset addObject:vvAsset];
                }
            }
            else
            {
                scenes = [NSMutableArray array];
                VVAsset *vvAsset = [[VVAsset alloc] init];
                vvAsset.url = file.contentURL;
                vvAsset.type = RDAssetTypeVideo;
                vvAsset.videoActualTimeRange = file.videoActualTimeRange;
                vvAsset.timeRange = videoTimeRange;
                vvAsset.speed = 1;
                [s1.vvAsset addObject:vvAsset];
            }
            
            [scenes1 removeAllObjects];
            scenes1 = nil;
            
            [scenes addObject:s1];
        }
            break;
        case kTimeFilterTyp_Slow:
        {
            RDScene * s1 = [[RDScene alloc] init];
            RDScene * s2 = [[RDScene alloc] init];
            RDScene * s3 = [[RDScene alloc] init];
            
            
            NSMutableArray* scenes1 = [NSMutableArray array];
            RDScene* e1 = scenes[0];
            for ( int i = 0; i < e1.vvAsset.count; i++) {
                [scenes1 addObject:e1.vvAsset[i]];
            }
            if(scenes)
            {
                [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    [RDGenSpecialEffect TimeEffectTypeSlow:effectTimeRange atVVAsset:( (VVAsset*)scenes1[i] ) atS1:s1 atS2:s2 atS3:s3 atFile:file];
                }
            }
            else
            {
                scenes = [NSMutableArray array];
                [RDGenSpecialEffect TimeEffectTypeSlow:effectTimeRange atVVAsset:nil atS1:s1 atS2:s2 atS3:s3 atFile:file];
            }
            [scenes1 removeAllObjects];
            scenes1 = nil;
            if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s1];
            }
            
            if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s2];
            }
            
            if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s3];
            }
        }
            break;
            
        case kTimeFilterTyp_Repeat:
        {
            RDScene * s1 = [[RDScene alloc] init];
            RDScene * s2 = [[RDScene alloc] init];
            RDScene * r2 = [[RDScene alloc] init];
            RDScene * s3 = [[RDScene alloc] init];
            RDScene * r3 = [[RDScene alloc] init];
            RDScene * s4 = [[RDScene alloc] init];
            RDScene * s5 = [[RDScene alloc] init];
            
            NSMutableArray* scenes1 = [NSMutableArray array];
            RDScene* e1 = scenes[0];
            for ( int i = 0; i < e1.vvAsset.count; i++) {
                [scenes1 addObject:e1.vvAsset[i]];
            }
            if(scenes)
            {
                [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    [RDGenSpecialEffect TimeEffectTypeRepeat:effectTimeRange atVVAsset:( (VVAsset*)scenes1[i] )  atS1:s1 atS2:s2 atr2:r2 atS3:s3 atr3:r3 atS4:s4 atS5:s5 atFile:file];
                }
            }
            else
            {
                scenes = [NSMutableArray array];
                [RDGenSpecialEffect TimeEffectTypeRepeat:effectTimeRange atVVAsset:nil  atS1:s1 atS2:s2 atr2:r2 atS3:s3 atr3:r3 atS4:s4 atS5:s5 atFile:file];
            }
            [scenes1 removeAllObjects];
            scenes1 = nil;
            
            if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s1];
            }
            
            if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s2];
            }
            
            if (CMTimeGetSeconds(r2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:r2];
            }
            
            if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s3];
            }
            
            if (CMTimeGetSeconds(r3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:r3];
            }
            
            if (CMTimeGetSeconds(s4.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s4];
            }
            
            if (CMTimeGetSeconds(s5.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s5];
            }
        }
            break;
            
        case kTimeFilterTyp_Reverse:
        {
            RDScene * s1 = [[RDScene alloc] init];
            RDScene * s2 = [[RDScene alloc] init];
            RDScene * s3 = [[RDScene alloc] init];
            
            NSMutableArray* scenes1 = [NSMutableArray array];
            RDScene* e1 = scenes[0];
            for ( int i = 0; i < e1.vvAsset.count; i++) {
                [scenes1 addObject:e1.vvAsset[i]];
            }
            if(scenes)
            {
                [scenes removeAllObjects];
                for (int i = 0; i < scenes1.count; i++) {
                    [RDGenSpecialEffect TimeEffectTypeReverse:effectTimeRange atVVAsset:( (VVAsset*)scenes1[i] ) atS1:s1 atS2:s2 atS3:s3 atFile:file];
                }
            }
            else
            {
                scenes = [NSMutableArray array];
                [RDGenSpecialEffect TimeEffectTypeReverse:effectTimeRange atVVAsset:nil atS1:s1 atS2:s2 atS3:s3 atFile:file];
            }
            [scenes1 removeAllObjects];
            scenes1 = nil;
            
            if (CMTimeGetSeconds(s1.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s1];
            }
            
            if (CMTimeGetSeconds(s2.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s2];
            }
            
            if (CMTimeGetSeconds(s3.vvAsset[0].timeRange.duration) > 0.1) {
                [scenes addObject:s3];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 滤镜特效
+ (RDCustomFilter *)getCustomFilerWithFxId:(int)fxId
                             filterFxArray:(NSArray *)filterFxArray
                                 timeRange:(CMTimeRange)timeRange
                   currentFrameTexturePath:(NSString *)currentFrameTexturePath
{
    NSString *path;
    if (fxId == 0) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource: @"RDVEUISDK" ofType :@"bundle"];
        NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
        path = [[resourceBundle resourcePath] stringByAppendingPathComponent:@"/jianji/effect_icon/shear/无"];
    }else {
        if (!filterFxArray || filterFxArray.count == 0) {
            return nil;
        }
        __block NSDictionary *itemDic;
        [filterFxArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([obj1[@"id"] intValue] == fxId) {
                    itemDic = obj1;
                    *stop1 = YES;
                    *stop = YES;
                }
            }];
        }];
        path = [RDHelpClass getEffectCachedFilePath:itemDic[@"file"] updatetime:itemDic[@"updatetime"]];
        NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
        if (fileCount == 0) {
            return nil;
        }
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
    }
    NSString *configPath = [path stringByAppendingPathComponent:@"config.json"];
    RDCustomFilter *customFilter = [[RDCustomFilter alloc] init];
    
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:configPath];
    NSMutableDictionary *effectDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    NSError * error = nil;
    NSString *fragPath = [path stringByAppendingPathComponent:effectDic[@"fragShader"]];
    NSString *vertPath = [path stringByAppendingPathComponent:effectDic[@"vertShader"]];
    customFilter.frag = [NSString stringWithContentsOfFile:fragPath encoding:NSUTF8StringEncoding error:&error];
    customFilter.vert = [NSString stringWithContentsOfFile:vertPath encoding:NSUTF8StringEncoding error:&error];
    customFilter.name = effectDic[@"name"];
    NSString *builtIn = effectDic[@"builtIn"];
    if ([builtIn isEqualToString:@"illusion"]) {
        customFilter.builtInType = RDBuiltIn_illusion;
    }
    customFilter.timeRange = timeRange;
    customFilter.cycleDuration = [effectDic[@"duration"] floatValue];
    NSArray *uniformParams = effectDic[@"uniformParams"];
    [uniformParams enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *type = obj[@"type"];
        NSMutableArray *paramArray = [NSMutableArray array];
        NSArray *frameArray = obj[@"frameArray"];
        [frameArray enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
            RDShaderParams *param = [[RDShaderParams alloc] init];
            param.time = [obj1[@"time"] floatValue];
            if ([type isEqualToString:@"floatArray"]) {
                param.type = UNIFORM_ARRAY;
                param.array = [NSMutableArray array];
                [obj1[@"value"] enumerateObjectsUsingBlock:^(id  _Nonnull obj2, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    [param.array addObject:[NSNumber numberWithFloat:[obj2 floatValue]]];
                }];
            }else if ([type isEqualToString:@"float"]) {
                param.type = UNIFORM_FLOAT;
                param.fValue = [[obj1[@"value"] firstObject] floatValue];
            }else if ([type isEqualToString:@"Matrix4x4"]) {
                param.type = UNIFORM_MATRIX4X4;
                RDGLMatrix4x4 matrix4;
                NSArray *valueArray = obj1[@"value"];
                matrix4.one = (RDGLVectore4){[valueArray[0][0] floatValue], [valueArray[0][1] floatValue], [valueArray[0][2] floatValue], [valueArray[0][3] floatValue]};
                matrix4.two = (RDGLVectore4){[valueArray[1][0] floatValue], [valueArray[1][1] floatValue], [valueArray[1][2] floatValue], [valueArray[1][3] floatValue]};
                matrix4.three = (RDGLVectore4){[valueArray[2][0] floatValue], [valueArray[2][1] floatValue], [valueArray[2][2] floatValue], [valueArray[2][3] floatValue]};
                matrix4.four = (RDGLVectore4){[valueArray[3][0] floatValue], [valueArray[3][1] floatValue], [valueArray[3][2] floatValue], [valueArray[3][3] floatValue]};
                param.matrix4 = matrix4;
            }else {
                param.type = UNIFORM_INT;
                param.iValue = [[obj1[@"value"] firstObject] intValue];
            }
            [paramArray addObject:param];
        }];
        [customFilter setShaderUniformParams:paramArray isRepeat:[obj[@"repeat"] boolValue] forUniform:obj[@"paramName"]];
    }];
    NSArray *textureParams = effectDic[@"textureParams"];
    [textureParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDTextureParams *param = [[RDTextureParams alloc] init];
        if ([[obj objectForKey:@"paramName"] isEqualToString:@"currentFrameTexture"]) {
            param.type = RDSample2DMainTexture;
            param.path = currentFrameTexturePath;
            NSString *warpMode = obj[@"warpMode"];
            if ([warpMode isEqualToString:@"Repeat"]) {
                param.warpMode = RDTextureWarpModeRepeat;
            }else if ([warpMode isEqualToString:@"MirroredRepeat"]) {
                param.warpMode = RDTextureWarpModeMirroredRepeat;
            }
        }else {
            NSString *sourceName = obj[@"source"];
            if (sourceName.length > 0) {
                param.type = RDSample2DBufferTexture;
                param.path = [[configPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:sourceName];
                NSString *warpMode = obj[@"warpMode"];
                if ([warpMode isEqualToString:@"Repeat"]) {
                    param.warpMode = RDTextureWarpModeRepeat;
                }else if ([warpMode isEqualToString:@"MirroredRepeat"]) {
                    param.warpMode = RDTextureWarpModeMirroredRepeat;
                }
            }
        }
        param.name = obj[@"paramName"];
        [customFilter setShaderTextureParams:param];
    }];
    
    return customFilter;
}

+ (RDCustomFilter *)getCustomFilerWithFxId:(int)fxId
                             filterFxArray:(NSArray *)filterFxArray
                                 timeRange:(CMTimeRange)timeRange
{
    NSString *path;
    if (fxId == 0) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource: @"RDVEUISDK" ofType :@"bundle"];
        NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
        path = [[resourceBundle resourcePath] stringByAppendingPathComponent:@"/jianji/effect_icon/shear/无"];
    }else {
        if (!filterFxArray || filterFxArray.count == 0) {
            return nil;
        }
        __block NSDictionary *itemDic;
        [filterFxArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj[@"data"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                if ([obj1[@"id"] intValue] == fxId) {
                    itemDic = obj1;
                    *stop1 = YES;
                    *stop = YES;
                }
            }];
        }];
        path = [RDHelpClass getEffectCachedFilePath:itemDic[@"file"] updatetime:itemDic[@"updatetime"]];
        NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
        if (fileCount == 0) {
            return nil;
        }
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
    }
    NSString *configPath = [path stringByAppendingPathComponent:@"config.json"];
    RDCustomFilter *customFilter = [[RDCustomFilter alloc] init];
    
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:configPath];
    NSMutableDictionary *effectDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    NSError * error = nil;
    NSString *fragPath = [path stringByAppendingPathComponent:effectDic[@"fragShader"]];
    NSString *vertPath = [path stringByAppendingPathComponent:effectDic[@"vertShader"]];
    customFilter.frag = [NSString stringWithContentsOfFile:fragPath encoding:NSUTF8StringEncoding error:&error];
    customFilter.vert = [NSString stringWithContentsOfFile:vertPath encoding:NSUTF8StringEncoding error:&error];
    customFilter.name = effectDic[@"name"];
    NSString *builtIn = effectDic[@"builtIn"];
    if ([builtIn isEqualToString:@"illusion"]) {
        customFilter.builtInType = RDBuiltIn_illusion;
    }
    customFilter.timeRange = timeRange;
    customFilter.cycleDuration = [effectDic[@"duration"] floatValue];
    NSArray *uniformParams = effectDic[@"uniformParams"];
    [uniformParams enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *type = obj[@"type"];
        NSMutableArray *paramArray = [NSMutableArray array];
        NSArray *frameArray = obj[@"frameArray"];
        [frameArray enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
            RDShaderParams *param = [[RDShaderParams alloc] init];
            param.time = [obj1[@"time"] floatValue];
            if ([type isEqualToString:@"floatArray"]) {
                param.type = UNIFORM_ARRAY;
                param.array = [NSMutableArray array];
                [obj1[@"value"] enumerateObjectsUsingBlock:^(id  _Nonnull obj2, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    [param.array addObject:[NSNumber numberWithFloat:[obj2 floatValue]]];
                }];
            }else if ([type isEqualToString:@"float"]) {
                param.type = UNIFORM_FLOAT;
                param.fValue = [[obj1[@"value"] firstObject] floatValue];
            }else if ([type isEqualToString:@"Matrix4x4"]) {
                param.type = UNIFORM_MATRIX4X4;
                RDGLMatrix4x4 matrix4;
                NSArray *valueArray = obj1[@"value"];
                matrix4.one = (RDGLVectore4){[valueArray[0][0] floatValue], [valueArray[0][1] floatValue], [valueArray[0][2] floatValue], [valueArray[0][3] floatValue]};
                matrix4.two = (RDGLVectore4){[valueArray[1][0] floatValue], [valueArray[1][1] floatValue], [valueArray[1][2] floatValue], [valueArray[1][3] floatValue]};
                matrix4.three = (RDGLVectore4){[valueArray[2][0] floatValue], [valueArray[2][1] floatValue], [valueArray[2][2] floatValue], [valueArray[2][3] floatValue]};
                matrix4.four = (RDGLVectore4){[valueArray[3][0] floatValue], [valueArray[3][1] floatValue], [valueArray[3][2] floatValue], [valueArray[3][3] floatValue]};
                param.matrix4 = matrix4;
            }else {
                param.type = UNIFORM_INT;
                param.iValue = [[obj1[@"value"] firstObject] intValue];
            }
            [paramArray addObject:param];
        }];
        [customFilter setShaderUniformParams:paramArray isRepeat:[obj[@"repeat"] boolValue] forUniform:obj[@"paramName"]];
    }];
    NSArray *textureParams = effectDic[@"textureParams"];
    [textureParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDTextureParams *param = [[RDTextureParams alloc] init];
        NSString *sourceName = obj[@"source"];
        if (sourceName.length > 0) {
            param.type = RDSample2DBufferTexture;
            param.path = [[configPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:sourceName];
            NSString *warpMode = obj[@"warpMode"];
            if ([warpMode isEqualToString:@"Repeat"]) {
                param.warpMode = RDTextureWarpModeRepeat;
            }else if ([warpMode isEqualToString:@"MirroredRepeat"]) {
                param.warpMode = RDTextureWarpModeMirroredRepeat;
            }
        }
        param.name = obj[@"paramName"];
        [customFilter setShaderTextureParams:param];
    }];
    
    return customFilter;
}

+ (RDCustomTransition *)getCustomTransitionWithId:(NSInteger)transitionId transitionArray:(NSMutableArray *)transitionArray{
    __block NSDictionary *transitionDic;
    [transitionArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj[@"data"] enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
            if ([obj1[@"id"] intValue] == transitionId) {
                transitionDic = obj1;
                *stop1 = YES;
                *stop = YES;
            }
        }];
    }];
    if (!transitionDic) {
        return nil;
    }
    NSString *file = transitionDic[@"file"];
    if ([file.pathExtension hasPrefix:@"zip"]) {
        NSString *path = [RDHelpClass getTransitionCachedFilePath:transitionDic[@"file"] updatetime:transitionDic[@"updatetime"]];
        NSInteger fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] count];
        if (fileCount == 0) {
            return nil;
        }
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
        NSString *configPath = [path stringByAppendingPathComponent:@"config.json"];
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:configPath];
        NSMutableDictionary *configDic = [RDHelpClass objectForData:jsonData];
        jsonData = nil;
        
        RDCustomTransition *transition = [[RDCustomTransition alloc] init];
        NSError * error = nil;
        NSString *fragPath = [path stringByAppendingPathComponent:configDic[@"fragShader"]];
        NSString *vertPath = [path stringByAppendingPathComponent:configDic[@"vertShader"]];
        transition.frag = [NSString stringWithContentsOfFile:fragPath encoding:NSUTF8StringEncoding error:&error];
        transition.vert = [NSString stringWithContentsOfFile:vertPath encoding:NSUTF8StringEncoding error:&error];
        transition.name = configDic[@"name"];
        
        NSArray *uniformParams = configDic[@"uniformParams"];
        [uniformParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *type = obj[@"type"];
            NSDictionary *frameDic = [obj[@"frameArray"] firstObject];
            RDTranstionShaderParams *param = [[RDTranstionShaderParams alloc] init];
            if ([type isEqualToString:@"floatArray"]) {
                param.type = UNIFORM_ARRAY;
                param.array = [NSMutableArray array];
                [frameDic[@"value"] enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                    [param.array addObject:[NSNumber numberWithFloat:[obj1 floatValue]]];
                }];
            }else if ([type isEqualToString:@"float"]) {
                param.type = UNIFORM_FLOAT;
                param.fValue = [[frameDic[@"value"] firstObject] floatValue];
            }else if ([type isEqualToString:@"Matrix4x4"]) {
                param.type = UNIFORM_MATRIX4X4;
                RDGLMatrix4x4 matrix4;
                NSArray *valueArray = frameDic[@"value"];
                matrix4.one = (RDGLVectore4){[valueArray[0][0] floatValue], [valueArray[0][1] floatValue], [valueArray[0][2] floatValue], [valueArray[0][3] floatValue]};
                matrix4.two = (RDGLVectore4){[valueArray[1][0] floatValue], [valueArray[1][1] floatValue], [valueArray[1][2] floatValue], [valueArray[1][3] floatValue]};
                matrix4.three = (RDGLVectore4){[valueArray[2][0] floatValue], [valueArray[2][1] floatValue], [valueArray[2][2] floatValue], [valueArray[2][3] floatValue]};
                matrix4.four = (RDGLVectore4){[valueArray[3][0] floatValue], [valueArray[3][1] floatValue], [valueArray[3][2] floatValue], [valueArray[3][3] floatValue]};
                param.matrix4 = matrix4;
            }else {
                param.type = UNIFORM_INT;
                param.iValue = [[frameDic[@"value"] firstObject] intValue];
            }
            [transition setShaderUniformParams:param forUniform:obj[@"paramName"]];
        }];
        
        NSArray *textureParams = configDic[@"textureParams"];
        [textureParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RDTranstionTextureParams *param = [[RDTranstionTextureParams alloc] init];
            NSString *sourceName = obj[@"source"];
            if (sourceName.length > 0) {
                param.type = RDSample2DBufferTexture;
                param.path = [[configPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:sourceName];
                NSString *warpMode = obj[@"warpMode"];
                if ([warpMode isEqualToString:@"Repeat"]) {
                    param.warpMode = RDTextureWarpModeRepeat;
                }else if ([warpMode isEqualToString:@"MirroredRepeat"]) {
                    param.warpMode = RDTextureWarpModeMirroredRepeat;
                }
            }
            param.name = obj[@"paramName"];
            [transition setShaderTextureParams:param];
        }];
        return transition;
    }
    RDCustomTransition *transition = [[RDCustomTransition alloc] init];
    NSError * error = nil;
    NSString *fragPath = [[kTransitionFolder stringByAppendingPathComponent:transitionDic[@"name"]] stringByAppendingPathExtension:[file pathExtension]];
    transition.frag = [NSString stringWithContentsOfFile:fragPath encoding:NSUTF8StringEncoding error:&error];
    
    return transition;
}

+ (RDCustomTransition *)getCustomTransitionWithJsonPath:(NSString *)configPath {
    NSString *path = [configPath stringByDeletingLastPathComponent];
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:configPath];
    NSMutableDictionary *configDic = [RDHelpClass objectForData:jsonData];
    jsonData = nil;
    
    RDCustomTransition *transition = [[RDCustomTransition alloc] init];
    NSError * error = nil;
    NSString *fragPath = [path stringByAppendingPathComponent:configDic[@"fragShader"]];
    NSString *vertPath = [path stringByAppendingPathComponent:configDic[@"vertShader"]];
    transition.frag = [NSString stringWithContentsOfFile:fragPath encoding:NSUTF8StringEncoding error:&error];
    transition.vert = [NSString stringWithContentsOfFile:vertPath encoding:NSUTF8StringEncoding error:&error];
    transition.name = configDic[@"name"];
    
    NSArray *uniformParams = configDic[@"uniformParams"];
    [uniformParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *type = obj[@"type"];
        NSDictionary *frameDic = [obj[@"frameArray"] firstObject];
        RDTranstionShaderParams *param = [[RDTranstionShaderParams alloc] init];
        if ([type isEqualToString:@"floatArray"]) {
            param.type = UNIFORM_ARRAY;
            param.array = [NSMutableArray array];
            [frameDic[@"value"] enumerateObjectsUsingBlock:^(id  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
                [param.array addObject:[NSNumber numberWithFloat:[obj1 floatValue]]];
            }];
        }else if ([type isEqualToString:@"float"]) {
            param.type = UNIFORM_FLOAT;
            param.fValue = [[frameDic[@"value"] firstObject] floatValue];
        }else if ([type isEqualToString:@"Matrix4x4"]) {
            param.type = UNIFORM_MATRIX4X4;
            RDGLMatrix4x4 matrix4;
            NSArray *valueArray = frameDic[@"value"];
            matrix4.one = (RDGLVectore4){[valueArray[0][0] floatValue], [valueArray[0][1] floatValue], [valueArray[0][2] floatValue], [valueArray[0][3] floatValue]};
            matrix4.two = (RDGLVectore4){[valueArray[1][0] floatValue], [valueArray[1][1] floatValue], [valueArray[1][2] floatValue], [valueArray[1][3] floatValue]};
            matrix4.three = (RDGLVectore4){[valueArray[2][0] floatValue], [valueArray[2][1] floatValue], [valueArray[2][2] floatValue], [valueArray[2][3] floatValue]};
            matrix4.four = (RDGLVectore4){[valueArray[3][0] floatValue], [valueArray[3][1] floatValue], [valueArray[3][2] floatValue], [valueArray[3][3] floatValue]};
            param.matrix4 = matrix4;
        }else {
            param.type = UNIFORM_INT;
            param.iValue = [[frameDic[@"value"] firstObject] intValue];
        }
        [transition setShaderUniformParams:param forUniform:obj[@"paramName"]];
    }];
    
    NSArray *textureParams = configDic[@"textureParams"];
    [textureParams enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RDTranstionTextureParams *param = [[RDTranstionTextureParams alloc] init];
        NSString *sourceName = obj[@"source"];
        if (sourceName.length > 0) {
            param.type = RDSample2DBufferTexture;
            param.path = [[configPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:sourceName];
            NSString *warpMode = obj[@"warpMode"];
            if ([warpMode isEqualToString:@"Repeat"]) {
                param.warpMode = RDTextureWarpModeRepeat;
            }else if ([warpMode isEqualToString:@"MirroredRepeat"]) {
                param.warpMode = RDTextureWarpModeMirroredRepeat;
            }
        }
        param.name = obj[@"paramName"];
        [transition setShaderTextureParams:param];
    }];
    return transition;
}

#pragma mark - 添加logo水印及片尾水印
+ (void)addWatermarkToVideoCoreSDK:(RDVECore *)videoCoreSDK
                      totalDration:(float)totalDration
                        exportSize:(CGSize)exportSize
                      exportConfig:(ExportConfiguration *)exportConfig
{
    if(!exportConfig.waterDisabled){
        if(exportConfig.waterImage){
            NSFileManager *fm = [NSFileManager defaultManager];
            NSError *error = nil;
            if(![fm fileExistsAtPath:kWatermarkFolder]){
                [fm createDirectoryAtPath:kWatermarkFolder withIntermediateDirectories:YES attributes:nil error:&error];
            }
            UIImage *logoWatermarkImage = exportConfig.waterImage;
            NSURL *url = [NSURL fileURLWithPath:[kWatermarkFolder stringByAppendingPathComponent:@"logoWatermark.png"]];
            [UIImagePNGRepresentation(logoWatermarkImage) writeToURL:url atomically:YES];
            
            RDWatermark *watermark = [[RDWatermark alloc] init];
            watermark.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(totalDration, TIMESCALE));
            watermark.vvAsset.type = RDAssetTypeImage;
            watermark.vvAsset.fillType = RDImageFillTypeFit;
            watermark.vvAsset.url = url;
            CGRect rect = CGRectMake(0, 0, logoWatermarkImage.size.width/exportSize.width, logoWatermarkImage.size.height/exportSize.height);
            switch (exportConfig.waterPosition) {
                case WATERPOSITION_LEFTBOTTOM:
                    rect.origin.y = 1.0 - rect.size.height;
                    break;
                case WATERPOSITION_RIGHTTOP:
                    rect.origin.x = 1.0 - rect.size.width;
                    break;
                case WATERPOSITION_RIGHTBOTTOM:
                    rect.origin.x = 1.0 - rect.size.width;
                    rect.origin.y = 1.0 - rect.size.height;
                    break;
                default:
                    break;
            }
            watermark.vvAsset.rectInVideo = rect;
            watermark.vvAsset.timeRange = watermark.timeRange;
            videoCoreSDK.logoWatermark = watermark;
        }
    }
    //是否添加片尾
    if(!exportConfig.endPicDisabled){
        [videoCoreSDK addEndLogoMark:[UIImage imageWithContentsOfFile:exportConfig.endPicImagepath] userName:exportConfig.endPicUserName showDuration:exportConfig.endPicDuration fadeDuration:exportConfig.endPicFadeDuration];
    }
}

@end
