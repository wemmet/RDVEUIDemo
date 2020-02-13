//
//  BCMutableMeshTransform+DemoTransforms.h
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshTransform.h"

@interface BCMeshTransform (DemoTransforms)




+ (instancetype)curtainMeshTransformAtPoint:(CGPoint)point
                                 boundsSize:(CGSize)boundsSize;



+ (instancetype)shiverTransformWithPhase:(CGFloat)phase magnitude:(CGFloat)magnitude;

+ (instancetype)ellipseMeshTransform;

+ (instancetype)rippleMeshTransform;



/**  鱼眼效果
*
*  @param  center   鱼眼中心点
*  @param  radius   鱼眼半径
*  @param  size     画布大小
*
*  返回设置后的矩阵
*/
+ (instancetype)buldgeMeshTransformAtPoint:(CGPoint)center
                                withRadius:(CGFloat)radius
                                boundsSize:(CGSize)size;


/**  四角定位，也称异形 - 由任意四个点构成
*
*  @param  topLeft      左上点坐标
*  @param  topRight     右上点坐标
*  @param  bottomLeft   左下点坐标
*  @param  bottomRight  右下点坐标
*  @param  boundsSize   画布大小
*
*  返回设置后的矩阵
*/
+ (instancetype)cornerMeshTransformAtTopLeftPoint:(CGPoint)topLeft
                                   TopRight:(CGPoint)topRight
                                 BottomLeft:(CGPoint)bottomLeft
                                BottomRight:(CGPoint)bottomRight
                                 boundsSize:(CGSize)boundsSize;


/**  贝塞尔曲线，一共12个点，4个顶点，8个切点（每个顶点都有两个切点）
*
*  @param  topLeft          上左顶点
*  @param  topLeftT0        上左切点 --- 上切点
*  @param  topRightT1       上右切点 --- 上切点
*
*  @param  topRight         上右顶点
*  @param  topRightR0       上右切点 --- 右切点
*  @param  bottomRightR1    下右切点 --- 右切点
*
*  @param  bottomRight      下右顶点
*  @param  bottomRightB1    下右切点 --- 下切点
*  @param  bottomLeftB0     下右切点 --- 下切点
*
*  @param  bottomLeft       下左顶点
*  @param  bottomLeftL1     下左切点 --- 左切点
*  @param  topLeftL0        上左切点 --- 左切点
*
*  @param  boundsSize       画布的大小
*
*  返回设置后的矩阵
*/

+ (instancetype)bezierMeshTransformAtTopLeftPoint:(CGPoint)topLeft
                                     TopLeftPointT0:(CGPoint)topLeftT0
                                  TopLeftPointL0:(CGPoint)topLeftL0
                                    TopRightPoint:(CGPoint)topRight
                                TopRightT1:(CGPoint)topRightT1
                                TopRightR0:(CGPoint)topRightR0
                                       BottomLeft:(CGPoint)bottomLeft
                                 BottomLeftB0:(CGPoint)bottomLeftB0
                                 BottomLeftL1:(CGPoint)bottomLeftL1
                                      BottomRight:(CGPoint)bottomRight
                                BottomRightB1:(CGPoint)bottomRightB1
                                  BottomRightR1:(CGPoint)bottomRightR1;

@end
