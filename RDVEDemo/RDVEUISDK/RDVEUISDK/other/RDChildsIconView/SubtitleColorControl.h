//
//  SubtitleColorControl.h
//  RDVEUISDK
//
//  Created by apple on 2019/4/9.
//  Copyright © 2019年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SubtitleColorControlDelegate <NSObject>
@optional

-(void)SubtitleColorChanged:(UIColor *) color Index:(int) index View:(UIControl *) SELF ;

@end

@interface SubtitleColorControl : UIControl
-(id)initWithFrame:(CGRect) frame Colors:(NSArray *) colors  CurrentColor:(UIColor*) currentColor atisDefault:(BOOL) isDefault;
-(void)setValue:(UIColor *) color;
@property (nonatomic, strong)   NSMutableArray<UIColor *>               *colorsArr;
@property (nonatomic, weak)     NSObject<SubtitleColorControlDelegate>  *delegate;
@property(nonatomic,assign)     UIColor                                 *currentColor;
@property(nonatomic,assign)     int                                 currentColorIndex;

@property(nonatomic,assign)     bool                                isDefault; //默认白色为原始色
@end
