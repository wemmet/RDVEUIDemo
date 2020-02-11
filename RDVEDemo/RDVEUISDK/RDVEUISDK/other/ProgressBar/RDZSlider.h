//
//  RDZSlider.h
//  RDVEUISDK
//
//  Created by 周晓林 on 2016/12/6.
//  Copyright © 2016年 RDVEUISDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDZSlider : UISlider
- (void)setHighlightImage:(UIImage *)highlightImage;

@property (nonatomic, assign) BOOL isAETemplate;
@property (nonatomic, assign) BOOL isAdj;

@end
