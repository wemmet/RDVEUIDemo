

#import "RDPosterEditView.h"

@interface RDPosterEditView (Utility)

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;

@end

@implementation RDPosterEditView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        
        [self initImageView];
    }
    return self;
}

- (void)setRealAreas:(NSMutableArray *)realAreas{
    _realAreas = realAreas;
    NSLog(@"%ld _realAreas:%@",(long)self.tag,_realAreas);
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _contentView.frame = CGRectInset(self.bounds, 0, 0);
    
}

- (void)initImageView
{
    zoomScale = 0.2;
    self.backgroundColor = [UIColor grayColor];
    
    _contentView = [[UIScrollView alloc] initWithFrame:CGRectInset(self.bounds, 0, 0)];
    _contentView.delegate = self;
    _contentView.bounces = NO;
    _contentView.showsHorizontalScrollIndicator = NO;
    _contentView.showsVerticalScrollIndicator = NO;
    [self addSubview:_contentView];

    
    self.imageview = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageview.frame = CGRectMake(0, 0, [[UIScreen mainScreen] autorelease].applicationFrame.size.width  * 2.5, [[UIScreen mainScreen] autorelease].applicationFrame.size.width * 2.5);
    _imageview.userInteractionEnabled = YES;
    [_imageview setClipsToBounds:YES];
    _imageview.contentMode = UIViewContentModeScaleAspectFit;
    [_contentView addSubview:_imageview];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapGesture setNumberOfTapsRequired:1];
    [_imageview addGestureRecognizer:tapGesture];
    [tapGesture release];
    
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
//    [longGesture setNumberOfTapsRequired:1];
    longGesture.minimumPressDuration = 0.3;
    [_imageview addGestureRecognizer:longGesture];
    [longGesture release];
    
    
    UIPanGestureRecognizer *pangesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handPan:)];
    [_imageview addGestureRecognizer:pangesture];
    pangesture.delegate = self;
    [longGesture requireGestureRecognizerToFail:tapGesture];//先处理longGesture
    [longGesture requireGestureRecognizerToFail:pangesture];//先处理longGesture

    
    [pangesture release];
    float minimumScale = self.frame.size.width / _imageview.frame.size.width;
    [_contentView setMinimumZoomScale:minimumScale];
    [_contentView setMaximumZoomScale:2.0];
    [_contentView setZoomScale:minimumScale];
    
}

- (CGRect)getvideoCrop{
    
    CGRect rect = CGRectMake(_contentView.contentOffset.x, _contentView.contentOffset.y, _contentView.frame.size.width, _contentView.frame.size.height);
    
    CGSize size = _imageview.frame.size;
    
    CGRect newRect = CGRectZero;
    newRect.origin.x = rect.origin.x/size.width;
    newRect.origin.y = rect.origin.y/size.height;
    newRect.size.width = rect.size.width/size.width;
    newRect.size.height = rect.size.height/size.height;
    
    
    NSLog(@"newRect:%@",NSStringFromCGRect(newRect));
    return newRect;
}

- (void)setImageViewData:(UIImage *)imageData reset:(BOOL)reset
{
    NSLog(@"tag : %ld %@",(long)self.tag,NSStringFromCGRect(self.frame));
    _imageview.image = imageData;
    if (imageData == nil)
    {
        [self getvideoCrop];
        return;
    }
    if(!reset){
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = [self.realCellArea CGPath];
        maskLayer.fillColor = [[UIColor whiteColor] CGColor];
        maskLayer.frame = maskRect;
        self.layer.mask = maskLayer;
        [self setNeedsLayout];
        [self getvideoCrop];
        return;
    }
    self.contentView.frame = self.bounds;
    self.contentView.contentOffset = CGPointMake(0, 0);
    CGRect rect  = CGRectZero;
//    CGFloat scale = 1.0f;
    CGFloat w = 0.0f;
    CGFloat h = 0.0f;
    if(self.contentView.frame.size.width > self.contentView.frame.size.height)
    {
        
        w = self.contentView.frame.size.width;
        h = w*imageData.size.height/imageData.size.width;
        if(h < self.contentView.frame.size.height){
            h = self.contentView.frame.size.height;
            w = h*imageData.size.width/imageData.size.height;
        }
        
    }
    else
    {
    
        h = self.contentView.frame.size.height;
        w = h*imageData.size.width/imageData.size.height;
        if(w < self.contentView.frame.size.width)
        {
            w = self.contentView.frame.size.width;
            h = w*imageData.size.height/imageData.size.width;
        }
    }
    rect.size = CGSizeMake(w, h);
#if 0
    CGFloat scale_w = w / imageData.size.width;
    CGFloat scale_h = h / imageData.size.height;
    if (w > self.frame.size.width || h > self.frame.size.height)
    {
        scale_w = w / self.frame.size.width;
        scale_h = h / self.frame.size.height;
        if (scale_w > scale_h)
        {
            scale = 1/scale_w;
        }
        else
        {
            scale = 1/scale_h;
        }
    }
    
    if (w <= self.frame.size.width || h <= self.frame.size.height)
    {
        scale_w = w / self.frame.size.width;
        scale_h = h / self.frame.size.height;
        if (scale_w > scale_h)
        {
            scale = scale_h;
        }
        else
        {
            scale = scale_w;
        }
    }
#endif
    @synchronized(self)
    {
         maskRect = rect;
        _imageview.frame = rect;
        [_contentView setZoomScale:zoomScale animated:YES];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = [self.realCellArea CGPath];
        maskLayer.fillColor = [[UIColor whiteColor] CGColor];
        maskLayer.frame = maskRect;
        self.layer.mask = maskLayer;
        [self setNeedsLayout];
        
    }
    [self getvideoCrop];
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL contained=[_realCellArea containsPoint:point];
    return contained;
}


