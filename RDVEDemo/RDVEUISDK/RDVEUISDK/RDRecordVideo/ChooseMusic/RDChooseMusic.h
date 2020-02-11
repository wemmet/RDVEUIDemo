//
//  RDChooseMusic.h
//  RDVEUISDK
//
//  Created by apple on 2019/6/20.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDScene.h"

typedef void(^SelectCloudMusicBlock)(RDMusic *music);

@interface RDChooseMusic : UIViewController

@property (nonatomic,copy)NSString *cloudMusicResourceURL;

@property (nonatomic,copy)SelectCloudMusicBlock selectCloudMusic;

@property (nonatomic,assign)NSInteger   selectedIndex;
@property(copy) void(^backBlock)(void);

@property(nonatomic,assign)BOOL isNOSound;    //是否音效
@property(nonatomic,assign)BOOL isLocal; //是否需要本地


@property (nonatomic,copy)NSString *soundMusicResourceURL;
@property (nonatomic,copy)NSString *soundMusicTypeResourceURL;

-(void)setTitile:(NSString *) title;

@end
