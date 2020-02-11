//
//  toni_editCollageView.h
//  RDVEUISDK
//
//  Created by apple on 2020/1/8.
//  Copyright © 2020 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDPasterTextView.h"

/**水印位置
*/
typedef NS_ENUM(NSInteger,AdjustType){
    Adjust_Brightness,      //亮度
    Adjust_Contrast,        //对比度
    Adjust_Saturation,      //饱和度
    Adjust_Sharpness,       //锐度
    Adjust_WhiteBalance,    //色温
    Adjust_Vignette,        //暗角
} ;

NS_ASSUME_NONNULL_BEGIN

@protocol toni_editCollageViewDelegate <NSObject>

//隐藏控件
-(void)hiddenCollageBarItem:( RDPIPFunctionType ) pipType isSave:(BOOL) isSave;

@end

@interface toni_editCollageView : UIView

@property(nonatomic,strong)RDVECore *videoCoreSDK;      //core
@property(strong,nonatomic)   RDWatermark  *currentCollage;//当前选中画中画
/** 媒体
 */
@property (nonatomic,strong) VVAsset*  currentVvAsset;

@property(nonatomic,strong)RDPasterTextView *pasterView;

@property (nonatomic,strong)UIScrollView    *featuresScroll;

@property(nonatomic,weak)id<toni_editCollageViewDelegate>   delegate;

@property (nonatomic, strong)RDNavigationViewController *navigationController;

+ (toni_editCollageView *)initWithFrame:(CGRect)frame atVVAsset:(VVAsset *)  vvAsset;

@end

NS_ASSUME_NONNULL_END
