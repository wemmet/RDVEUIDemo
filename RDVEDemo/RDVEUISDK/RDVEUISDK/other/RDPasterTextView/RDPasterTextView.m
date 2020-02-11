//
//  RDTextView.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/14.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import "RDPasterTextView.h"

#import "RDHelpClass.h"

/* 角度转弧度 */
#define SK_DEGREES_TO_RADIANS(angle) \
((angle) / 180.0 * M_PI)
CG_INLINE CGPoint CGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

//CG_INLINE CGRect CGRectScale(CGRect rect, CGFloat wScale, CGFloat hScale)
//{
//    return CGRectMake(rect.origin.x * wScale, rect.origin.y * hScale, rect.size.width * wScale, rect.size.height * hScale);
//}

CG_INLINE CGFloat CGPointGetDistance(CGPoint point1, CGPoint point2)
{
    //Saving Variables.
    CGFloat fx = (point2.x - point1.x);
    CGFloat fy = (point2.y - point1.y);
    
    return sqrt((fx*fx + fy*fy));
}

CG_INLINE CGFloat CGAffineTransformGetAngle(CGAffineTransform t)
{
    return atan2(t.b, t.a);
}


CG_INLINE CGSize CGAffineTransformGetScale(CGAffineTransform t)
{
    return CGSizeMake(sqrt(t.a * t.a + t.c * t.c), sqrt(t.b * t.b + t.d * t.d)) ;
}
@interface RDPasterTextView()
{
    CGFloat globalInset;
    UIImageView* rotateView;
    UIButton * closeBtn;
    UIButton * alignBtn;
    
    
    CGRect initialBounds;
    CGFloat initialDistance;
    
    CGPoint beginningPoint;
    CGPoint beginningCenter;
    
    CGPoint prevPoint;
    CGPoint touchLocation;
    
    CGRect beginBounds;
    
    CGFloat deltaAngle;
    CGFloat RotateAngle;
    
    CGPoint beganLocation;
    
    BOOL _isShowingEditingHandles;
    
    CGRect originRect;
    CGRect _tOutRect;
    
    float  _tScale;
    
    float   _selfScale;
    float   _oldSelfScale;
    
    float   pinScale;
    
    float  _zoomScale;
    float  _zoomLastScale;
    CGRect _syncContainerRect;
    UIImageView * selectImageView;
    bool    iscanvas;
    BOOL    iswatermark;
    
    
    bool    isShock;
}
@end
@implementation RDPasterTextView

-(float) selfscale
{
    return _selfScale;
}

-(void)setCanvasPasterText:(BOOL) isCanvas
{
    closeBtn.hidden = YES;
    iscanvas = TRUE;
    
}

//加水印
-(void)setWatermarkPasterText:(BOOL) isWatermark
{
    iswatermark = isWatermark;
}


- (instancetype)initWithFrame:(CGRect)frame
               superViewFrame:(CGRect)superRect
                 contentImage:(UIImageView *)contentImageView
            syncContainerRect:(CGRect)syncContainerRect
{
    if (frame.size.width < 16) {
        frame.size.width = 16;
    }
    if (frame.size.height < 16) {
        frame.size.height = 16;
    }
    if(frame.origin.x<0){
        frame.origin.x = 0;
    }
    if(frame.origin.y<0){
        frame.origin.y = 0;
    }
    if (self = [super initWithFrame:frame]) {
        
        _dragaAlpha = -1;
        _isDrag_Upated = true;
        _isDrag = false;
        _minScale = 0;
        isShock = true;
//        self.layer.shouldRasterize = YES;
//        self.layer.rasterizationScale = YES;
//        self.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
//        self.layer.shadowOpacity = 0.0;
//        self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
//        self.layer.shadowRadius = 0.0;
//        self.layer.allowsEdgeAntialiasing = YES;
        
//        contentImageView.layer.contentsGravity = kCAGravityResizeAspectFill;
        contentImageView.layer.minificationFilter = kCAFilterNearest;
        contentImageView.layer.magnificationFilter = kCAFilterNearest;
        
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        
        _syncContainerRect = syncContainerRect;
        originRect = frame;
        globalInset = 8;
        _selfScale = 1.0;
        _alignment = NSTextAlignmentCenter;
        self.backgroundColor = [UIColor clearColor];
        
         self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        
        _contentImage = contentImageView;
        _contentImage.frame = CGRectInset(self.bounds, globalInset, globalInset);
        _contentImage.layer.allowsEdgeAntialiasing = YES;
        _contentImage.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        [self addSubview:_contentImage];
        
        [selectImageView removeFromSuperview];
        selectImageView = nil;
        selectImageView = [[UIImageView alloc] init];
        selectImageView.frame = CGRectInset(self.bounds, globalInset, globalInset);
        selectImageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        selectImageView.layer.borderWidth = 1.0;
        selectImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        selectImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        selectImageView.layer.shadowOffset = CGSizeZero;
        selectImageView.layer.shadowOpacity = 0.5;
        selectImageView.layer.shadowRadius = 2.0;
        selectImageView.clipsToBounds = NO;
        selectImageView.layer.allowsEdgeAntialiasing = YES;
        //        selectImageView.hidden = YES;
        
        [self addSubview:selectImageView];
        
        closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - globalInset*3 + globalInset/2.0, -globalInset/2.0, globalInset*3, globalInset*3)];
        closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin ;
        closeBtn.backgroundColor = [UIColor clearColor];
        [closeBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-删除_"] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(touchClose) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:closeBtn];
        
        rotateView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width - globalInset*3 + globalInset/2.0, self.bounds.size.height - globalInset*3 + globalInset/2.0, globalInset*3, globalInset*3)];
        rotateView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin ;
        rotateView.backgroundColor = [UIColor clearColor];
        rotateView.image = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕旋转_"];
//        rotateView.image = [rotateView.image imageWithTintColor];
        rotateView.userInteractionEnabled = YES;
        [self addSubview:rotateView];
        
