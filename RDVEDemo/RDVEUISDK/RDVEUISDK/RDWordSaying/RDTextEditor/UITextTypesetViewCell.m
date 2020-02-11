//
//  UITextTypesetViewCell.m
//  RDVEUISDK
//
//  Created by apple on 2019/8/16.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "UITextTypesetViewCell.h"
#import "RDHelpClass.h"

#define HEIGHT 20

@implementation RDTextObject

- (instancetype)init{
    self = [super init];
    if(self){
        self.startTime = kCMTimeZero;
        self.showTime = kCMTimeZero;
        self.textRotationTime = kCMTimeZero;   //旋转时间 用于需要旋转的自绘对象
        self.textRadian = 0;
        
        //字体
        self.fontName = nil;
        self.textFontSize = 0.0;
        //阴影
        self.textFontshadow = 0.0;
        self.textColorShadow = [UIColor clearColor];
        //描边
        self.textFontStroke = 0.0;
        self.textFontStrokeColor = [UIColor clearColor];
        //字体颜色
        self.textColor = [UIColor clearColor];
        self.strText = nil;
        self.textFontSizeSpeed = 0.0;
    }
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    RDTextObject *copy = [[[self class] allocWithZone:zone] init];
    
    copy.startTime = _startTime;
    copy.AnimationTime = _AnimationTime;
    copy.showTime = _showTime;
    copy.textRotationTime = _textRotationTime;   //旋转时间 用于需要旋转的自绘对象
    copy.textRadian = _textRadian;
    
    //字体
    copy.fontName = _fontName;
    copy.textFontSize = _textFontSize;
    //阴影
    copy.textColorShadow = _textColorShadow;
    copy.textFontshadow = _textFontshadow;
    //描边
    copy.textFontStroke = _textFontStroke;
    copy.textFontStrokeColor = _textFontStrokeColor;
    //字体颜色
    copy.textColor = _textColor;
    copy.strText = _strText;
    
    copy.textFontSizeSpeed = _textFontSizeSpeed;
    return copy;
}

- (id)copyWithZone:(NSZone *)zone{
    RDTextObject *copy = [[[self class] allocWithZone:zone] init];
    
    copy.startTime = _startTime;
    copy.AnimationTime = _AnimationTime;
    copy.showTime = _showTime;
    copy.textRotationTime = _textRotationTime;   //旋转时间 用于需要旋转的自绘对象
    copy.textRadian = _textRadian;
    
    //字体
    copy.fontName = _fontName;
    copy.textFontSize = _textFontSize;
    //阴影
    copy.textColorShadow = _textColorShadow;
    copy.textFontshadow = _textFontshadow;
    //描边
    copy.textFontStroke = _textFontStroke;
    copy.textFontStrokeColor = _textFontStrokeColor;
    //字体颜色
    copy.textColor = _textColor;
    copy.strText = _strText;
    
    copy.textFontSizeSpeed = _textFontSizeSpeed;
    return copy;
}


@end

@implementation UITextTypesetViewCell

- (void)addLayer:(UIView *)view
{
    /* 初始化一个layer */
    CAShapeLayer *border = [CAShapeLayer layer];
    /* 虚线的颜色 */
    border.strokeColor = Main_Color.CGColor;
    /* 填充虚线内的颜色 */
    border.fillColor = nil;
    /* 贝塞尔曲线路径 */
    border.path = [UIBezierPath bezierPathWithRect:CGRectMake(2, 2, view.frame.size.width- 4, view.frame.size.height - 4)].CGPath;
    /* 虚线宽度 */
    border.lineWidth = 1.0f;
    //border.frame = view.bounds; /* 这个因为给了路径, 而且用的约束给的控件尺寸, 所以没什么效果 */
    /* 官方API注释:The cap style used when stroking the path. Options are `butt', `round'
     * and `square'. Defaults to `butt'. */
    /* 意思是沿路径画帽时的样式 有三种 屁股 ; 圆; 广场 ,我没感觉有啥区别 可以自己试一下*/
    border.lineCap = @"square";
    /* 虚线的每个点长  和 两个点之间的空隙 */
    border.lineDashPattern = @[@3, @2];
    /* 添加到你的控件上 */
    [view.layer addSublayer:border];
}

