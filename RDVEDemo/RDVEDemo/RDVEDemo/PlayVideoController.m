//
//  PlayVideoController.m
//  RDVEDemo
//
//  Created by emmet on 16/1/15.
//  Copyright © 2016年 RDVEDemo. All rights reserved.
//

#import "PlayVideoController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "RDVEUISDK.h"

#define PHOTO_ALBUM_NAME @"RDVEUISDKDemo"

@interface PlayVideoController ()<RDVEUISDKDelegate>
{
    UIView                  *_playerView;
    UIView                  *_syncContainer;
    
    UIButton                *_playBtn;
    UIButton                *_savePhotosAlbumBtn;
    UIButton                *_deletedBtn;
    AVPlayer                *_player;
    id                      _timeObserver;
    AVPlayerItem            *playerItem;
    UISlider                *_slider;
    
    float                   videoDuration;
    NSTimer                 *playerTimer;
}

@end

@implementation PlayVideoController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterHome:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:20];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0xffffff);
    
    
    self.navigationController.navigationBar.titleTextAttributes = attributes;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
    [_player pause];
    _player = nil;
}

- (void)applicationEnterHome:(NSNotification *)notification{
    [_player pause];
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    [_player play];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self initPlayerView];
    
    [self initPlayer];
    videoDuration = CMTimeGetSeconds(playerItem.duration);
}

- (void)initPlayer{
    NSURL * url=[NSURL fileURLWithPath:_videoPath];
    //创建item
    playerItem=[[AVPlayerItem alloc]initWithURL:url];
    //创建player
    _player=[[AVPlayer alloc]initWithPlayerItem:playerItem];
    //生成layer层
    AVPlayerLayer * layer=[AVPlayerLayer playerLayerWithPlayer:_player];
    //设置坐标
    layer.frame=_playerView.bounds;
    //把layer层加入到self.View中
    [_playerView.layer addSublayer:layer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerToEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    
    //进行播放
    [_player play];

    __weak typeof(self) myself = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:NULL usingBlock:^(CMTime time) {
        __strong typeof(self) strongSelf = myself;
        //当前播放时间
        CGFloat  currentime=CMTimeGetSeconds(time);
//        NSLog(@"当前时间：%f",currentime);
        //总时长
        
        CMTime  time1 = strongSelf->playerItem.duration;
        strongSelf->videoDuration=CMTimeGetSeconds(time1);
//        NSLog(@"总时长：%f",myself->videoDuration);
        //设置滑动条的进度
        
        float v=currentime/strongSelf->videoDuration;
        
        strongSelf->_slider.value = v;
    }];
    videoDuration = CMTimeGetSeconds(playerItem.duration);

}

- (void) playWith{
    [_player play];
}
- (void) initPlayerView{
    
    _playerView= [[UIView alloc]init];
    _playerView.frame=CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width, ([UIScreen mainScreen].bounds.size.width));
    _playerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_playerView];
    
    
    _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _playBtn.layer.cornerRadius = 5;
    _playBtn.layer.masksToBounds = YES;
    _playBtn.backgroundColor = UIColorFromRGB(0x0e0e10);
    [_playBtn setTitle:NSLocalizedString(@"播放", nil) forState:UIControlStateNormal];
    [_playBtn setTitle:NSLocalizedString(@"暂停", nil) forState:UIControlStateSelected];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [_playBtn addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playBtn];
    
    _savePhotosAlbumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _savePhotosAlbumBtn.backgroundColor = UIColorFromRGB(0x0e0e10);
    [_savePhotosAlbumBtn setTitle:NSLocalizedString(@"保存到相册", nil) forState:UIControlStateNormal];
    _savePhotosAlbumBtn.titleLabel.adjustsFontSizeToFitWidth =YES;
    [_savePhotosAlbumBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_savePhotosAlbumBtn addTarget:self action:@selector(savePhotosAlbum) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_savePhotosAlbumBtn];
    _savePhotosAlbumBtn.layer.cornerRadius = 5;
    _savePhotosAlbumBtn.layer.masksToBounds = YES;
    
    _playBtn.selected = YES;
    _playBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2-30, _playerView.frame.size.height, 60,40);
    _savePhotosAlbumBtn.frame = CGRectMake(10, _playerView.frame.size.height, 80,40);
    
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(0, _playerView.frame.origin.y + _playerView.frame.size.height + 50, _playerView.frame.size.width, 25)];
    _slider.maximumValue = 1;
    _slider.minimumValue = 0;
    _slider.backgroundColor = [UIColor clearColor];
    [_slider addTarget:self action:@selector(seektime:) forControlEvents:UIControlEventValueChanged];
    [self.view insertSubview:_slider aboveSubview:_playerView];
}

- (void) seektime: (UISlider *) sender{
    float value = sender.value;
    [playerItem seekToTime:CMTimeMakeWithSeconds(videoDuration*value, 600)];
}

- (void)playerToEnd{
    [_player seekToTime:kCMTimeZero];
    _slider.value = 0;
    _playBtn.selected = NO;
}

- (void)freshSlider:(float)value{
    _slider.value = value;
}

- (void)playVideo:(UIButton *)sender{
    sender.selected = !sender.selected;
    if(sender.selected){
        [_player play];
        
    }else{
        [_player pause];
    }
}

- (void)savePhotosAlbum{
    [self saveVideoToCameraRoll:_videoPath];
}

-(void) saveVideoToCameraRoll:(NSString *)path{
    if(_savePhotosAlbumBtn.selected){
        return;
    }
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    __weak PlayVideoController *weakSelf = self;
    
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:path] completionBlock:^(NSURL *assetURL, NSError *error){
        
        if(error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"保存提示", nil) message:NSLocalizedString(@"保存到相册失败!", nil) delegate:weakSelf cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil];
                [alert show];
            });
        }
        
        else {
            
            __block ALAssetsGroup* groupToAddTo;
            [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                   usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                       if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:PHOTO_ALBUM_NAME]) {
                                           groupToAddTo = group;
                                       }
                                   }
                                 failureBlock:^(NSError* error) {
                                 }];
            [library assetForURL:assetURL resultBlock:^(ALAsset *addAsset){
                BOOL suc=[groupToAddTo addAsset:addAsset];
                if (suc) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong PlayVideoController *strongSelf = weakSelf;
                        if( strongSelf )
                            strongSelf->_savePhotosAlbumBtn.selected = YES;
                        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"保存提示", nil) message:[NSString stringWithFormat:NSLocalizedString(@"保存到相册成功!", nil)] delegate:strongSelf cancelButtonTitle:NSLocalizedString(@"我知道了", nil) otherButtonTitles:nil];
                        [alert show];
                    });
                    
                }
            }failureBlock:^(NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"保存提示", nil) message:NSLocalizedString(@"保存到相册失败!", nil) delegate:weakSelf cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil];
                    [alert show];
                });
            }];
        }
    }];
}

- (void)dealloc {
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
