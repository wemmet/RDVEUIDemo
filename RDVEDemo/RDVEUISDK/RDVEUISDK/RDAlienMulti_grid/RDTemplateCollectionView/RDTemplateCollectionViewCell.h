//
//  RDTemplateCollectionViewCell.h
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDMultiDifferentFile : NSObject
@property(nonatomic,strong)RDFile * file;
@property (nonatomic, assign) NSMutableArray *pointsInVideoArray;

@property (nonatomic, assign) CGFloat          scale;               // scale relative to the touch points in screen coordinates
@property (nonatomic, assign) CGPoint          translation;
@property (nonatomic, assign) CGPoint          origin;
@property (nonatomic, assign) int              RotateGrade;         //旋转等级
@property (nonatomic, strong) UIImageView          *thumbnailImage;         //旋转等级

/**在video中的范围。默认为CGRectMake(0, 0, 1, 1)
 * (0, 0)为左上角 (1, 1)为右下角
 * rectInVideo与pointsInVideoArray只有一个有效，以最后设置的为准
 * 设置媒体动画后，该属性及pointsInVideoArray属性均无效，以动画中的rect或pointsArray值为准
 */
@property (nonatomic, assign) CGRect           rectInVideo;
@property (nonatomic, assign) CGRect           crop;
@property (nonatomic, assign) BOOL             isChangedCrop;

@property (nonatomic, assign) int              number;

@end

@class RDTemplateCollectionViewCell;
@protocol RDTemplateCollectionViewCellDelegate <NSObject>
- (void)longPressAction:(UIPanGestureRecognizer *)longPress;

@end

@interface RDTemplateCollectionViewCell : UICollectionViewCell
{
    bool isFistoriginal;
    // 缩放手势
    UIPinchGestureRecognizer *pinchGestureRecognizer;
    
    // 移动手势
    UIPanGestureRecognizer *panGestureRecognizer;
    
    CAShapeLayer *maskBorderLayer;
    CAShapeLayer *selectMaskBorderLayer;
}

@property (nonatomic, assign) CGRect           originalRect;
@property (nonatomic, assign) CGRect           crop;
@property (nonatomic, assign) RDMultiDifferentFile * currentMultiDifferentFile;

@property (nonatomic, assign) CGSize originalThumbnailSize;

/** 是否被选中
 */
@property (nonatomic, assign) BOOL isSelected;
//@property (nonatomic, assign) BOOL isFull;

//选中 状态
@property (nonatomic, strong) UIImageView *selectImage;
//未选中状态
@property (nonatomic, strong) UIImageView *noSelectImage;

//视频缩略图
@property (nonatomic, strong) UIImageView *thumbnailIV;

//可继续录制
//@property (nonatomic, assign) BOOL isContinueRecord;

@property (nonatomic, weak) id<RDTemplateCollectionViewCellDelegate> delegate;
//手势添加
- (void)addGestureRecognizerToView;
//调整选中 和为选中状态 的显示框
-(void)adjSelectImage:(CGSize) size;
//设置选中
-(void)setSelect:(bool) isSelect;
//取消选中和未选中状态
-(void)noSelect;
//恢复 调整
-(void)setImageScale;
//设置旋转角度
-(void)setImageViewRotate:(float) rotate;

//异形相关设置t
@property (nonatomic, strong) NSMutableArray *trackPoints;

//@property (nonatomic, strong) NSMutableArray *pointsInVideoArray;
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, assign) float cornerRadius;
@property (nonatomic, assign) float borderWidth;
@property (nonatomic, strong) UIColor *borderColor;

- (void)setMask;
@end