//        CGPoint center = CGRectGetCenter(self.frame);
//        CGPoint rotateViewCenter = CGRectGetCenter(rotateView.frame);
//        RotateAngle = atan2(rotateViewCenter.y-center.y, rotateViewCenter.x-center.x);
        
        UIPanGestureRecognizer* moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGesture:)];
        [self addGestureRecognizer:moveGesture];
        
        UIPanGestureRecognizer* rotateGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateGesture:)];
        [rotateView addGestureRecognizer:rotateGesture];
        
        [moveGesture requireGestureRecognizerToFail:rotateGesture];//优先识别rotateGesture手势
        
        UITapGestureRecognizer *singleTapShowHide = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTapped:)];
        [self addGestureRecognizer:singleTapShowHide];
        
        
        //放大
        UIPinchGestureRecognizer *GestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizer:)];
        [self addGestureRecognizer:GestureRecognizer];
    }
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame
             pasterViewEnbled:(BOOL)pasterViewEnbled
               superViewFrame:(CGRect)superRect
                 contentImage:(UIImageView *)contentImageView
                    textLabel:(RDPasterLabel *)textLabel
                     textRect:(CGRect )textRect
                      ectsize:(CGSize )tsize
                          ect:(CGRect )t
               needStretching:(BOOL)needStretching
                  onlyoneLine:(BOOL)onlyoneLine
                    textColor:(UIColor *)textColor
                  strokeColor:(UIColor *)strokeColor
                   strokeWidth:(float)strokeWidth syncContainerRect:(CGRect)syncContainerRect
                    isRestore:(BOOL)isREstroe
{
    
    globalInset = 8;
    _syncContainerRect = syncContainerRect;
    _needStretching = needStretching;
    _tsize = tsize;
    _tOutRect = t;
    if( !isREstroe )
    {
        if (frame.size.width < globalInset*2.0) {
            frame.size.width = globalInset*2.0;
        }
        if (frame.size.height < globalInset*2.0) {
            frame.size.height = globalInset*2.0;
        }
        if(frame.origin.x<0){
            frame.origin.x = 0;
        }
        if(frame.origin.y<0){
            frame.origin.y = 0;
        }
    }
    NSLog(@"frame1:%@", NSStringFromCGRect(frame));
    if (self = [super initWithFrame:frame]) {
        
        _dragaAlpha = -1;
        _isDrag_Upated = true;
        _isDrag = false;
        _minScale = 0;
        _tScale = 1.0;
        isShock = true;
        
        contentImageView.layer.minificationFilter = kCAFilterNearest;
        contentImageView.layer.magnificationFilter = kCAFilterNearest;
        
        originRect = frame;
        _selfScale = 1.0;
        _oldSelfScale = 1.0;
        _alignment = NSTextAlignmentCenter;
        self.backgroundColor = [UIColor clearColor];
        
         self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        
        closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(-globalInset/2.0, -globalInset/2.0, globalInset*3, globalInset*3)];
        closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin ;
        closeBtn.backgroundColor = [UIColor clearColor];
//        [closeBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_删除素材_"] forState:UIControlStateNormal];
        [closeBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-删除_"] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(touchClose) forControlEvents:UIControlEventTouchUpInside];
        
        
        alignBtn = [[UIButton alloc] initWithFrame:CGRectMake(-globalInset/2.0, self.bounds.size.height - globalInset*3 + globalInset/2.0, globalInset*3, globalInset*3)];
        alignBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin ;
        alignBtn.backgroundColor = [UIColor clearColor];
        [alignBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕居中_"] forState:UIControlStateNormal];
        [alignBtn addTarget:self action:@selector(alignBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        alignBtn.hidden = YES;
        
        rotateView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width - globalInset*3 + globalInset/2.0, self.bounds.size.height - globalInset*3 + globalInset/2.0, globalInset*3, globalInset*3)];
        rotateView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin ;
        rotateView.backgroundColor = [UIColor clearColor];
        rotateView.image = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕旋转_"];
        rotateView.image = [rotateView.image imageWithTintColor];
        rotateView.userInteractionEnabled = YES;
        
        [selectImageView removeFromSuperview];
        selectImageView = nil;
        selectImageView = [[UIImageView alloc] init];
        selectImageView.frame = CGRectInset(self.bounds, globalInset, globalInset);
        selectImageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        selectImageView.layer.borderWidth = 1.0;
        selectImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        selectImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        selectImageView.layer.shadowOffset = CGSizeZero;
        selectImageView.layer.shadowOpacity = 0.5;
        selectImageView.layer.shadowRadius = 2.0;
        selectImageView.clipsToBounds = NO;
        selectImageView.layer.allowsEdgeAntialiasing = YES;
//        selectImageView.hidden = YES;
        
        [self addSubview:selectImageView];
        
        [self addSubview:closeBtn];
        [self addSubview:alignBtn];
        [self addSubview:rotateView];
        
        [_contentImage removeFromSuperview];
        _contentImage = contentImageView;
        _contentImage.frame = CGRectInset(self.bounds, globalInset, globalInset);
        _contentImage.layer.allowsEdgeAntialiasing = YES;
        CALayer *layer = _contentImage.layer;
        layer.magnificationFilter = @"nearest";
        [self insertSubview:_contentImage atIndex:0];
        
        _labelBgView = [[UIView alloc] initWithFrame:textRect];
        _labelBgView.backgroundColor = [UIColor clearColor];
        _labelBgView.clipsToBounds = NO;
        _labelBgView.layer.allowsEdgeAntialiasing = YES;
        [self insertSubview:_labelBgView atIndex:1];
        
        _shadowLbl = [[RDPasterLabel alloc] initWithFrame:_labelBgView.bounds];
        _shadowLbl.text = textLabel.text;
        _shadowLbl.globalInset = globalInset;
        _shadowLbl.backgroundColor = [UIColor clearColor];
        _shadowLbl.tScale = _tScale;
        _shadowLbl.fontColor = textColor;
        _shadowLbl.strokeWidth = strokeWidth;
        _shadowLbl.needStretching = needStretching;
        _shadowLbl.onlyoneline = onlyoneLine;
        _shadowLbl.clipsToBounds = NO;
        _shadowLbl.layer.allowsEdgeAntialiasing = YES;
        _shadowLbl.lineBreakMode = NSLineBreakByCharWrapping;
        _shadowLbl.minimumScaleFactor = 5.0;
        _shadowLbl.numberOfLines = 0;
        _shadowLbl.hidden = YES;
        [_labelBgView addSubview:_shadowLbl];
        
        _contentLabel = textLabel;
        _contentLabel.frame = _labelBgView.bounds;
        _contentLabel.globalInset = globalInset;
//        [_contentLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        _contentLabel.backgroundColor = [UIColor clearColor];
        _contentLabel.tScale = _tScale;
        _contentLabel.fontColor = textColor;
        _contentLabel.strokeColor = strokeColor;
        _contentLabel.strokeWidth = strokeWidth;
        _contentLabel.needStretching = needStretching;
        _contentLabel.onlyoneline = onlyoneLine;
        
//        _contentLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
//        _contentLabel.layer.borderWidth = 1.0;
//        _contentLabel.layer.borderColor = [UIColor clearColor].CGColor;
//        _contentLabel.layer.shadowColor = [UIColor clearColor].CGColor;
//        _contentLabel.layer.shadowOffset = CGSizeZero;
//        _contentLabel.layer.shadowOpacity = 0.5;
//        _contentLabel.layer.shadowRadius = 2.0;
        //2019.10.31 为了解决文字毛边严重
        _contentLabel.clipsToBounds = NO;
        _contentLabel.layer.allowsEdgeAntialiasing = YES;
        _contentLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _contentLabel.minimumScaleFactor = 5.0;
        [_labelBgView addSubview:_contentLabel];
        
        if(!_needStretching){
            
            _contentImage.image = [contentImageView.animationImages firstObject];
            _contentImage.animationImages = contentImageView.animationImages;
            _contentImage.animationDuration = 1.6;
            [_contentImage startAnimating];
            //[_contentImage setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight];
            [_contentImage setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];

            _contentImage.contentMode = UIViewContentModeScaleAspectFill;
            //_contentLabel.adjustsFontSizeToFitWidth = YES;
        }else{
//            _contentImage.layer.contents        = (id)((UIImage *)[contentImageView.animationImages firstObject]).CGImage;
            _contentImage.image = [contentImageView.animationImages firstObject];
            _contentImage.layer.contentsCenter  = contentImageView.layer.contentsCenter;
            _contentImage.layer.contentsGravity = kCAGravityResize;
            [_contentImage setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        }
        _contentLabel.numberOfLines = 0;
        
        UIPanGestureRecognizer* moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGesture:)];
        [self addGestureRecognizer:moveGesture];
        
        UIPanGestureRecognizer* rotateGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateGesture:)];
        [rotateView addGestureRecognizer:rotateGesture];
        
        [moveGesture requireGestureRecognizerToFail:rotateGesture];//优先识别rotateGesture手势
        
        UITapGestureRecognizer *singleTapShowHide = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTapped:)];
        [self addGestureRecognizer:singleTapShowHide];
        
        //放大
        UIPinchGestureRecognizer *GestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizer:)];
        [self addGestureRecognizer:GestureRecognizer];
        
        if(needStretching){
            CGPoint centPoint = self.center;
            if(self.frame.origin.x <= 0){
                centPoint.x = self.frame.size.width / 2.0 + 2;
                self.center = centPoint;
            }
            
            if(self.frame.origin.x + self.frame.size.width > superRect.size.width){
                centPoint.x = superRect.size.width  - self.frame.size.width/2.0 - 2;
                self.center = centPoint;
            }
        }
        
    }
    //initialBounds   = self.bounds;
    return self;
}

