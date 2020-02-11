//
//  CustomTextPhotoViewController.h
//  RDVEUISDK
//
//  Created by emmet on 15/11/4.
//  Copyright © 2015年 emmet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "UIImageView+RDWebCache.h"
#import "CustomTextPhotoFile.h"
#import "UIImage+RDVECore.h"
#import "RDZipArchive.h"

@protocol CustomTextDelegate <NSObject>

- (void)getCustomTextImage:(UIImage *)textImage customTextPhotoFile:(CustomTextPhotoFile *)file touchUpType:(NSInteger)touchUpType change:(BOOL)flag;

- (void)getCustomTextImagePath:(NSString *)textImagePath thumbImage:(UIImage *)thumbImage customTextPhotoFile:(CustomTextPhotoFile *)file touchUpType:(NSInteger)touchUpType change:(BOOL)flag;

@end
@interface CustomTextPhotoViewController : UIViewController

@property (nonatomic,weak)id<CustomTextDelegate> delegate;
@property (nonatomic,assign)NSInteger touchUpType;
@property (nonatomic,assign)float videoProportion;

- (instancetype)init;

- (instancetype)initWithFile:(CustomTextPhotoFile *)file;

@end
