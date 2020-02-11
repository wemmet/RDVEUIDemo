//
//  UICliper.m
//  image
//
//  Created by 岩 邢 on 12-7-25.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#define D2R(d) (d * M_PI / 180)
#define HanlfOfCircleWidth 2.5

#import "RDUICliper.h"
#import "RDHelpClass.h"
@interface RDUICliper()
{
    CGContextRef context;
    float ratio;
}
@end

@implementation RDUICliper

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    oFrame=frame;
    _minEdge = 70;
    return self;
}
- (id)initWithView:(UIView*)iv freedom:(BOOL )bFree//初始化
{
    CGRect r = [iv bounds];
    self = [super initWithFrame:r];
    if (self) {
        [iv addSubview:self];
        [iv setUserInteractionEnabled:YES];
        
        _minEdge = 70;
        [self setBackgroundColor:[UIColor clearColor]];
        float size = r.size.height>r.size.width? r.size.width :r.size.height;
        cliprect = CGRectMake((r.size.width-size)/2, (r.size.height-size)/2, size, size);//裁剪框局域
        
        [self setMultipleTouchEnabled:NO];
        touchPoint = CGPointZero;
        freedom=bFree;
        _playBtn = [[UIButton alloc] init];
        
        _playBtn.backgroundColor = [UIColor clearColor];
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateNormal];
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateHighlighted];
        [_playBtn addTarget:self action:@selector(playerVideo) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playBtn];
        
        self.layer.masksToBounds = NO;
        self.clipsToBounds = YES;
        
        UITapGestureRecognizer *tapgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSelfGesture:)];
        [self addGestureRecognizer:tapgesture];
    }
    return self;
}