- (UIButton *)mirrorBtn {
    if (!_mirrorBtn) {
        _mirrorBtn = [[UIButton alloc] initWithFrame:CGRectMake(-globalInset/2.0, -globalInset/2.0, globalInset*3, globalInset*3)];
        [_mirrorBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-画中画镜像左右_"] forState:UIControlStateNormal];
        [_mirrorBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-画中画镜像上下_"] forState:UIControlStateSelected];
        [_mirrorBtn addTarget:self action:@selector(mirrorBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_mirrorBtn];
    }
    return _mirrorBtn;
}

- (void)mirrorBtnAction:(UIButton *)sender {
    if (CGAffineTransformEqualToTransform(_contentImage.transform, CGAffineTransformIdentity)) {
        _contentImage.transform = kLRFlipTransform;//左右
        sender.selected = NO;
    }else if (CGAffineTransformEqualToTransform(_contentImage.transform, kLRFlipTransform)) {
        _contentImage.transform = kUDFlipTransform;//上下
        sender.selected = YES;
    }else if (CGAffineTransformEqualToTransform(_contentImage.transform, kUDFlipTransform)) {
        _contentImage.transform = kLRUPFlipTransform;//上下左右
        sender.selected = YES;
    }else if (CGAffineTransformEqualToTransform(_contentImage.transform, kLRUPFlipTransform)) {
        _contentImage.transform = CGAffineTransformIdentity;//复原
        sender.selected = NO;
    }
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
}

- (void)setContentImageTransform:(CGAffineTransform)transform {
    _contentImage.transform = transform;
    if (CGAffineTransformEqualToTransform(transform, kUDFlipTransform) || CGAffineTransformEqualToTransform(transform, kLRUPFlipTransform)) {
        _mirrorBtn.selected = YES;
    }
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
}

- (void)refreshBounds:(CGRect)bounds {
    if (bounds.size.width < 16) {
        bounds.size.width = 16;
    }
    if (bounds.size.height < 16) {
        bounds.size.height = 16;
    }
    self.bounds = bounds;
    _contentImage.frame = CGRectInset(self.bounds, globalInset, globalInset);
    selectImageView.frame = CGRectInset(self.bounds, globalInset, globalInset);
    if( !iswatermark )
    {
        if( closeBtn )
            closeBtn.frame = CGRectMake(-globalInset/2.0, -globalInset/2.0, globalInset*3, globalInset*3);
        
        rotateView.frame = CGRectMake(self.bounds.size.width - globalInset*3 + globalInset/2.0, self.bounds.size.height - globalInset*3 + globalInset/2.0, globalInset*3, globalInset*3);
        _mirrorBtn.frame = CGRectMake(-globalInset/2.0, -globalInset/2.0, globalInset*3, globalInset*3);
    }
    
    
    _selfScale = self.transform.a;
    
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
    
     [self setFramescale:_selfScale];
    
    if( iswatermark )
    {
        float size = (_selfScale - 1.0)/1.2f;
        if([_delegate respondsToSelector:@selector(pasterViewSizeScale: atValue:)]){
            [_delegate pasterViewSizeScale:self atValue:size];
        }
    }
}

- (void)setIsHiddenAlignBtn:(BOOL)isHiddenAlignBtn {
    alignBtn.hidden = isHiddenAlignBtn;
//    if( alignBtn.isHidden )
//        [selectImageView removeFromSuperview];
}

- (void)contentTapped:(UITapGestureRecognizer*)tapGesture
{
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
    if( _isCutout )
    {
        //取得所点击的点的坐标
        [self setPointCutout:[tapGesture locationInView:_contentImage] isRefresh:false];
    }
    else
    {
        
    if (_isShowingEditingHandles) {
        [self hideEditingHandles];
        [self.superview bringSubviewToFront:self];
        if( [_delegate respondsToSelector:@selector(pasterViewShowText)] )
        {
            [_delegate pasterViewShowText];
        }
    } else {
        [self showEditingHandles];
        if( [_delegate respondsToSelector:@selector(pasterViewShowText)] )
        {
            [_delegate pasterViewShowText];
        }
    }
    

    }
}

//获取图片某一点的颜色
 - (UIColor *)colorAtPixel:(CGPoint)point  isRefresh:(BOOL) isRefresh{
     if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, _contentImage.image.size.width, _contentImage.image.size.height), point)) {
         return nil;
     }
     
     NSInteger pointX = trunc(point.x);
     NSInteger pointY = trunc(point.y);
     CGImageRef cgImage = _contentImage.image.CGImage;
     NSUInteger width = _contentImage.image.size.width;
     NSUInteger height = _contentImage.image.size.height;
     CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
     int bytesPerPixel = 4;
     int bytesPerRow = bytesPerPixel * 1;
     NSUInteger bitsPerComponent = 8;
     unsigned char pixelData[4] = { 0, 0, 0, 0 };
     CGContextRef context = CGBitmapContextCreate(pixelData,
                                                  1,
                                                  1,
                                                  bitsPerComponent,
                                                  bytesPerRow,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedLast |     kCGBitmapByteOrder32Big);
     CGColorSpaceRelease(colorSpace);
     CGContextSetBlendMode(context, kCGBlendModeCopy);
     
     CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
     CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
     CGContextRelease(context);
     
     CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
     CGFloat green = (CGFloat)pixelData[1] / 255.0f;
     CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
     CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
     
     if( [_delegate respondsToSelector:@selector(paster_CutoutColor: atColorRed: atColorGreen: atColorBlue: atAlpha: isRefresh:)] )
     {
         [_delegate paster_CutoutColor:self atColorRed:red atColorGreen:green atColorBlue:blue atAlpha:alpha isRefresh:isRefresh];
     }
     
     return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
 }

//抠图颜色获取界面
-(void)setPointCutout:(CGPoint ) point isRefresh:(BOOL) isRefresh
{
//    point = CGPointMake(point.x - _contentImage.frame.origin.x, point.y - _contentImage.frame.origin.y );
    if( point.x < (_cutoutHeight/2.0/_selfScale)  )
    {
        point = CGPointMake(_cutoutHeight/2.0/_selfScale, point.y);
    }
    if(point.y < (_cutoutHeight/2.0/_selfScale))
    {
        point = CGPointMake(point.x, _cutoutHeight/2.0/_selfScale);
    }
    if(point.y > (_contentImage.frame.size.height - _cutoutHeight/2.0/_selfScale))
    {
        point = CGPointMake(point.x, (_contentImage.frame.size.height - _cutoutHeight/2.0/_selfScale));
    }
    if(point.x > ((_contentImage.frame.size.width - _cutoutHeight/2.0/_selfScale) ))
    {
        point = CGPointMake(((_contentImage.frame.size.width - _cutoutHeight/2.0/_selfScale) ), point.y);
    }
    
    float imageHeight = _cutoutHeight;
    
    CGRect rect = CGRectMake( (point.x - _cutoutHeight/2.0/_selfScale)/_contentImage.frame.size.width, (point.y - _cutoutHeight/2.0/_selfScale)/_contentImage.frame.size.height, imageHeight/_selfScale/_contentImage.frame.size.width, imageHeight/_selfScale /_contentImage.frame.size.height);
    
    UIColor * color = [self colorAtPixel:CGPointMake(
     (point.x/_contentImage.frame.size.width)  * _contentImage.image.size.width,
     (point.y/_contentImage.frame.size.height) * _contentImage.image.size.height )
     isRefresh:isRefresh];
    
    UIImage * image = [RDHelpClass image:_contentImage.image rotation:0 cropRect:rect];
    
    _cutout_ZoomAreaView.image = nil;
    _cutout_RealAreaView.image = nil;
    
    _cutout_ZoomAreaView.image = image;
    _cutout_RealAreaView.image = image;
    
    _cutout_MagnifierView.backgroundColor = color;
    
    _cutout_MagnifierView.frame = CGRectMake( point.x + _contentImage.frame.origin.x - _cutout_MagnifierView.frame.size.width/2.0, point.y + _contentImage.frame.origin.y - _cutout_MagnifierView.frame.size.height/2.0,  _cutout_MagnifierView.frame.size.width, _cutout_MagnifierView.frame.size.height);
}

