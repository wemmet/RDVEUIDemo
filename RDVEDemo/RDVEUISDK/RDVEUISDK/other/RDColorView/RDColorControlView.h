//
//  RDColorView.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2019/12/26.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RDColorControlViewDelegate <NSObject>
@optional

- (void)colorChanged:(UIColor *)color index:(NSInteger)index colorControlView:(UIView *)colorControlView;

@end

@interface RDColorControlView : UIView

@property (nonatomic, strong)NSArray *colorArray;

@property (nonatomic,weak) id<RDColorControlViewDelegate> delegate;

- (void)refreshFrame:(CGRect)frame;

@end