#pragma mark - Zoom methods

- (void)zoomOut{
    [UIView animateWithDuration:0.2 animations:^{
        _contentView.zoomScale = _contentView.zoomScale * 0.8 ;
    }] ;
}

- (void)zoomIn{
    [UIView animateWithDuration:0.2 animations:^{
        _contentView.zoomScale = _contentView.zoomScale * 1.2 ;
    }] ;
}

- (void)handleTap:(UIGestureRecognizer *)gesture
{
    //NSLog(@"self.tag = %d",self.tag);
    if(_tapDelegate && [_tapDelegate respondsToSelector:@selector(tapWithEditView:)])
    {
        [_tapDelegate tapWithEditView:self];
    }
    
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture{
    NSLog(@"%s",__func__);
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gesture
{
    float newScale = _contentView.zoomScale * 1.2;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gesture locationInView:_imageview]];
    [_contentView zoomToRect:zoomRect animated:YES];
}

- (void)handPan:(UIPanGestureRecognizer *)gesture{
    if(gesture.state == UIGestureRecognizerStateBegan){
        
        CGPoint point = [gesture locationInView:self];

        diffHandPanPoint.x = point.x - _contentView.frame.origin.x;
        diffHandPanPoint.y = point.y - _contentView.frame.origin.y;
        
        beginHandPanTime = CFAbsoluteTimeGetCurrent();
        canHandPan = YES;
    }else if(gesture.state == UIGestureRecognizerStateChanged){
        if(!canHandPan){
            return;
        }
        double dur = CFAbsoluteTimeGetCurrent() - beginHandPanTime;
        if(dur >0.2){
            CGPoint point = [gesture locationInView:self];
        
            _contentView.frame = CGRectMake(point.x - diffHandPanPoint.x, point.y - diffHandPanPoint.y, _contentView.frame.size.width, _contentView.frame.size.height);
        }
    
    } else if (gesture.state == UIGestureRecognizerStateEnded){
        _contentView.frame = self.bounds;
        if(!canHandPan){
            return;
        }
        
        double endTime = CFAbsoluteTimeGetCurrent() - beginHandPanTime;
        if(endTime >0.4){
            CGPoint point = [gesture locationInView:self];
            if(!CGRectContainsPoint(self.bounds, point)){
                CGPoint insuperviewPoint = self.frame.origin;
                insuperviewPoint.x = self.frame.origin.x + point.x;
                insuperviewPoint.y = self.frame.origin.y + point.y;
                NSLog(@"%s point:%@",__func__,NSStringFromCGPoint(insuperviewPoint));
                if([_tapDelegate respondsToSelector:@selector(handpanEditView:endpointInSuperviewLocation:)]){
                    [_tapDelegate handpanEditView:self endpointInSuperviewLocation:insuperviewPoint];
                }
            }
        }
        
    }
    
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer*) gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        
        return NO;
        
    }
    else {
        
        return YES;
        
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center
{
    CGRect zoomRect;
    if (scale == 0)
    {
        scale = 1;
    }
    
    zoomRect.size.height = self.frame.size.height / scale;
    zoomRect.size.width  = self.frame.size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    return zoomRect;
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageview;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    
    [scrollView setZoomScale:scale animated:NO];
    zoomScale = scrollView.zoomScale;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"%s",__func__);
    canHandPan = NO;
    return;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    NSLog(@"%s",__func__);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //NSLog(@"scrollView.offset:%@ scrollView.contentsize:%@",NSStringFromCGPoint(scrollView.contentOffset),NSStringFromCGSize(scrollView.contentSize));
    //NSLog(@"scrollView.frame:%@",NSStringFromCGRect(scrollView.frame));
    [self getvideoCrop];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{


}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint touch = [[touches anyObject] locationInView:self.superview];
    self.imageview.center = touch;
    
}

#pragma mark - View cycle
- (void)dealloc{
    NSLog(@"%s",__func__);
    _imageview.image = nil;
    [_contentView release];
    [_realCellArea release];
    [_imageview release];
    
    _contentView = nil;
    _realCellArea = nil;
    _imageview = nil;
    [_realAreas removeAllObjects];
    _realAreas = nil;
    [super dealloc];
}

@end
