//
//  UIImage+GIF.h
//  LBGIFImage
//
//  Created by Laurin Brandner on 06.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (RDGIF)

+ (UIImage *)rd_sd_animatedGIFNamed:(NSString *)name;

+ (UIImage *)rd_sd_animatedGIFWithData:(NSData *)data;

- (UIImage *)rd_sd_animatedImageByScalingAndCroppingToSize:(CGSize)size;

+ (UIImage *)getGifThumbImageWithData:(NSData *)data time:(float)time;

@end
