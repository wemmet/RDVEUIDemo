//
//  RDTemplateCollectionViewCell.m
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDTemplateCollectionViewCell.h"
#define MAXSCALE    10.0

#define M_PI       3.14159265358979323846   // pi


@implementation RDMultiDifferentFile
- (instancetype)init{
    self = [super init];
    if(self){
        self.scale                  = 1.0;
        self.translation            = CGPointZero;
        self.origin                 = CGPointZero;
        self.rectInVideo            = CGRectZero;
        self.crop                   = CGRectZero;
        self.isChangedCrop          = 0.0;
        self.number                 = 0;
    }
    return self;
}

@end

@implementation RDTemplateCollectionViewCell

- (void)setOriginalRect:(CGRect)originalRect
{
    if( isFistoriginal )
    {
        isFistoriginal = false;
        _originalRect = originalRect;
    }
}

-(void)noSelect
{
    _selectImage.hidden = YES;
    _noSelectImage.hidden = YES;
    _isSelected = NO;
}

-(void)setSelect:(bool) isSelect
{
    if( isSelect )
    {
        _selectImage.hidden = NO;
        _noSelectImage.hidden = YES;
        _isSelected = YES;
    }
    else
    {
        _selectImage.hidden = YES;
        _noSelectImage.hidden = NO;
        _isSelected = NO;
    }
}

-(void)adjSelectImage:(CGSize) size
{
    _selectImage.frame = CGRectMake(0, 0, size.width, size.height);
    if( self.trackPoints.count > 0 )
    {
        [_selectImage removeFromSuperview];
        _selectImage = nil;
        _selectImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        _selectImage.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        [self.contentView addSubview:_selectImage];
        _selectImage.hidden = !_isSelected;
        
        UIBezierPath* path = [[UIBezierPath alloc] init];
        for (int i = 0; i < [self.trackPoints count]; i++) {
            CGPoint pathPoint = [[self.trackPoints objectAtIndex:i] CGPointValue];
            if (i == 0) {
                [path moveToPoint:pathPoint];
            }else{
                [path addLineToPoint:pathPoint];
            }
            
            if (i == [self.trackPoints count]-1) {
                pathPoint = [[self.trackPoints objectAtIndex:0] CGPointValue];
                [path addLineToPoint:pathPoint];
            }
        }
        CAShapeLayer* shape = [CAShapeLayer layer];
        shape.path = path.CGPath;
        shape.strokeColor =  Main_Color.CGColor;
        shape.lineWidth = 6.0;
        shape.frame=self.bounds;
        shape.fillColor = [UIColor clearColor].CGColor;  //设置填充颜色
        shape.backgroundColor = [UIColor clearColor].CGColor;  //设置背景颜色
        [_selectImage.layer addSublayer:shape];
    }
    _noSelectImage.frame = CGRectMake(0, 0, size.width, size.height);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        isFistoriginal = true;
        _thumbnailIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _thumbnailIV.backgroundColor = UIColorFromRGB(0x000000);
        _thumbnailIV.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailIV.clipsToBounds = YES;
        [self.contentView addSubview:_thumbnailIV];
        
        self.clipsToBounds = YES;
        self.backgroundColor = UIColorFromRGB(0x000000);
//        self.contentView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
//        _isContinueRecord = NO;
        
        _selectImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _selectImage.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        if( self.trackPoints.count == 0 )
        {
            _selectImage.layer.borderColor = Main_Color.CGColor;
            _selectImage.layer.borderWidth = 3.0;
        }
        [self.contentView addSubview:_selectImage];
        
        _noSelectImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _noSelectImage.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
        [self.contentView addSubview:_noSelectImage];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
}

//手势
- (void) addGestureRecognizerToView
{
    [_thumbnailIV setUserInteractionEnabled:YES];
    [_thumbnailIV setMultipleTouchEnabled:YES];
    
    // 缩放手势
    [_thumbnailIV removeGestureRecognizer:pinchGestureRecognizer];
    pinchGestureRecognizer = nil;
    pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
    [_thumbnailIV addGestureRecognizer:pinchGestureRecognizer];
    
    // 移动手势
    [_thumbnailIV removeGestureRecognizer:panGestureRecognizer];
    panGestureRecognizer = nil;
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    panGestureRecognizer.maximumNumberOfTouches = 1;
    [_thumbnailIV addGestureRecognizer:panGestureRecognizer];
}

-(void)setImageViewRotate:(float) rotate
{
    _currentMultiDifferentFile.RotateGrade = rotate/90.0;
    _currentMultiDifferentFile.file.rotate = 360 -rotate;
    _thumbnailIV.transform = CGAffineTransformMakeRotation( M_PI/180*rotate );
}

-(void)setImageScale
{
    if( _currentMultiDifferentFile.isChangedCrop )
    {
        float width = self.frame.size.width/_currentMultiDifferentFile.crop.size.width;
        float height =  self.frame.size.height/_currentMultiDifferentFile.crop.size.height;
        float x = -_currentMultiDifferentFile.crop.origin.x * width;
        float y = -_currentMultiDifferentFile.crop.origin.y * height;
        
        _thumbnailIV.frame = CGRectMake(x, y, width, height);
    }
}