-(void)setCutoutMagnifier:(bool) isCutout
{
    if( isCutout )
    {
        selectImageView.hidden = YES;
        closeBtn.hidden = YES;
        rotateView.hidden = YES;
        _mirrorBtn.hidden = YES;
        
        if( !_cutout_MagnifierView )
        {
            _cutout_Height = 80;
            _cutoutHeight = 20;
            
            UIColor *backgroundColor = [UIColor  colorWithWhite:0.8 alpha:1.0];
            
            float imageHeight = _cutoutHeight/_selfScale;
            
            UIImage * image = [RDHelpClass image:_contentImage.image rotation:0 cropRect:CGRectMake((_contentImage.frame.size.width - imageHeight)/2.0/_contentImage.frame.size.width, (_contentImage.frame.size.height - imageHeight)/2.0/_contentImage.frame.size.height, imageHeight/_contentImage.frame.size.width, imageHeight/_contentImage.frame.size.height)];
            
            UIColor * color = [self colorAtPixel:CGPointMake(_contentImage.frame.size.width/2.0/_contentImage.frame.size.width * _contentImage.image.size.width, _contentImage.frame.size.height/2.0/_contentImage.frame.size.height * _contentImage.image.size.height) isRefresh:false];
            
            _cutout_MagnifierView = [[UIView alloc] initWithFrame:CGRectMake((_contentImage.frame.size.width - _cutout_Height)/2.0, (_contentImage.frame.size.height - _cutout_Height)/2.0, _cutout_Height, _cutout_Height)];
            _cutout_MagnifierView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4];
            _cutout_MagnifierView.layer.borderColor = backgroundColor.CGColor;
            _cutout_MagnifierView.layer.cornerRadius =  _cutout_MagnifierView.frame.size.width/2.0;
            _cutout_MagnifierView.layer.borderWidth = 1.5;
            _cutout_MagnifierView.layer.cornerRadius =  _cutout_MagnifierView.frame.size.width/2.0;
            _cutout_MagnifierView.layer.shadowColor = [UIColor blackColor].CGColor;
            _cutout_MagnifierView.layer.shadowOffset = CGSizeZero;
            _cutout_MagnifierView.layer.shadowOpacity = 0.5;
            _cutout_MagnifierView.layer.shadowRadius = 2.0;
            _cutout_MagnifierView.clipsToBounds = YES;
            _cutout_MagnifierView.layer.allowsEdgeAntialiasing = YES;
            
            [self addSubview:_cutout_MagnifierView];
            
            _cutout_ZoomAreaView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, _cutout_Height - 10, _cutout_Height - 10)];
            _cutout_ZoomAreaView.layer.borderColor = backgroundColor.CGColor;
            _cutout_ZoomAreaView.layer.cornerRadius =  _cutout_ZoomAreaView.frame.size.width/2.0;
            _cutout_ZoomAreaView.layer.borderWidth = 1.5;
            _cutout_ZoomAreaView.layer.shadowColor = [UIColor blackColor].CGColor;
            _cutout_ZoomAreaView.layer.shadowOffset = CGSizeZero;
            _cutout_ZoomAreaView.layer.shadowOpacity = 0.5;
            _cutout_ZoomAreaView.layer.shadowRadius = 2.0;
            _cutout_ZoomAreaView.clipsToBounds = YES;
            _cutout_ZoomAreaView.layer.allowsEdgeAntialiasing = YES;
            
            _cutout_ZoomAreaView.image = image;
            [_cutout_MagnifierView addSubview:_cutout_ZoomAreaView];
            
            _cutout_RealAreaView = [[UIImageView alloc] initWithFrame:CGRectMake((_cutout_Height - _cutoutHeight)/2.0, (_cutout_Height - _cutoutHeight)/2.0, _cutoutHeight, _cutoutHeight)];
            _cutout_RealAreaView.layer.borderColor = backgroundColor.CGColor;
            _cutout_RealAreaView.layer.cornerRadius =  _cutout_RealAreaView.frame.size.width/2.0;
            _cutout_RealAreaView.layer.borderWidth = 1.5;
            _cutout_RealAreaView.layer.shadowColor = [UIColor blackColor].CGColor;
            _cutout_RealAreaView.layer.shadowOffset = CGSizeZero;
            _cutout_RealAreaView.layer.shadowOpacity = 0.5;
            _cutout_RealAreaView.layer.shadowRadius = 2.0;
            _cutout_RealAreaView.clipsToBounds = YES;
            _cutout_RealAreaView.layer.allowsEdgeAntialiasing = YES;
            _cutout_RealAreaView.image = image;
            [_cutout_MagnifierView addSubview:_cutout_RealAreaView];
            
            _cutout_label1 = [[UILabel alloc] initWithFrame:CGRectMake( (_cutout_Height - 5)/2.0,  (_cutout_Height - 1)/2.0, 5, 1)];
            _cutout_label1.backgroundColor = backgroundColor;
            _cutout_label1.layer.shadowColor = [UIColor blackColor].CGColor;
            _cutout_label1.layer.shadowOffset = CGSizeZero;
            _cutout_label1.layer.shadowOpacity = 0.5;
            _cutout_label1.layer.shadowRadius = 2.0;
            _cutout_label1.clipsToBounds = NO;
            _cutout_label1.layer.allowsEdgeAntialiasing = YES;
            [_cutout_MagnifierView addSubview:_cutout_label1];
            
            
            _cutout_label2 = [[UILabel alloc] initWithFrame:CGRectMake( (_cutout_Height - 1)/2.0,  (_cutout_Height - 5)/2.0, 1, 5)];
            _cutout_label2.backgroundColor = backgroundColor;
            _cutout_label2.layer.shadowColor = [UIColor blackColor].CGColor;
            _cutout_label2.layer.shadowOffset = CGSizeZero;
            _cutout_label2.layer.shadowOpacity = 0.5;
            _cutout_label2.layer.shadowRadius = 2.0;
            _cutout_label2.clipsToBounds = NO;
            _cutout_label2.layer.allowsEdgeAntialiasing = YES;
            [_cutout_MagnifierView addSubview:_cutout_label2];
            
            
            _cutout_MagnifierView.layer.borderWidth = 1.0*1/_selfScale;
            _cutout_MagnifierView.layer.shadowRadius = 2.0*1/_selfScale;
            _cutout_MagnifierView.transform = CGAffineTransformMakeScale(1, 1);
            _cutout_MagnifierView.transform = CGAffineTransformMakeScale(1/_selfScale, 1/_selfScale);

            _cutout_ZoomAreaView.layer.borderWidth = 1.0*1/_selfScale;
            _cutout_ZoomAreaView.layer.shadowRadius = 2.0*1/_selfScale;

            _cutout_RealAreaView.layer.borderWidth = 1.0*1/_selfScale;
            _cutout_RealAreaView.layer.shadowRadius = 2.0*1/_selfScale;
        }
        
        _cutout_MagnifierView.hidden = NO;
    }
    else
    {
        selectImageView.hidden = NO;
        closeBtn.hidden = NO;
        rotateView.hidden = NO;
        _mirrorBtn.hidden = NO;
        _cutout_MagnifierView.hidden = YES;
    }
    _isCutout = isCutout;
}

-(void)refresh
{
    if (self.superview) {
        CGSize scale = CGAffineTransformGetScale(self.superview.transform);
        CGAffineTransform t = CGAffineTransformMakeScale(scale.width, scale.height);
        [closeBtn setTransform:CGAffineTransformInvert(t)];
        [rotateView setTransform:CGAffineTransformInvert(t)];
        [alignBtn setTransform:CGAffineTransformInvert(t)];
    }
}

-(void)setSyncContainer:( syncContainerView * ) syncContainer
{
    _syncContainer = syncContainer;
    
    _syncContainer.currentPasterTextView = self;
    [_syncContainer setMark];
}

