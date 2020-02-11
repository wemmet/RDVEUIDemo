//
//  RDLocalMusicViewController.h
//  RDVEUISDK
//
//  Created by emmet on 2017/5/18.
//  Copyright © 2017年 RDVEUISDK. All rights reserved.
//

#import "RDScene.h"
typedef void(^SelectLocalMusicBlock)(RDMusic *music);

@interface RDLocalMusicViewController : UIViewController
{
    UITableView                 *_localMusicTableView;
}
//@property(nonatomic, assign) float maxDuration;//最大选择时长,默认为0不限制
@property(copy) SelectLocalMusicBlock selectLocalMusicBlock;
@property(copy) void(^backBlock)(void);

@end
