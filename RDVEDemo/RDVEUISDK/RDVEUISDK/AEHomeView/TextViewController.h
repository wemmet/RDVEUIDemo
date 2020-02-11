//
//  TextViewController.h
//  RDVEUISDK
//
//  Created by apple on 2018/10/22.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDScene.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TextViewControllerDelegate <NSObject>

- (void)editTextFinished:(NSInteger)fontIndex;

@end

@interface TextViewController : UIViewController

@property (nonatomic, strong) RDJsonText *textSource;

/** 文字序号
 */
@property (nonatomic, assign) NSInteger textIndex;

/** 建议文字内容
 */
@property (nonatomic, copy) NSString *suggestionStr;

/** 最大文字数
 */
@property (nonatomic, assign) NSInteger maxNum;

/** 最大行数
 */
@property (nonatomic, assign) NSInteger lineNum;

/** 模板字体
 */
@property (nonatomic, copy) NSString *templateFontName;
@property (nonatomic, copy) NSString *templateFontPath;

@property (nonatomic, weak) id<TextViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