- (void)pinchGestureRecognizer:(UIPinchGestureRecognizer *)recognizer {
    if( _isCutout )
    {
        return;
    }
    CGPoint center = CGRectGetCenter(self.frame);
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan://缩放开始
        {
             deltaAngle      =-CGAffineTransformGetAngle(self.transform);
                    beganLocation = touchLocation;
                    initialBounds   = CGRectIntegral(self.bounds);
                    initialDistance = CGPointGetDistance(center, touchLocation);
            
            
            pinScale = recognizer.scale;
            _oldSelfScale = _selfScale;
            
            
            
            if( _isDrag )
            {
                _isDrag_Upated = false;
                _contentImage.alpha = 1.0;
            }
        }
            break;
        case UIGestureRecognizerStateChanged://缩放改变
        {
            float ang =
            -atan2(beganLocation.y-center.y, beganLocation.x-center.x) +
            atan2(touchLocation.y-center.y, touchLocation.x-center.x);
            
            float angleDiff = deltaAngle - ang;
            
            CGFloat newScale = 0;
            if( iswatermark )
            {
                newScale = (recognizer.scale - 1.0) + _oldSelfScale;
                
                if( newScale > _waterMaxScale )
                    newScale = _waterMaxScale;
                else if( newScale < 1.0 )
                    newScale = 1.0;
                else
                    newScale = (recognizer.scale - 1.0) + _oldSelfScale;
                
            }
            else
               newScale = (recognizer.scale - 1.0) + _oldSelfScale;
            if( _minScale > newScale )
            {
                newScale = _minScale;
            }
            
            
            if( newScale < 0.20 )
                newScale = 0.2;
            
            self.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(atan2f(self.transform.b, self.transform.a)), newScale, newScale);
            
            [self setFramescale:newScale];
            if([_delegate respondsToSelector:@selector(pasterViewSizeScale: atValue:)]){
                [_delegate pasterViewSizeScale:self atValue:(_selfScale - 1.0)/1.2f];
            }
            _selfScale = newScale;
            if( _isDrag )
            {
                _isDrag_Upated = false;
                _contentImage.alpha = 1.0;
            }
        }
            break;
        case UIGestureRecognizerStateEnded://缩放结束
            //               self.lastScale = 1;
            if( _isDrag )
            {
                _isDrag_Upated = true;
                _contentImage.alpha = 0.0;
            }
            break;
            
        default:
            break;
    }
    
    if(_delegate){
        if([_delegate respondsToSelector:@selector(pasterViewDidChangeFrame:)]){
            [_delegate pasterViewDidChangeFrame:self];
        }
        if([_delegate respondsToSelector:@selector(pasterViewMoved:)]){
            [_delegate pasterViewMoved:self];
        }
    }
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
}

- (void) moveGesture:(UIGestureRecognizer *) recognizer{
    
    if( _isCutout )
    {
        BOOL isRefresh = false;
        if (recognizer.state == UIGestureRecognizerStateEnded){
            isRefresh = true;
        }
        //取得所点击的点的坐标
        [self setPointCutout:[recognizer locationInView:_contentImage] isRefresh:isRefresh];
    }
    else
    {
        touchLocation = [recognizer locationInView:self.superview];
        
        if(_delegate){
//            if( iscanvas || iswatermark )
//            {
//                if([_delegate respondsToSelector:@selector(pasterMidline:isHidden:)]){
                if( self.syncContainer )
                    [self.syncContainer pasterMidline:self isHidden:false];
//                }
//            }
        }
        
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            beginningPoint = touchLocation;
            beginningCenter = self.center;
            
            [self setCenter:CGPointMake(beginningCenter.x + (touchLocation.x - beginningPoint.x), beginningCenter.y + (touchLocation.y - beginningPoint.y))];
            beginBounds = self.bounds;
            if( _isDrag )
            {
                _isDrag_Upated = false;
                _contentImage.alpha = 1.0;
            }
        }else if (recognizer.state == UIGestureRecognizerStateChanged){
            [self setCenter:CGPointMake(beginningCenter.x + (touchLocation.x - beginningPoint.x), beginningCenter.y + (touchLocation.y - beginningPoint.y))];
            if( _isDrag )
            {
                _isDrag_Upated = false;
                _contentImage.alpha = 1.0;
            }
        }else if (recognizer.state == UIGestureRecognizerStateEnded){
            [self setCenter:CGPointMake(beginningCenter.x + (touchLocation.x - beginningPoint.x), beginningCenter.y + (touchLocation.y - beginningPoint.y))];
            if(_delegate){
//                if( iscanvas || iswatermark )
//                {
                    if( self.syncContainer )
                    [self.syncContainer pasterMidline:self isHidden:false];
//                }
            }
            if( _isDrag )
            {
                _isDrag_Upated = true;
                _contentImage.alpha = 0.0;
            }
        }
        prevPoint = touchLocation;
        
        if([_delegate respondsToSelector:@selector(pasterViewMoved:)]){
            [_delegate pasterViewMoved:self];
        }
        [_contentLabel setNeedsLayout];
        [_shadowLbl setNeedsLayout];
    }
}

- (void)touchClose{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(pasterViewDidClose:)]){
            [_delegate pasterViewDidClose:self];
        }
    }
    [self removeFromSuperview];
}

- (NSInteger)getTextAlign{
    if (_alignment == NSTextAlignmentLeft) {
        return 0;
    }
    else if (_alignment == NSTextAlignmentCenter) {
        return 1;
    }else {
        return 2;
    }
}

- (void)alignBtnAction:(UIButton *)sender {
    if (_alignment == NSTextAlignmentRight) {
       self.alignment = NSTextAlignmentLeft;
    }
    else if (_alignment == NSTextAlignmentCenter) {
        self.alignment = NSTextAlignmentRight;
    }else {
        self.alignment = NSTextAlignmentCenter;
    }
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
}

- (void)setIsBold:(BOOL)isBold{
    _isBold = isBold;
    _contentLabel.isBold = _isBold;
    _shadowLbl.isBold = _isBold;
}

