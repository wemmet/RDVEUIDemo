//
//  RDCloudMusicViewController.h
//  RDVEUISDK
//

#import <UIKit/UIKit.h>
#import "RDScene.h"

typedef void(^SelectCloudMusicBlock)(RDMusic *music);

@interface RDCloudMusicViewController : UIViewController
@property (nonatomic,copy)NSString *cloudMusicResourceURL;
@property (nonatomic,copy)SelectCloudMusicBlock selectCloudMusic;
@property (nonatomic,assign)NSInteger   selectedIndex;
@property(copy) void(^backBlock)(void);
@end