-(void)SetScale:(float) scale atView:(UIView *) view
{
    NSLog(@"scale:%.2f",scale);
    view.transform = CGAffineTransformScale(view.transform, scale, scale);
    if (view.frame.size.width < _originalThumbnailSize.width || view.frame.size.height < _originalThumbnailSize.height)
    {
        //让图片无法缩得比原图小
        view.frame = CGRectMake((self.bounds.size.width - _originalThumbnailSize.width)/2.0, (self.bounds.size.height - _originalThumbnailSize.height)/2.0, _originalThumbnailSize.width, _originalThumbnailSize.height);
    }
    else if (view.frame.size.width > MAXSCALE * _originalThumbnailSize.width || view.frame.size.height > MAXSCALE * _originalThumbnailSize.height)
    {
        //不能超过原来的2倍
        view.frame = CGRectMake((self.bounds.size.width - _originalThumbnailSize.width*MAXSCALE)/2.0, (self.bounds.size.height - _originalThumbnailSize.height*MAXSCALE)/2.0, _originalThumbnailSize.width*MAXSCALE, _originalThumbnailSize.height*MAXSCALE);
    }
}

// 处理缩放手势
- (void) pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    UIView *view = pinchGestureRecognizer.view;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        _currentMultiDifferentFile.scale = pinchGestureRecognizer.scale;
        [self SetScale:pinchGestureRecognizer.scale atView:view];
        
        pinchGestureRecognizer.scale = 1;
    }else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        _currentMultiDifferentFile.isChangedCrop = YES;
        _currentMultiDifferentFile.crop = [self getCropRect];
        _crop = _currentMultiDifferentFile.crop;
    }
}

// 处理拖拉手势
- (void) panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = panGestureRecognizer.view;
    
    if (_delegate && [_delegate respondsToSelector:@selector(longPressAction:)]) {
        [_delegate longPressAction:panGestureRecognizer];
    }
    
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panGestureRecognizer translationInView:view.superview];
//        CGPoint point = [panGestureRecognizer locationInView:_collectionView];
        [view setCenter:(CGPoint){view.center.x + translation.x, view.center.y + translation.y}];
        CGRect tempFrame = view.frame;
//        if (tempFrame.origin.x > 0) {
//            tempFrame.origin.x = 0;
//        }
//        if (tempFrame.origin.y > 0) {
//            tempFrame.origin.y = 0;
//        }
//        if (tempFrame.origin.x + tempFrame.size.width < self.bounds.size.width) {
//            tempFrame.origin.x = self.bounds.size.width - tempFrame.size.width;
//        }
//        if (tempFrame.origin.y + tempFrame.size.height < self.bounds.size.height) {
//            tempFrame.origin.y = self.bounds.size.height - tempFrame.size.height;
//        }
        view.frame = tempFrame;
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        {
            CGPoint translation = [panGestureRecognizer translationInView:view.superview];
            [view setCenter:(CGPoint){view.center.x + translation.x, view.center.y + translation.y}];
            CGRect tempFrame = view.frame;
            if (tempFrame.origin.x > 0) {
                tempFrame.origin.x = 0;
            }
            if (tempFrame.origin.y > 0) {
                tempFrame.origin.y = 0;
            }
            if (tempFrame.origin.x + tempFrame.size.width < self.bounds.size.width) {
                tempFrame.origin.x = self.bounds.size.width - tempFrame.size.width;
            }
            if (tempFrame.origin.y + tempFrame.size.height < self.bounds.size.height) {
                tempFrame.origin.y = self.bounds.size.height - tempFrame.size.height;
            }
            view.frame = tempFrame;
            [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
        }
        
        
        _currentMultiDifferentFile.isChangedCrop = YES;
        _currentMultiDifferentFile.crop = [self getCropRect];
        _crop = _currentMultiDifferentFile.crop;
    }
}

- (CGRect)getCropRect {
    
    CGRect cropRect = CGRectZero;
    
    NSLog(@"x:%.2f",self.thumbnailIV.frame.origin.x);
    NSLog(@"y:%.2f",self.thumbnailIV.frame.origin.y);
    
    cropRect.origin.x = fabs(self.thumbnailIV.frame.origin.x / self.thumbnailIV.frame.size.width);
    cropRect.origin.y = fabs(self.thumbnailIV.frame.origin.y / self.thumbnailIV.frame.size.height);
    
    cropRect.size.width = self.frame.size.width / self.thumbnailIV.frame.size.width;
    cropRect.size.height = self.frame.size.height / self.thumbnailIV.frame.size.height;
    
    return cropRect;
}