-(void)dottedLine:(bool) isLine
{
    {
        // 画虚线
        // 创建一个imageView 高度是你想要的虚线的高度 一般设为2
        UIImageView * _lineImg = [[UIImageView alloc] initWithFrame:CGRectMake(10+HEIGHT/2.0, 0, 1.0, (self.frame.size.height-HEIGHT)/2.0)];
        // 调用方法 返回的iamge就是虚线
        _lineImg.image = [self drawLineByImageView:_lineImg lineColor:UIColorFromRGB(0x838383)];
        // 添加到控制器的view上
        [self addSubview:_lineImg];
    }
    
    if( isLine )
    {
        // 画虚线
        // 创建一个imageView 高度是你想要的虚线的高度 一般设为2
        UIImageView * _lineImg = [[UIImageView alloc] initWithFrame:CGRectMake(10+HEIGHT/2.0, (self.frame.size.height-HEIGHT)/2.0 + _selectBtn.frame.size.height, 1.0, (self.frame.size.height-HEIGHT)/2.0)];
        // 调用方法 返回的iamge就是虚线
        _lineImg.image = [self drawLineByImageView:_lineImg lineColor:UIColorFromRGB(0x838383)];
        // 添加到控制器的view上
        [self addSubview:_lineImg];
    }
}

