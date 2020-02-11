//
//  RDEditTextViewController.h
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/20.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDTextAnimateInfo : NSObject

/** 文字开始显示时间，格式：分:秒.毫秒
 */
@property (nonatomic, copy) NSString *startTimeStr;

/** 文字结束显示时间，格式：分:秒.毫秒
 */
@property (nonatomic, copy) NSString *endTimeStr;

/** 文字开始显示时间
 */
@property (nonatomic, assign) float startTime;

/** 文字结束显示时间
 */
@property (nonatomic, assign) float endTime;

/** 文字显示内容
 */
@property (nonatomic, copy) NSString *contentStr;

@end


@protocol RDEditTextViewControllerDelegate <NSObject>

- (void)editTextFinished:(NSString *)fontName textContent:(NSString *)textContent;

@end

@interface RDEditTextViewController : UIViewController

/** 当前显示文字内容
 */
@property (nonatomic, copy) NSString *textContent;

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

/** 当前选择字体
 */
@property (nonatomic, copy) NSString *selectedFontName;

@property (nonatomic, weak) id<RDEditTextViewControllerDelegate> delegate;

@end