- (void)playerVideo{
    if(!_delegate){
        return;
    }
    if([_delegate respondsToSelector:@selector(touchUpinslidePlayeBtn)]){
        BOOL play = [_delegate touchUpinslidePlayeBtn];
        if(!play){
            [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateNormal];
            [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateHighlighted];
        }else{
            [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_暂停_"] forState:UIControlStateNormal];
            [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_暂停_"] forState:UIControlStateHighlighted];
            //_playBtn.hidden = YES;
        }
    }
}

- (void)playerVideo:(BOOL) isPlay{
    if(!isPlay){
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateNormal];
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_播放_"] forState:UIControlStateHighlighted];
    }else{
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_暂停_"] forState:UIControlStateNormal];
        [_playBtn setImage:[RDHelpClass imageWithContentOfFile:@"剪辑_暂停_"] forState:UIControlStateHighlighted];
        //_playBtn.hidden = YES;
    }
}

#pragma mark - set Clips

- (void)setFrameRect:(CGRect )frame{
    oFrame=frame;
    self.frame = frame;
    _playBtn.frame = CGRectMake(frame.size.width/2-28, frame.size.height/2-28, 56, 56);
    [self setNeedsDisplay];
}

- (void)setVideoSize:(CGSize )size{
    videoSize=size;
}

- (void)setCropType:(FileCropModeType)type{
    isMoving=NO;
    _crop_Type=type;
    switch (_crop_Type) {
        case kCropTypeFreedom:
        case kCropType1v1:
            ratio=1;
            break;
        case kCropType16v9:
            ratio=16.0/9.0;
            break;
        case kCropType9v16:
            ratio=9.0/16.0;
            break;
        case kCropType4v3:
            ratio=4.0/3.0;
            break;
        case kCropType3v4:
            ratio=3.0/4.0;
            break;
        default:
            ratio=videoSize.width/videoSize.height;
            break;
    }
    //裁剪框局域
    CGRect r = oFrame;
    float x=0,y=0,w=0,h=0;
    if (_crop_Type == kCropTypeFreedom) {
        cliprect = CGRectMake(0, 0, r.size.width, r.size.height);
    }else {
        if (_crop_Type == kCropTypeFixedRatio) {
            if (videoSize.width >= videoSize.height) {
                if (r.size.width > r.size.height) {
                    h = r.size.height;
                    w = h * (videoSize.width / videoSize.height);
                    if (w > r.size.width) {
                        w = r.size.width;
                        h = w / (videoSize.width / videoSize.height);
                    }
                }else {
                    w = r.size.width;
                    h = w / (videoSize.width / videoSize.height);
                    if (h > r.size.height) {
                        h = r.size.height;
                        w = h * (videoSize.width / videoSize.height);
                    }
                }
            }else {
                w = r.size.height * (videoSize.width / videoSize.height);
                h = r.size.height;
                if (w > r.size.width) {
                    w = r.size.width;
                    h = w / (videoSize.width / videoSize.height);
                }
            }
        }else if (_crop_Type == kCropTypeOriginal) {
            w=r.size.width;
            h=r.size.height;
        }
        else if (_crop_Type == kCropType1v1) {
            w=MIN(r.size.width, r.size.height);
            h=w;
        }else {
            if (r.size.width >= r.size.height) {
                h = r.size.height;
                w = h * ratio;
                if (w > r.size.width) {
                    w = r.size.width;
                    h = w / ratio;
                }
            }else {
                w = r.size.width;
                h = w / ratio;
                if (h > r.size.height) {
                    h = r.size.height;
                    w = h * ratio;
                }
            }
        }
        x=(r.size.width-w)/2;
        y=(r.size.height-h)/2;
        cliprect = CGRectMake(x, y, w, h);
    }
    cliprect = CGRectInset(cliprect, -HanlfOfCircleWidth, -HanlfOfCircleWidth);
    [self setNeedsDisplay];
}

- (void)setCropText:(NSString *)text{
    textStr=text;
}

- (void)drawRect:(CGRect)rect
{
    _minEdge=ratio>=0?_minEdge:_minEdge*ratio;
    if (cliprect.size.width<_minEdge) {
        if (cliprect.origin.x<-HanlfOfCircleWidth) {
            cliprect.origin.x = -HanlfOfCircleWidth;
        }
        if (cliprect.origin.x+_minEdge>oFrame.size.width) {
            cliprect.origin.x=oFrame.size.width-_minEdge;
        }
        cliprect.size.width = _minEdge;
    }
    if(cliprect.size.height<_minEdge/ratio) {
        if (cliprect.origin.y<-HanlfOfCircleWidth) {
            cliprect.origin.y = -HanlfOfCircleWidth;
        }
        if (cliprect.origin.y+_minEdge/ratio>oFrame.size.height) {
            cliprect.origin.y=oFrame.size.height-_minEdge/ratio;
        }
        cliprect.size.height = _minEdge/ratio;
    }
    float videoRotio=videoSize.width/videoSize.height;
    
    if (cliprect.origin.x+cliprect.size.width>oFrame.size.width + HanlfOfCircleWidth) {
        cliprect.size.width=oFrame.size.width + HanlfOfCircleWidth-cliprect.origin.x;
    }
    if (cliprect.origin.y+cliprect.size.height>oFrame.size.height + HanlfOfCircleWidth) {
        cliprect.size.height=oFrame.size.height + HanlfOfCircleWidth-cliprect.origin.y;
    }
    if (isMoving) {
        if (cliprect.origin.x<-HanlfOfCircleWidth) {
            cliprect.origin.x=-HanlfOfCircleWidth;
        }
        if (cliprect.origin.y<-HanlfOfCircleWidth) {
            cliprect.origin.y=-HanlfOfCircleWidth;
        }
        switch (_crop_Type) {
            case kCropTypeOriginal:
                if (videoSize.width>videoSize.height) {
                    cliprect.size.width=videoRotio>ratio?cliprect.size.height:cliprect.size.width;
                    cliprect.size.height=cliprect.size.width/ratio;
                }else{
                    cliprect.size.width=videoRotio>ratio?cliprect.size.height*ratio:cliprect.size.width;
                    cliprect.size.height=cliprect.size.width/ratio;
                }
                break;
            case kCropTypeFixedRatio:
                if (videoSize.width == videoSize.height) {
                    cliprect.size.width=MIN(cliprect.size.height,cliprect.size.width);
                    cliprect.size.height=cliprect.size.width;
                }else if (videoSize.width>videoSize.height) {
                    cliprect.size.width=cliprect.size.width;
                    cliprect.size.height=cliprect.size.width/ratio;
                }else{
                    cliprect.size.width=cliprect.size.height*ratio;
                    cliprect.size.height=cliprect.size.width/ratio;
                }
                break;
            case kCropType1v1:
                cliprect.size.width=videoRotio>ratio?cliprect.size.height:cliprect.size.width;
                cliprect.size.height=cliprect.size.width;
                break;
            case kCropType16v9:
                cliprect.size.width=cliprect.size.width;
                cliprect.size.height=cliprect.size.width*9/16;
                break;
            case kCropType9v16:
                cliprect.size.width=videoRotio>ratio?cliprect.size.height*9/16:cliprect.size.width;
                cliprect.size.height=cliprect.size.width*16/9;
                break;
            case kCropType4v3:
                cliprect.size.width=cliprect.size.width;
                cliprect.size.height=cliprect.size.width*3/4;
                break;
            case kCropType3v4:
                cliprect.size.width=videoRotio>ratio?cliprect.size.height*3/4:cliprect.size.width;
                cliprect.size.height=cliprect.size.width*4/3;
                break;
            default:
                break;
        }
    }
    //if (!context) {
        context=UIGraphicsGetCurrentContext();
    //}

    //绘制剪裁区域外半透明效果
//    grayAlpha = [[[UIColor alloc]initWithRed:0 green:0 blue:0 alpha:0.8] CGColor];//黑色背景
    if (_isOutsideTransparent) {
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    }else {
        CGContextSetFillColorWithColor(context, [[[UIColor alloc]initWithRed:0 green:0 blue:0 alpha:0.8] CGColor]);
    }
    CGRect rrr = CGRectMake(cliprect.origin.x+3, cliprect.origin.y+3, cliprect.size.width-6, cliprect.size.height-6);
    
    
    CGRect r_up = CGRectMake(rrr.origin.x, 0, rrr.size.width, rrr.origin.y);
    CGContextFillRect(context, r_up);
    
    
    CGRect r_down  = CGRectMake(rrr.origin.x, rrr.origin.y + rrr.size.height, rrr.size.width , rect.size.height -  rrr.size.height-r_up.size.height);
    CGContextFillRect(context, r_down);
    
    
    CGRect r_left  = CGRectMake(0, 0, r_up.origin.x + 0.08, rect.size.height);
    CGContextFillRect(context, r_left);
    
    CGRect r_right  = CGRectMake(r_up.size.width + r_left.size.width - 0.2, 0, rect.size.width- (r_up.size.width + r_left.size.width) + 0.2, rect.size.height);
    CGContextFillRect(context, r_right);
    
    //绘制剪裁区域的格子
    {
        CGFloat cornerStrokeWidth = 1.2;
        
        CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 1.0f, 1.0f);
        CGContextSetLineWidth(context, cornerStrokeWidth);
        
        CGContextAddRect(context, rrr);
        CGContextStrokePath(context);
    }
    
    
    //绘制虚线
    {
        CGFloat cornerStrokeWidth = 1.1;
        CGContextSetRGBStrokeColor(context, 0.91f, 0.91f, 0.91f, 1.0f);
        CGContextSetLineWidth(context, cornerStrokeWidth);
        const CGFloat lengths[] = {5,5};
        
        CGContextSetLineDash(context, 0, lengths,2);
        
        CGContextMoveToPoint(context, rrr.origin.x+rrr.size.width/3, rrr.origin.y);
        CGContextAddLineToPoint(context, rrr.origin.x+rrr.size.width/3, rrr.origin.y+rrr.size.height);
        
        CGContextMoveToPoint(context, rrr.origin.x+rrr.size.width/3*2, rrr.origin.y);
        CGContextAddLineToPoint(context, rrr.origin.x+rrr.size.width/3*2, rrr.origin.y+rrr.size.height);
        
        CGContextMoveToPoint(context, rrr.origin.x, rrr.origin.y+rrr.size.height/3);
        CGContextAddLineToPoint(context, rrr.origin.x+rrr.size.width, rrr.origin.y+rrr.size.height/3);
        
        CGContextMoveToPoint(context, rrr.origin.x, rrr.origin.y+rrr.size.height/3*2);
        CGContextAddLineToPoint(context, rrr.origin.x+rrr.size.width, rrr.origin.y+rrr.size.height/3*2);
        
        CGContextStrokePath(context);
    }
    
    {
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(context, 1.0);
        
        //填充圆，无边框
        CGContextAddArc(context, rrr.origin.x+2, rrr.origin.y+2, HanlfOfCircleWidth*2, 0, 2*3.14159265358979323846, 0); //添加一个圆
        CGContextDrawPath(context, kCGPathFill);//绘制填充
        
        //填充圆，无边框
        CGContextAddArc(context, rrr.origin.x+rrr.size.width - 2, rrr.origin.y + 2, HanlfOfCircleWidth*2, 0, 2*3.14159265358979323846, 0); //添加一个圆
        CGContextDrawPath(context, kCGPathFill);//绘制填充
        
        //填充圆，无边框
        CGContextAddArc(context, rrr.origin.x+2, rrr.origin.y+rrr.size.height-2, HanlfOfCircleWidth*2, 0, 2*3.14159265358979323846, 0); //添加一个圆
        CGContextDrawPath(context, kCGPathFill);//绘制填充
        
        //填充圆，无边框
        CGContextAddArc(context, rrr.origin.x+rrr.size.width - 2, rrr.origin.y+rrr.size.height - 2, HanlfOfCircleWidth*2, 0, 2*3.14159265358979323846, 0); //添加一个圆
        CGContextDrawPath(context, kCGPathFill);//绘制填充
    }
    {
        CGContextSetLineWidth(context, 1.2);
        CGContextSetRGBFillColor (context, 1, 1, 1, 1);
        UIFont  *font = [UIFont boldSystemFontOfSize:18.0];
//        [textStr drawInRect:CGRectMake(cliprect.origin.x+cliprect.size.width/2-15, cliprect.origin.y+cliprect.size.height/2-15, cliprect.size.width, 30) withFont:font];
//
        
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys: font, NSFontAttributeName, nil];
        
        [textStr drawInRect: CGRectMake(cliprect.origin.x+cliprect.size.width/2-15, cliprect.origin.y+cliprect.size.height/2-15, cliprect.size.width, 30)
               withAttributes: dictionary];
        font = nil;
    }
    
    if( rrr.size.height < 0)
    {
        int b = 0;
    }
    
    _playBtn.frame = CGRectMake(rrr.origin.x + rrr.size.width/2-22, rrr.origin.y +rrr.size.height/2-22, 44, 44);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    touchPoint = [touch locationInView:self];
    touchBeginPoint = [[[event allTouches] anyObject] locationInView:self];
    //    CGPoint p = [touch locationInView:self];
    
    //    float x1=.0f, x2=.0f, y1=.0f, y2=.0f;
    
    float x = touchPoint.x;
    float y = touchPoint.y;
    if (_crop_Type == kCropTypeFixed) {
        if((x>cliprect.origin.x && x< cliprect.origin.x+cliprect.size.width)&&(y>cliprect.origin.y && y<cliprect.origin.y+cliprect.size.height)){ //正中
            //        NSLog(@"---------->>>正中");
            cropTouchPoint=CropMid;
            
        }else {
            return;
        }
    }
    if (fabs(x-cliprect.origin.x)<20) //左
    {
        float offy = y-cliprect.origin.y;
        if (fabsf(offy)<20) { //左上角
            cropTouchPoint=CropLeftTop;

        }else if(fabs(offy-cliprect.size.height)<20){ //左下角
//            NSLog(@"---------->>>左下角");
            cropTouchPoint=CropLeftButtom;
            
        }else if(y>cliprect.origin.y+cliprect.size.height/2-20 && y<cliprect.origin.y+cliprect.size.height/2+20) { //左中部
//            NSLog(@"---------->>>左中部");
            cropTouchPoint=CropLeftMid;
            
        }
    }
    else if(fabs(x-cliprect.origin.x-cliprect.size.width)<20) //右
    {
        float offy = y-cliprect.origin.y;
        if (fabsf(offy)<20) { //右上角
//            NSLog(@"---------->>>右上角");
            cropTouchPoint=CropRightTop;
            
        }else if(fabs(offy-cliprect.size.height)<20) { //右下角
//            NSLog(@"---------->>>右下角");
            cropTouchPoint=CropRightButtom;
            
            
        }else if(y>cliprect.origin.y+cliprect.size.height/2-20 && y<cliprect.origin.y+cliprect.size.height/2+20) { //右中部
//            NSLog(@"---------->>>右中部");
            cropTouchPoint=CropRightMid;
            
        }
    }
    else if(fabs(y-cliprect.origin.y)<20){ //上
        if (x>cliprect.origin.x+cliprect.size.width/2-20 && x< cliprect.origin.x+cliprect.size.width/2+20) { //上中
//            NSLog(@"---------->>>上中");
            cropTouchPoint=CropTopMid;
            
        }
    }
    else if(fabs(y-cliprect.origin.y-cliprect.size.height)<20){ //下
        if (x>cliprect.origin.x+cliprect.size.width/2-20 && x< cliprect.origin.x+cliprect.size.width/2+20) { //下中
//            NSLog(@"---------->>>下中");
            cropTouchPoint=CropButtomMid;
            
        }
    }
    else if((x>cliprect.origin.x && x< cliprect.origin.x+cliprect.size.width)&&(y>cliprect.origin.y && y<cliprect.origin.y+cliprect.size.height)){ //正中
//        NSLog(@"---------->>>正中");
        cropTouchPoint=CropMid;
        
    }else {
        return;
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if([[[NSUserDefaults standardUserDefaults]objectForKey:@"isPlaying"] integerValue]!=1){
        UITouch *touch = [touches anyObject];
        CGPoint p = [touch locationInView:self];
        
        float x1=.0f, x2=.0f, y1=.0f, y2=.0f;
        
        if (cropTouchPoint==CropNone) {//没有
        }
        
        if (cropTouchPoint==CropLeftTop) {//左上
            x1 = p.x - touchPoint.x;
            y1 = p.y - touchPoint.y;
            if (_crop_Type != kCropTypeFreedom) {
                if (fabsf(x1)>fabsf(y1)) {
                    y1=x1/ratio;
                }else{
                    x1=y1*ratio;
                }
            }
        }
        if (cropTouchPoint==CropRightTop) {//右上
            x2 = p.x - touchPoint.x;
            y1 = p.y - touchPoint.y;
            if (_crop_Type != kCropTypeFreedom) {
                if (fabsf(x2)>fabsf(y1)) {
                    y1=-x2/ratio;
                }else{
                    x2=-y1*ratio;
                }
            }
        }
        if (cropTouchPoint==CropLeftButtom) {//左下
            x1 = p.x - touchPoint.x;
            y2 = p.y - touchPoint.y;
            if (_crop_Type != kCropTypeFreedom) {
                if (fabsf(x1)>fabsf(y2)) {
                    y2=-x1/ratio;
                }else{
                    x1=-y2*ratio;
                }
            }
        }
        if (cropTouchPoint==CropRightButtom) {//右下
            x2 = p.x - touchPoint.x;
            y2 = p.y - touchPoint.y;
            if (_crop_Type != kCropTypeFreedom) {
                if (fabsf(x2)>fabsf(y2)) {
                    y2=x2/ratio;
                }else{
                    x2=y2*ratio;
                    y2=x2/ratio;
                }
            }
        }
        if (_crop_Type==kCropTypeFreedom) {
            if (cropTouchPoint==CropLeftMid) {//左中
                x1 = p.x - touchPoint.x;
            }
            if (cropTouchPoint==CropRightMid) {//右中
                x2 = p.x - touchPoint.x;
            }
            if (cropTouchPoint==CropTopMid) {//上中
                y1 = p.y - touchPoint.y;
            }
            if (cropTouchPoint==CropButtomMid) {//下中
                y2 = p.y - touchPoint.y;
            }
        }
        
        if (cropTouchPoint==CropMid) {//中间
            cliprect.origin.x += (p.x -touchPoint.x);
            cliprect.origin.y += (p.y -touchPoint.y);
            if (cliprect.origin.x<-HanlfOfCircleWidth) {
                cliprect.origin.x=-HanlfOfCircleWidth;
            }else if(cliprect.origin.x>self.bounds.size.width + HanlfOfCircleWidth-cliprect.size.width)
            {
                cliprect.origin.x=self.bounds.size.width + HanlfOfCircleWidth-cliprect.size.width;
            }
            if (cliprect.origin.y<-HanlfOfCircleWidth) {
                cliprect.origin.y=-HanlfOfCircleWidth;
            }else if(cliprect.origin.y>self.bounds.size.height + HanlfOfCircleWidth-cliprect.size.height)
            {
                cliprect.origin.y=self.bounds.size.height + HanlfOfCircleWidth-cliprect.size.height;
            }
        }
        //修改rect
        isMoving=YES;
        [self ChangeclipEDGE:x1 x2:x2 y1:y1 y2:y2];
        touchPoint = p;
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    cropTouchPoint=CropNone;
    CGPoint touchEndPoint = [[[event allTouches] anyObject] locationInView:self];
    
    if(iPhone4s){
        float sqrtx =  sqrt(pow((touchEndPoint.x -touchBeginPoint.x),2) + pow(touchEndPoint.y -touchBeginPoint.y,2));
        if(sqrtx<5){
            _playBtn.hidden = NO;//!_playBtn.hidden;
            if(_delegate){
                if([_delegate respondsToSelector:@selector(touchesEndSuperView)]){
                    [_delegate  touchesEndSuperView];
                }
            }
        }
        
    }else{
        if(CGPointEqualToPoint(touchBeginPoint, touchEndPoint) && _fileType == 1){
            _playBtn.hidden = NO;//!_playBtn.hidden;
            if(_delegate){
                if([_delegate respondsToSelector:@selector(touchesEndSuperView)]){
                    [_delegate  touchesEndSuperView];
                }
            }
        }
    }
}

//休整剪切区域
- (void)ChangeclipEDGE:(float)x1 x2:(float)x2 y1:(float)y1 y2:(float)y2
{
//    NSLog(@"x:%f w:%f y:%f h:%f",x1,x2,y1,y2);
    
    cliprect.origin.x += x1;
    cliprect.size.width -= x1;
    cliprect.origin.y += y1;
    cliprect.size.height -= y1;
    cliprect.size.width += x2;
    cliprect.size.height += y2;
    
    BOOL bUpdate=YES;
    if (cliprect.origin.x<-HanlfOfCircleWidth) {
        cliprect.origin.x=-HanlfOfCircleWidth;
        bUpdate=NO;
    }
    if (cliprect.origin.y<-HanlfOfCircleWidth) {
        cliprect.origin.y=-HanlfOfCircleWidth;
        bUpdate=NO;
    }
    if (cliprect.origin.x+cliprect.size.width>oFrame.size.width + HanlfOfCircleWidth) {
        cliprect.size.width=oFrame.size.width + HanlfOfCircleWidth-cliprect.origin.x;
        bUpdate=NO;
    }
    if (cliprect.origin.y+cliprect.size.height>oFrame.size.height + HanlfOfCircleWidth) {
        cliprect.size.height=oFrame.size.height + HanlfOfCircleWidth-cliprect.origin.y;
        bUpdate=NO;
    }
    
    if (bUpdate) {
        [self setNeedsDisplay];
    }
    if([_delegate respondsToSelector:@selector(cropViewDidChangeClipValue:clipRect:)]){
        [_delegate cropViewDidChangeClipValue:[self getclipRect] clipRect:[self getclipRectFrame]];
    }
}

- (void)tapSelfGesture:(UITapGestureRecognizer *)gesture{
    _playBtn.hidden = NO;//!_playBtn.hidden;
    if(_delegate){
        if([_delegate respondsToSelector:@selector(touchesEndSuperView)]){
            [_delegate  touchesEndSuperView];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder] touchesEnded:touches withEvent:event];
    [self touchesEnded:touches withEvent:event];
}


- (void)setclipEDGE:(CGRect)rect
{
    cliprect = rect;
    [self setNeedsDisplay];
}

- (CGFloat)getclipRectScale{
    float imgsize = videoSize.width;
    float viewsize = oFrame.size.width;
    
    float scale = imgsize/viewsize;
    return scale;
}

- (CGRect)getclipRectFrame{
    return CGRectInset(cliprect, HanlfOfCircleWidth, HanlfOfCircleWidth);
}

- (CGRect)getclipRect
{
    float imgsize = videoSize.width;
    float viewsize = oFrame.size.width;
    
    float scale = imgsize/viewsize;
    CGRect clipRect = CGRectInset(cliprect, HanlfOfCircleWidth, HanlfOfCircleWidth);
    CGRect r = CGRectMake(clipRect.origin.x*scale, clipRect.origin.y*scale, clipRect.size.width*scale, clipRect.size.height*scale);
  
    CGRect v_r = CGRectZero;
    if (_crop_Type == kCropTypeFixedRatio) {
        v_r.origin.x = clipRect.origin.x/oFrame.size.width;
        v_r.origin.y = clipRect.origin.y/oFrame.size.height;
        v_r.size.width = clipRect.size.width/oFrame.size.width;
        v_r.size.height = clipRect.size.height/oFrame.size.height;
    }else {
        v_r.origin.x = r.origin.x/videoSize.width;
        v_r.origin.y = r.origin.y/videoSize.height;
        v_r.size.width = r.size.width/videoSize.width;
        v_r.size.height = r.size.height/videoSize.height;
    }
    return v_r;
    
}

-(void)setClipRect:(CGRect)rect
{
    if(CGRectEqualToRect(rect, CGRectZero)){
        return;
    }
    cliprect = CGRectInset(rect, -HanlfOfCircleWidth, -HanlfOfCircleWidth);
    [self setNeedsDisplay];
}

- (void)dealloc {
    _delegate = nil;
    NSLog(@"%s",__func__);
}


@end