// 返回虚线image的方法
- (UIImage *)drawLineByImageView:(UIImageView *)imageView lineColor:(UIColor *) lineColor{
    UIGraphicsBeginImageContext(imageView.frame.size); //开始画线 划线的frame
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextRef context =UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    CGContextSetLineWidth(context,1);
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGFloat lengths[] = {2,1.5};
    CGContextSetLineDash(context, 0, lengths,2);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 0,imageView.frame.size.height);
    CGContextStrokePath(context);
    CGContextClosePath(context);
    return UIGraphicsGetImageFromCurrentImageContext();
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _selectBtn = [[UIButton alloc] init];
        _selectBtn.frame = CGRectMake( 10, (self.frame.size.height-HEIGHT)/2.0, HEIGHT, HEIGHT);
        [_selectBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_单选_默认" Type:@"png"]] forState:UIControlStateNormal];
        [_selectBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_单选_选中" Type:@"png"]] forState:UIControlStateSelected];
        [_selectBtn addTarget:self action:@selector( select_Btn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_selectBtn];
        
        _selectLabel = [[UIImageView alloc] initWithFrame:CGRectMake( 10, (self.frame.size.height-HEIGHT)/2.0, HEIGHT, HEIGHT)];
        _selectLabel.image = [RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/TextToSpeech/文转音_单选_禁用" Type:@"png"]];
        _selectLabel.hidden = YES;
        [self addSubview:_selectLabel];
//        // 画虚线
//        // 创建一个imageView 高度是你想要的虚线的高度 一般设为2
//        UIImageView * _lineImg = [[UIImageView alloc] initWithFrame:CGRectMake(10+19.5, 0, 1.0, self.frame.size.height)];
//        // 调用方法 返回的iamge就是虚线
//        _lineImg.image = [self drawLineByImageView:_lineImg lineColor:UIColorFromRGB(0x838383)];
//        // 添加到控制器的view上
//        [self addSubview:_lineImg];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(_selectBtn.frame.size.width+_selectBtn.frame.origin.x-5 +5, 5, self.frame.size.width-(_selectBtn.frame.size.width+_selectBtn.frame.origin.x+10) - 10 + 10 - 5, self.frame.size.height - 10 )];
//        [self addLayer:view];
        [self addSubview:view];
        
        _selectView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
        [self addLayer:_selectView];
        [view addSubview:_selectView];
        _selectView.hidden = YES;
        
        _textField = [[UITextFieldKeybordDelete alloc] initWithFrame:CGRectMake(5, 5, view.frame.size.width - 10, view.frame.size.height-10)];
        _textField.text = @"床前明月光";
        _textField.font = [UIFont boldSystemFontOfSize:32];
        _textField.textColor = [UIColor whiteColor];
        
        
        
        [view addSubview:_textField];
    }
    return self;
}

-(void)select_Btn:(UIButton*) sender
{
    sender.selected = !sender.selected;
    _selectView.hidden = !sender.selected;
    
    if( [_delegate respondsToSelector:@selector(select)] )
    {
        [_delegate select];
    }
}

-(void)setSelect:(BOOL) select
{
    _selectBtn.selected = select;
    _selectView.hidden = !select;
}

-(void)setTextFieldTag:(int) tag
{
    _textField.tag = tag;
}

-(void)setText:(NSString*) text
{
    _textField.text = text;
    _textObject.strText = text;
    if( text.length == 0 )
    {
        [self setEndle: true];
    }
}

-(void)setEndle:(bool) isEndle
{
    if( isEndle )
    {
        _selectBtn.hidden = YES;
        _selectLabel.hidden = NO;
    }
    else
    {
        _selectBtn.hidden = NO;
        _selectLabel.hidden = YES;
    }
}

-(void)setshadow:(float)shadowSize secondColor:(UIColor*)secondColor
{
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 1;
    shadow.shadowColor = secondColor;
    shadow.shadowOffset = CGSizeMake(shadowSize, shadowSize);
    NSDictionary *myDic = @{
                             NSStrokeColorAttributeName:_textObject.textFontStrokeColor,
                            NSStrokeWidthAttributeName: [NSNumber numberWithFloat:-_textObject.textFontStroke],
                             NSShadowAttributeName: shadow,
                            };
    _textField.attributedText = [[NSAttributedString alloc] initWithString:_textField.text attributes:myDic];
    _textObject.textFontshadow = shadowSize;
    _textObject.textColorShadow = secondColor;
}

-(void)setTextStroke:(UIColor *) strokeColor atStrokeSize:(float) strokeSize
{
    if( strokeColor != nil )
    {
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 1;
        shadow.shadowColor = _textObject.textColorShadow;
        shadow.shadowOffset = CGSizeMake(_textObject.textFontshadow, _textObject.textFontshadow);
        NSDictionary *myDic = @{
                                NSStrokeColorAttributeName:strokeColor,
                                NSStrokeWidthAttributeName: [NSNumber numberWithFloat:-strokeSize],
                                NSShadowAttributeName: shadow,
                                };
        _textField.attributedText = [[NSAttributedString alloc] initWithString:_textField.text attributes:myDic];
        _textObject.textFontStroke = strokeSize;
        _textObject.textFontStrokeColor = strokeColor;
    }
}
-(void)setTextFont:(NSString *)fontName
{
    _textField.font = [UIFont fontWithName:fontName size:32];
    _textObject.fontName = fontName;
}
-(void)setTextColor:(UIColor *)fontColor
{
    _textField.textColor = fontColor;
    _textObject.textColor  = fontColor;
}

-(BOOL)firstColor:(UIColor*)firstColor secondColor:(UIColor*)secondColor
{
    if (CGColorEqualToColor(firstColor.CGColor, secondColor.CGColor))
    {
        NSLog(@"颜色相同");
        return YES;
    }
    else
    {
        NSLog(@"颜色不同");
        return NO;
    }
}

-(void)setTextObject:(RDTextObject*) textObject
{
    _textField.font = [UIFont fontWithName:textObject.fontName size:32];
    if( ![self firstColor:textObject.textColor secondColor:[UIColor blackColor] ] )
        _textField.textColor = textObject.textColor;
    else
        _textField.textColor = [UIColor whiteColor];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 1;
    shadow.shadowColor = textObject.textColorShadow;
    shadow.shadowOffset = CGSizeMake(textObject.textFontshadow, textObject.textFontshadow);
        
    NSDictionary *myDic = @{            NSStrokeColorAttributeName:textObject.textFontStrokeColor,
                            NSStrokeWidthAttributeName: [NSNumber numberWithFloat:-textObject.textFontStroke],
                                        NSShadowAttributeName:shadow,
                            };
    _textField.attributedText = [[NSAttributedString alloc] initWithString:_textField.text attributes:myDic];
    _textObject = textObject;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