- (void)setAlignment:(NSTextAlignment)alignment {
    _alignment = alignment;
    if (alignment == NSTextAlignmentLeft) {
        _contentLabel.textAlignment = NSTextAlignmentLeft;
        _contentLabel.tAlignment = UICaptionTextAlignmentLeft;
        _shadowLbl.textAlignment = NSTextAlignmentLeft;
        _shadowLbl.tAlignment = UICaptionTextAlignmentLeft;
        [alignBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕居左_"] forState:UIControlStateNormal];
    }
    else if (alignment == NSTextAlignmentRight) {
        _contentLabel.textAlignment = NSTextAlignmentRight;
        _contentLabel.tAlignment = UICaptionTextAlignmentRight;
        _shadowLbl.textAlignment = NSTextAlignmentRight;
        _shadowLbl.tAlignment = UICaptionTextAlignmentRight;
        [alignBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕居右_"] forState:UIControlStateNormal];
    }else {
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.tAlignment = UICaptionTextAlignmentCenter;
        _shadowLbl.textAlignment = NSTextAlignmentCenter;
        _shadowLbl.tAlignment = UICaptionTextAlignmentCenter;
        [alignBtn setImage:[RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕居中_"] forState:UIControlStateNormal];
    }
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
}

- (void) setFramescale:(float)value{
//    NSLog(@"frame2:%@", NSStringFromCGRect(self.frame));
    _selfScale = value;
    
    closeBtn.transform =  CGAffineTransformMakeScale(1/value, 1/value);
    
    rotateView.transform = CGAffineTransformMakeScale(1, 1);
    rotateView.transform =  CGAffineTransformMakeScale(1/value, 1/value);
    
    alignBtn.transform =  CGAffineTransformMakeScale(1/value, 1/value);
    
    _mirrorBtn.transform = CGAffineTransformMakeScale(1, 1);
    _mirrorBtn.transform = CGAffineTransformMakeScale(1/value, 1/value);
    
    selectImageView.layer.borderWidth = 1.0*1/value;
    selectImageView.layer.shadowRadius = 2.0*1/value;
    
    _cutout_MagnifierView.layer.borderWidth = 1.0*1/value;
    _cutout_MagnifierView.layer.shadowRadius = 2.0*1/value;
    _cutout_MagnifierView.transform = CGAffineTransformMakeScale(1, 1);
    _cutout_MagnifierView.transform = CGAffineTransformMakeScale(1/value, 1/value);

    _cutout_ZoomAreaView.layer.borderWidth = 1.0*1/value;
    _cutout_ZoomAreaView.layer.shadowRadius = 2.0*1/value;

    _cutout_RealAreaView.layer.borderWidth = 1.0*1/value;
    _cutout_RealAreaView.layer.shadowRadius = 2.0*1/value;
    
    if( _contentLabel )
    {
        _labelBgView.transform = CGAffineTransformIdentity;
        float width = _labelBgView.frame.size.width/_tScale;
        float height = _labelBgView.frame.size.height/_tScale;
        CGPoint center = CGRectGetCenter(_labelBgView.frame);
        _labelBgView.frame = CGRectMake( center.x -  (width * value)/2.0  , center.y - (height * value)/2.0, width * value , height * value );
        if(_isItalic){
            if (_isVerticalText) {
                _labelBgView.transform = CGAffineTransformMake(1/value, 0, tanf(0 * (CGFloat)M_PI / 180), 1/value, 0, 0);
                CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
                UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:_fontName matrix:matrix];
                _contentLabel.font = [UIFont fontWithDescriptor:desc size:_fontSize*value];
            }else {
                _labelBgView.transform = CGAffineTransformMake(1/value, 0, tanf(-15 * (CGFloat)M_PI / 180), 1/value, 0, 0);
                _contentLabel.font = [UIFont fontWithName:_fontName size:_fontSize*value];
            }
        }else{
            _labelBgView.transform = CGAffineTransformMake(1/value, 0, tanf(0 * (CGFloat)M_PI / 180), 1/value, 0, 0);
            _contentLabel.font = [UIFont fontWithName:_fontName size:_fontSize*value];
        }
        _tScale = value;
        _contentLabel.frame = _labelBgView.bounds;
//        _contentLabel.tScale = _tScale;
        _shadowLbl.font = _contentLabel.font;
        _shadowLbl.frame = CGRectMake(_shadowOffset.width*_tScale, _shadowOffset.height*_tScale, _contentLabel.frame.size.width, _contentLabel.frame.size.height);
        [_contentLabel setNeedsLayout];
        [_shadowLbl setNeedsLayout];
    }
}

- (float) getFramescale{
    return _selfScale;
}


-(float)Angle
{
    CGPoint center = CGRectGetCenter(self.frame);
    CGPoint rotateViewCenter = beganLocation;
    CGPoint closeBtnCenter = touchLocation;
    
    CGFloat x1 = rotateViewCenter.x - center.x;
    CGFloat y1 = rotateViewCenter.y - center.y;
    CGFloat x2 = closeBtnCenter.x - center.x;
    CGFloat y2 = closeBtnCenter.y - center.y;
    
    CGFloat x = x1 * x2 + y1 * y2;
    CGFloat y = x1 * y2 - x2 * y1;
    return atan2( y, x );
}

- (void) rotateGesture:(UIGestureRecognizer *) recognizer{
    
    touchLocation = [recognizer locationInView:self.superview];
//    touchLocation = [RDHelpClass solveUIWidgetFuzzyPoint:touchLocation];
    CGPoint center = CGRectGetCenter(self.frame);
//    center = [RDHelpClass solveUIWidgetFuzzyPoint:center];
    
    if( self.syncContainer )
       [self.syncContainer pasterMidline:self isHidden:false];
//    if( _delegate && iscanvas || iswatermark )
//    {
//        if([_delegate respondsToSelector:@selector(pasterMidline: isHidden:)]){
//                   [_delegate pasterMidline:self isHidden:false];
//               }
//    }
    
    
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        deltaAngle      =
//        floor(
//              atan2(touchLocation.y - center.y, touchLocation.x-center.x)
              - CGAffineTransformGetAngle(self.transform)
//        )
        ;
        beganLocation = touchLocation;
        initialBounds   = CGRectIntegral(self.bounds);
        initialDistance =
//        floor(
                                CGPointGetDistance(center, touchLocation)
//        )
        ;
        _oldSelfScale = _selfScale;
        if( _isDrag )
        {
            _isDrag_Upated = false;
            _contentImage.alpha = 1.0;
        }
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged){
        float ang =
        -atan2(beganLocation.y-center.y, beganLocation.x-center.x) +
//        [self Angle];
        atan2(touchLocation.y-center.y, touchLocation.x-center.x);
        
        float angleDiff = deltaAngle - ang;
        
        float oldScale = _selfScale;
        
        _zoomScale = CGPointGetDistance(center, touchLocation)/(initialDistance);
        if( iswatermark )
        {
            float watermarkScale = _oldSelfScale + (_zoomScale-1.0)*_oldSelfScale;
            
            if( watermarkScale > _waterMaxScale )
                _selfScale = _waterMaxScale;
            else if( watermarkScale < 1.0 )
                _selfScale = 1.0;
            else
                _selfScale = _oldSelfScale + (_zoomScale-1.0)*_oldSelfScale;
        }
        else
            _selfScale = _oldSelfScale + (_zoomScale-1.0)*_oldSelfScale;
//        if(_zoomScale>1){
//            if(_zoomScale>_zoomLastScale){
//                _selfScale +=0.04;
//            }
//            else if(_zoomLastScale>_zoomScale){
//                _selfScale -=0.04;
//            }
//        }else if(_zoomScale<1){
//            if(_zoomScale>_zoomLastScale)
//                _selfScale +=0.02;
//            else if(_zoomLastScale>_zoomScale){
//                _selfScale -=0.02;
//            }
//        }
        _zoomLastScale = _zoomScale;
        if( _contentLabel )
        {
            float size = (_selfScale - 1.0)/1.2f;
            float scale = oldScale;
//
//            float fontSize = _fontSize * (size*1.2f + 1.0);
//
//            float RestrictedFontSize = 6.0;
//            if( !_needStretching )
//                RestrictedFontSize = 4.0;
//
//            if( ( fontSize > RestrictedFontSize )
//               && (size < 4.0)
//               )
//                scale = _selfScale;
//            else
//            {
//                if( size >= 4.0 )
//                    size = 4.0;
//                else
//                    if(  fontSize < RestrictedFontSize )
//                        size = (RestrictedFontSize/_fontSize - 1.0)/1.2f;
//
//                _selfScale = size*1.2f + 1.0;
                scale = _selfScale;
                
                
//            }
            float fheight = (scale*CGRectGetHeight(self.frame));
            scale = fheight/CGRectGetHeight(self.frame);
            
            self.transform =  CGAffineTransformScale(CGAffineTransformMakeRotation(-angleDiff), scale, scale);
            [self setFramescale:scale];
            if([_delegate respondsToSelector:@selector(pasterViewSizeScale: atValue:)]){
                [_delegate pasterViewSizeScale:self atValue:size];
            }
        }
        else{
            float size = (_selfScale - 1.0)/1.2f;
            float scale = oldScale;
//            float RestrictedSize = -0.5;
//
//            if( ( size > RestrictedSize ) && (size < 4.0) )
//                scale = _selfScale;
//            else
//            {
//                if( size >= 4.0 )
//                    size = 4.0;
//                else if(  size < RestrictedSize )
//                    size = RestrictedSize;
//
//                _selfScale = size*1.2f + 1.0;
                scale = _selfScale;
                
                
//            }
//            float fheight = (scale*CGRectGetHeight(self.frame));
//            scale = fheight/CGRectGetHeight(self.frame);
            if( ((-angleDiff) < 0.03) && ((-angleDiff) >= -0.03)  )
            {
                angleDiff = 0;
                if( isShock )
                {
                    AudioServicesPlaySystemSound(1519);
                    isShock = false;
                }
            }
            else{
                isShock = true;
            }
            
            if( _minScale > scale )
            {
                scale = _minScale;
            }
            
            self.transform =  CGAffineTransformScale(CGAffineTransformMakeRotation(-angleDiff), scale, scale);
            [self setFramescale:scale];
            if([_delegate respondsToSelector:@selector(pasterViewSizeScale: atValue:)]){
                [_delegate pasterViewSizeScale:self atValue:size];
            }
        }
        if( _isDrag )
        {
            _isDrag_Upated = false;
            _contentImage.alpha = 1.0;
        }
//        NSLog(@"scale:%f",scale);
//        self.layer.shouldRasterize = YES;
        
    }else if(recognizer.state == UIGestureRecognizerStateEnded){
        
//        if( _delegate
//           && iscanvas || iswatermark
//           )
//        {
           if( self.syncContainer )
            [self.syncContainer pasterMidline:self isHidden:false];
//        }
        if( _isDrag )
        {
            _isDrag_Upated = true;
            _contentImage.alpha = 0.0;
        }
    }
    if(_delegate){
        if([_delegate respondsToSelector:@selector(pasterViewDidChangeFrame:)]){
            [_delegate pasterViewDidChangeFrame:self];
        }
        if([_delegate respondsToSelector:@selector(pasterViewMoved:)]){
            [_delegate pasterViewMoved:self];
        }
    }
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
}
-(void)setMinScale:(float) scale
{
    _minScale = scale;
}


- (void)setTextString:(NSString *)text adjustPosition:(BOOL)adjust{
    _contentLabel.pText = text;
    _shadowLbl.pText = text;
    NSMutableString * attributedText = [NSMutableString string];
    if (_isVerticalText) {
        [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
        ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if (substringRange.location + substringRange.length == text.length) {
                [attributedText insertString:substring atIndex:attributedText.length];
            }else {
                [attributedText insertString:[substring stringByAppendingString:@"\n"] atIndex:attributedText.length];
            }
        }];
        text = attributedText;
    }else {
        [attributedText setString:text];
    }
    _contentLabel.text = attributedText;
    _contentLabel.needStretching = _needStretching;
    _contentLabel.isVerticalText = _isVerticalText;
    _contentLabel.layer.contentsGravity = kCAGravityResizeAspectFill;
    _contentLabel.layer.minificationFilter = kCAFilterNearest;
    _contentLabel.layer.magnificationFilter = kCAFilterNearest;
    _shadowLbl.text = attributedText;
    _shadowLbl.needStretching = _needStretching;
    _shadowLbl.isVerticalText = _isVerticalText;
    _shadowLbl.layer.contentsGravity = kCAGravityResizeAspectFill;
    _shadowLbl.layer.minificationFilter = kCAFilterNearest;
    _shadowLbl.layer.magnificationFilter = kCAFilterNearest;
    self.layer.contentsGravity = kCAGravityResizeAspectFill;
    self.layer.minificationFilter = kCAFilterNearest;
    self.layer.magnificationFilter = kCAFilterNearest;
    float RestrictedFontSize  = 2.0;
    if(_needStretching){
        float fWidth = _labelBgView.frame.size.width;
        float fHeight = _labelBgView.frame.size.height;
        CGSize maxSize;
        if (_isVerticalText) {
            maxSize = CGSizeMake(CGFLOAT_MAX, _syncContainerRect.size.height - _tOutRect.origin.y - (originRect.size.height - _tOutRect.origin.y - _tOutRect.size.height));
        }else {
            maxSize = CGSizeMake(_syncContainerRect.size.width - _tOutRect.origin.x - (originRect.size.width - _tOutRect.origin.x - _tOutRect.size.width), CGFLOAT_MAX);
        }
        for (int i = (_isVerticalText ? fWidth : fHeight); i >= 1 ; i--) {
            UIFont *font = [UIFont fontWithName:_fontName size:(CGFloat)i];
            if(!font){
                _fontName = [[UIFont systemFontOfSize:10] fontName];//@"Baskerville-BoldItalic";
                _fontCode = @"morenziti";
                font = [UIFont fontWithName:_fontName size:(CGFloat)i];
            }
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                                 attributes:@{NSFontAttributeName:font}];
            CGSize rectSize = [attributedText boundingRectWithSize:maxSize
                                                           options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                            context:nil].size;
//            NSLog(@"fHeight:%.2f i:%d rectSizeW:%.2f H:%.2f", fHeight, i, rectSize.width, rectSize.height);
            if((!_isVerticalText && rectSize.height <= fHeight) || (_isVerticalText && rectSize.width <= fWidth) || i == RestrictedFontSize){
                CGRect frame = self.bounds;
                if (_isVerticalText) {
                    frame.size.height = rectSize.height + _tOutRect.origin.y + _tOutRect.size.height + globalInset*2.0;
                    self.bounds = frame;
                    _labelBgView.frame = CGRectMake(_tOutRect.origin.x + globalInset, _tOutRect.origin.y + globalInset, _labelBgView.frame.size.width, rectSize.height);
                }else {
                    frame.size.width = rectSize.width + _tOutRect.origin.x + _tOutRect.size.width + globalInset*2.0;
                    self.bounds = frame;
                    _labelBgView.frame = CGRectMake(_tOutRect.origin.x + globalInset, _tOutRect.origin.y + globalInset, rectSize.width, _labelBgView.frame.size.height);
                }
                _contentLabel.frame = _labelBgView.bounds;
                _shadowLbl.frame = CGRectMake(_shadowOffset.width*_tScale, _shadowOffset.height*_tScale, _contentLabel.frame.size.width, _contentLabel.frame.size.height);
                [self setFontSize:i label:_contentLabel];
                [self setFontSize:i label:_shadowLbl];
                break;
            }
        }
    }
    else
    {
        if (_isVerticalText) {
            float width = _labelBgView.frame.size.width;
            float height = _labelBgView.frame.size.height;
            for (int i = _labelBgView.frame.size.width; i >= 1 ; i--) {
                UIFont *font = [UIFont fontWithName:_fontName size:(CGFloat)i];
                if(!font){
                    _fontName = [[UIFont systemFontOfSize:10] fontName];
                    _fontCode = @"morenziti";
                    font = [UIFont fontWithName:_fontName size:(CGFloat)i];
                }
                CGSize size_w = [attributedText boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName:font}
                                                             context:nil].size;
                CGSize size_h = [attributedText boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName:font}
                                                             context:nil].size;
                NSLog(@"i:%d _contentLabel:%@ height:%.2f size_w.height:%.2f width:%.2f size_h.width:%.2f", i, NSStringFromCGSize(_labelBgView.bounds.size), height,  size_w.height, width, size_h.width);
                if ((size_w.height <= height && size_h.width <= width) || ( i == RestrictedFontSize )  ) {
                    [self setFontSize:i label:_contentLabel];
                    [self setFontSize:i label:_shadowLbl];
                    break;
                }
            }
        }else {
            for (int i = (_labelBgView.frame.size.height - 5 ); i >= 1 ; i--) {
                UIFont *font = [UIFont fontWithName:_fontName size:(CGFloat)i];
                if(!font){
                    _fontName = [[UIFont systemFontOfSize:10] fontName];
                    _fontCode = @"morenziti";
                    font = [UIFont fontWithName:_fontName size:(CGFloat)i];
                }
                NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text
                                                                                     attributes:@{NSFontAttributeName:font}];
                CGSize rectSize = [attributedText boundingRectWithSize:CGSizeMake(_labelBgView.frame.size.width-globalInset*2.0, CGFLOAT_MAX)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                               context:nil].size;
                if( (rectSize.height <= _labelBgView.frame.size.height) || ( i == RestrictedFontSize ) ){
//                    NSLog(@"_contentLabel:%.2f rectSize:%.2f", _contentLabel.frame.size.height, rectSize.height);
                    [self setFontSize:i label:_contentLabel];
                    [self setFontSize:i label:_shadowLbl];
                    break;                    
                }
            }
        }
        _contentLabel.adjustsFontSizeToFitWidth = NO;
    }
    if(adjust)
        [self adjustPosition];
    
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
    selectImageView.frame = CGRectInset(self.bounds, globalInset, globalInset);
    if( alignBtn )
        closeBtn.frame = CGRectMake(-globalInset/2.0, -globalInset/2.0, globalInset*3, globalInset*3);
    NSLog(@"_contentLabel:%@", NSStringFromCGSize(_contentLabel.bounds.size));
}

