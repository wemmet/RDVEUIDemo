//
//  RDCloudMusicItemViewController.h


#import <UIKit/UIKit.h>
#import "RDScene.h"

@protocol RDCloudMusicItemViewControllerDelegate <NSObject>
- (void)getMusicFile:(RDMusic *)music;

@end

typedef void(^RDDoneContentViewBlock)(RDMusic *music);

@interface RDCloudMusicItemViewController : UIViewController
{
    UITableView                 *_localMusicTableView;
}
@property (nonatomic, copy) NSString *category;
@property (nonatomic, assign) int vcIndex;
@property (nonatomic, strong) NSArray *sourceList;

@property (nonatomic,assign)  BOOL isCloud;     //是否云音乐

@property (nonatomic, copy) NSString * id;
@property (nonatomic, assign) BOOL  isSound;                //是否 音效
@property (nonatomic,copy)NSString *soundMusicResourceURL;

@property (nonatomic, assign)BOOL    isPlaying;
@property (nonatomic, assign)BOOL    isDisappear;

@property (nonatomic, assign)BOOL    isLocal;

@property (nonatomic, weak)id<RDCloudMusicItemViewControllerDelegate> musicItemDelegate;
/**点击添加时触发block回调
 */
@property (nonatomic, copy) RDDoneContentViewBlock doneBlock;
/*停止播放音乐
 */
- (void)stopPlayAudio;

@property (nonatomic,assign) float fheight;

//动画效果
@property (nonatomic,assign) bool   isStart;
@property (nonatomic,assign) int    animationCount;
@end