- (UIBezierPath *)setMask:(UIView *) view atBorderColor:(UIColor *) BorderColor atBorderWidth:(float) BorderWidth atmaskLayer:(CAShapeLayer *) maskLayer
{
    UIBezierPath * path =  [[UIBezierPath alloc] init];
    if (self.cornerRadius>0) {
        NSMutableArray *muaarray = [NSMutableArray array];
        for (int i = 0; i < [self.trackPoints count]; i++) {
            CGPoint pointStart, pointEnd;
            if (i < [self.trackPoints count]-1) {
                pointStart = [[self.trackPoints objectAtIndex:i] CGPointValue];
                pointEnd = [[self.trackPoints objectAtIndex:i+1] CGPointValue];
            }else {
                pointStart = [[self.trackPoints objectAtIndex:i] CGPointValue];
                pointEnd = [[self.trackPoints objectAtIndex:0] CGPointValue];
            }
            [muaarray addObject:[NSValue valueWithCGPoint:pointStart]];
            
            if (pointStart.x == pointEnd.x) {
                BOOL boolY = pointEnd.y-pointStart.y>0;
                pointStart.y = pointStart.y + self.cornerRadius*(boolY? 1 : -1);
                pointEnd.y = pointEnd.y - self.cornerRadius*(boolY? 1 : -1);
                
            }else if (pointStart.y == pointEnd.y){
                BOOL boolX = pointEnd.x-pointStart.x>0;
                pointStart.x = pointStart.x + self.cornerRadius*(boolX? 1 : -1);
                pointEnd.x = pointEnd.x - self.cornerRadius*(boolX? 1 : -1);
            }else{
                float tempL = (pointEnd.y-pointStart.y)/(pointEnd.x-pointStart.x);
                float cutX = sqrtf(self.cornerRadius*self.cornerRadius/(1+tempL*tempL));
                float cutY = fabsf(cutX*tempL);
                
                BOOL boolX = pointEnd.x-pointStart.x>0;
                BOOL boolY = pointEnd.y-pointStart.y>0;
                
                pointStart.x = pointStart.x + cutX*(boolX? 1 : -1);
                pointStart.y = pointStart.y + cutY*(boolY? 1 : -1);
                pointEnd.x = pointEnd.x - cutX*(boolX? 1 : -1);
                pointEnd.y = pointEnd.y - cutY*(boolY? 1 : -1);
            }
            
            [muaarray addObject:[NSValue valueWithCGPoint:pointStart]];
            [muaarray addObject:[NSValue valueWithCGPoint:pointEnd]];
        }
        
        //calculate the control point of every corner.
        NSMutableArray *arrayM = [NSMutableArray array];
        for (int i = 1; i < [muaarray count]; i = i+3) {
            CGPoint firstP;
            CGPoint nextP;
            CGPoint pointP;
            if (i < [muaarray count]-3) {
                firstP = [[muaarray objectAtIndex:i+1] CGPointValue];
                nextP  = [[muaarray objectAtIndex:i+3] CGPointValue];
                pointP  = [[muaarray objectAtIndex:i+2] CGPointValue];
            }else if (i == [muaarray count]-2){
                firstP = [[muaarray objectAtIndex:i+1] CGPointValue];
                nextP  = [[muaarray objectAtIndex:1] CGPointValue];
                pointP  = [[muaarray objectAtIndex:0] CGPointValue];
            }
            [arrayM addObject:[NSValue valueWithCGPoint:firstP]];
            [arrayM addObject:[NSValue valueWithCGPoint:pointP]];
            [arrayM addObject:[NSValue valueWithCGPoint:nextP]];
        }
        
        //set the path of maskLayer.
        for (int i = 0; i < [arrayM count]; i = i+3) {
            CGPoint pathPoint = [[arrayM objectAtIndex:i] CGPointValue];
            if (i == 0) {
                [path moveToPoint:pathPoint];
            }else{
                [path addLineToPoint:pathPoint];
            }
            
            CGPoint cPoint = [[arrayM objectAtIndex:i+1] CGPointValue];
            CGPoint endPoint = [[arrayM objectAtIndex:i+2] CGPointValue];
            [path addQuadCurveToPoint:endPoint controlPoint:cPoint];
            
            if (i == [arrayM count]-3){
                pathPoint = [[arrayM objectAtIndex:0] CGPointValue];
                [path addLineToPoint:pathPoint];
            }
        }
    }else{
        //set the path of maskLayer.
        for (int i = 0; i < [self.trackPoints count]; i++) {
            CGPoint pathPoint = [[self.trackPoints objectAtIndex:i] CGPointValue];
            if (i == 0) {
                [path moveToPoint:pathPoint];
            }else{
                [path addLineToPoint:pathPoint];
            }
            
            if (i == [self.trackPoints count]-1) {
                pathPoint = [[self.trackPoints objectAtIndex:0] CGPointValue];
                [path addLineToPoint:pathPoint];
            }
        }
    }
    
    maskLayer = [CAShapeLayer layer];
    maskLayer.path = [path CGPath];
    maskLayer.fillColor = [UIColor redColor].CGColor;  //设置填充颜色
    maskLayer.backgroundColor = [UIColor redColor].CGColor;  //设置背景颜色
    maskLayer.strokeColor =  BorderColor.CGColor;
    maskLayer.lineJoin = @"bevel";
    maskLayer.lineWidth = BorderWidth;
    view.layer.mask = maskLayer;
    return path;
}

//异形生成
- (void)setMask{
    self.path = [self setMask:self atBorderColor:self.borderColor atBorderWidth:self.borderWidth  atmaskLayer:maskBorderLayer];
}
@end