- (void)adjustPosition{

    if(self.superview.frame.size.width==0 || self.superview.frame.size.height==0){
        return;
    }
    CGFloat radius = atan2f(self.transform.b, self.transform.a);
    //double duijiaoxian = hypot(((double) _pasterView.frame.size.width), ((double) _pasterView.frame.size.height));//已知直角三角形两个直角边长度，求斜边长度
    float captionLastScale = [self getFramescale];
    double s = fabs(sin(radius));
    double c = fabs(cos(radius));
    
    float x = (c * self.contentImage.frame.size.width + self.contentImage.frame.size.height * s)/2.0 * captionLastScale+globalInset*3;
    float y = (s * self.contentImage.frame.size.width  + self.contentImage.frame.size.height * c)/2.0 * captionLastScale+globalInset*3;
    {
        CGPoint center = self.center;
        center.x = (MAX(self.center.x, x));
        [self setCenter: center];
    }
    
    {
        
        CGPoint center = self.center;
        center.x = (MIN(self.center.x, self.superview.frame.size.width - x));
        [self setCenter: center];
    }
    
    {
        CGPoint center = self.center;
        center.y = (MAX(self.center.y, y));
        [self setCenter: center];
    }
    
    {
        CGPoint center = self.center;
        center.y = MIN(self.center.y, self.superview.frame.size.height - y);
        [self setCenter: center];
    }
}

