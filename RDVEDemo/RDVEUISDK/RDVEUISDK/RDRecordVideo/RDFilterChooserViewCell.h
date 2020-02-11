//
//  RDFilterChooserViewCell.h
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//

#import <UIKit/UIKit.h>
#import "RDCameraManager.h"

#import "CircleView.h"
@class RDRecordGPUImageFilter;
@interface RDFilterChooserViewCell : UIView

@property (nonatomic , strong) UILabel *titleLabel;
@property (nonatomic , strong) UIImageView* backgroudView;
@property (nonatomic , strong) UIColor *circleColor;
@property (nonatomic , strong) CircleView* circleView;
@property (nonatomic , assign) BOOL     isDowning;

- (void)setFilter:(RDFilter *)filter;

- (RDFilter *)getFilter;
- (void) setImage:(NSString*)item name:(NSString *)name;

- (void)setState:(UIControlState)state value:(float )value;

@end