- (void)hideEditingHandles{
    
    closeBtn.hidden = YES;
    alignBtn.hidden = YES;
    if( !iscanvas  && !iswatermark)
    {
        rotateView.hidden = YES;
        selectImageView.hidden = YES;
    }
    _mirrorBtn.hidden = YES;
    
    
    _isShowingEditingHandles = NO;
}
static RDPasterTextView *lastTouchedView;
- (void) showEditingHandles{
    [lastTouchedView hideEditingHandles];
    _isShowingEditingHandles = YES;
    lastTouchedView = self;
    if( !iscanvas  && !iswatermark)
    {
        closeBtn.hidden = NO;
        alignBtn.hidden = (_contentLabel.text.length == 0);
        _mirrorBtn.hidden = NO;
    }
    selectImageView.hidden = NO;
    rotateView.hidden = NO;
}

- (void)setIsItalic:(BOOL)isItalic{
    _isItalic = isItalic;
    _contentLabel.isItalic = _isItalic;
    _shadowLbl.isItalic = _isItalic;
    if(_isItalic){
        if (_isVerticalText) {
            _labelBgView.transform = CGAffineTransformMake(1/_tScale, 0, tanf(0 * (CGFloat)M_PI / 180), 1/_tScale, 0, 0);
            CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
            UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:_fontName matrix:matrix];
            _contentLabel.font = [UIFont fontWithDescriptor:desc size:_fontSize*_tScale];
        }else {
            _labelBgView.transform = CGAffineTransformMake(1/_tScale, 0, tanf(-15 * (CGFloat)M_PI / 180), 1/_tScale, 0, 0);
            _contentLabel.font = [UIFont fontWithName:_fontName size:_fontSize*_tScale];
        }
    }else{
        _labelBgView.transform = CGAffineTransformMake(1/_tScale, 0, tanf(0 * (CGFloat)M_PI / 180), 1/_tScale, 0, 0);
        _contentLabel.font = [UIFont fontWithName:_fontName size:_fontSize*_tScale];
    }
}

- (void)setIsShadow:(BOOL)isShadow{
    _isShadow = isShadow;
    _contentLabel.isShadow = _isShadow;
    _shadowLbl.hidden = !isShadow;
}

- (void)setShadowColor:(UIColor *)shadowColor{
    _shadowColor = shadowColor;
    if(_isShadow){
        _contentLabel.tShadowColor = _shadowColor;    //设置文本的阴影色彩和透明度。
    }else{
        _contentLabel.tShadowColor = [UIColor clearColor];    //设置文本的阴影色彩和透明度。
    }
    _shadowLbl.textColor = shadowColor;
    _shadowLbl.strokeColor = shadowColor;
    _shadowLbl.fontColor = shadowColor;
    [_shadowLbl setNeedsLayout];
}

- (void)setIsVerticalText:(BOOL)isVerticalText {
    _isVerticalText = isVerticalText;
    _contentLabel.isVerticalText = isVerticalText;
    _shadowLbl.isVerticalText = isVerticalText;
}

- (void)setFontName:(NSString *)fontName
{
    _fontName = fontName;
    if(_isItalic){
        if (_isVerticalText) {
            CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
            UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:_fontName matrix:matrix];
            _contentLabel.font = [UIFont fontWithDescriptor:desc size:_fontSize*_tScale];
        }else {
            _contentLabel.font = [UIFont fontWithName:_fontName size:_fontSize*_tScale];
        }
    }else{
        _contentLabel.font = [UIFont fontWithName:_fontName size:_fontSize*_tScale];
    }
    _shadowLbl.font = _contentLabel.font;
    if(_needStretching && _contentLabel.pText.length > 0){
        [_contentLabel adjustsWidthWithSuperOriginalSize:originRect.size textRect:_tOutRect syncContainerRect:_syncContainerRect];
        _shadowLbl.frame = CGRectMake(_shadowOffset.width*_tScale, _shadowOffset.height*_tScale, _contentLabel.frame.size.width, _contentLabel.frame.size.height);
    }
    [_contentLabel setNeedsLayout];
    [_shadowLbl setNeedsLayout];
    selectImageView.frame = CGRectInset(self.bounds, globalInset, globalInset);
    if( alignBtn )
        closeBtn.frame = CGRectMake(-globalInset/2.0, -globalInset/2.0, globalInset*3, globalInset*3);
    if (_needStretching) {
        _contentImage.layer.contentsScale = _tsize.height / _contentImage.frame.size.height;
    }
}

- (void) setonlyoneline:(BOOL)onlyoneline{
    _contentLabel.onlyoneline = onlyoneline;
    _shadowLbl.onlyoneline = onlyoneline;
}

- (void)setFontSize:(CGFloat)fontSize label:(UILabel *)label
{
    NSLog(@"fontSize:%f",_fontSize);
    _fontSize = fontSize;
    if (_isItalic && _isVerticalText) {
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(15 * (CGFloat)M_PI / 180), 1, 0, 0);//设置倾斜角度。
        UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:_fontName matrix:matrix];
        label.font = [UIFont fontWithDescriptor:desc size:_fontSize*_tScale];
    }else {
        UIFont * font = [UIFont fontWithName:_fontName size:_fontSize*_tScale];
        label.font = font;
    }
    if (_needStretching) {
        _contentImage.layer.contentsScale = _tsize.height / _contentImage.frame.size.height;
    }
}

- (void)dealloc{
    NSLog(@"%s",__func__);
    
    if( _contentImage )
    {
        _contentImage.image = nil;
        [_contentImage removeFromSuperview];
        _contentImage = nil;
    }
    
    if( rotateView )
    {
        rotateView.image = nil;
        [rotateView removeFromSuperview];
        rotateView = nil;
    }
    
    if( rotateView )
    {
        rotateView.image = nil;
        [rotateView removeFromSuperview];
        rotateView = nil;
    }
    
    if( selectImageView )
    {
        selectImageView.image = nil;
        [selectImageView removeFromSuperview];
        selectImageView = nil;
    }
    
    if( closeBtn )
    {
        [closeBtn removeFromSuperview];
        closeBtn = nil;
    }
    
    if( alignBtn )
    {
        [alignBtn removeFromSuperview];
        alignBtn = nil;
    }
    
    if( closeBtn )
    {
        [closeBtn removeFromSuperview];
        closeBtn = nil;
    }
    
    if( _contentLabel )
    {
        [_contentLabel removeFromSuperview];
        _contentLabel = nil;
    }
    
    if( _shadowLbl )
    {
        [_shadowLbl removeFromSuperview];
        _shadowLbl = nil;
    }
    
    if( closeBtn )
    {
        [closeBtn removeFromSuperview];
        closeBtn = nil;
    }
    
    
    if( _cutout_MagnifierView )
    {
        [_cutout_label1 removeFromSuperview];
        _cutout_label1 = nil;
        
        [_cutout_label2 removeFromSuperview];
        _cutout_label2 = nil;
        
        [_cutout_ZoomAreaView removeFromSuperview];
        _cutout_ZoomAreaView = nil;
        
        [_cutout_RealAreaView removeFromSuperview];
        _cutout_RealAreaView = nil;
        
        [_cutout_MagnifierView removeFromSuperview];
        _cutout_MagnifierView = nil;
    }
    
}
@end
