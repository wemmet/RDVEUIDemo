//
//  SubtitleColorControl.m
//  RDVEUISDK
//
//  Created by apple on 2019/4/9.
//  Copyright © 2019年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "SubtitleColorControl.h"

@interface SubtitleColorControl (){
    
    UIImageView * ImageSlider;      //滑杆
    
}
@end

@implementation SubtitleColorControl

-(void) ItemSelected: (UIPanGestureRecognizer *) tap {
    
    CGPoint point = [tap locationInView:self];
//    NSLog(@"point {%.f,%.f}",point.x,point.y);
    float width = (self.frame.size.width-8)/_colorsArr.count;
    float x = point.x;
    if( point.x <= 4 )
        x = 0.0;
    else if( point.x >=  (self.frame.size.width-4) )
        x = self.frame.size.width-8;
    int index = x/width;
    if( index >=  (_colorsArr.count-1) )
        index = _colorsArr.count-1;
    
    if( _currentColorIndex != index )
    {
        _currentColorIndex = index;
        CGRect Rect = ImageSlider.frame;
        Rect.origin.x = index*(width);
        [ImageSlider setFrame:Rect];
        if( index == 0 )
            ImageSlider.backgroundColor = UIColorFromRGB(0x000000);
        else
            ImageSlider.backgroundColor = _colorsArr[index];
        
        _currentColor = _colorsArr[index];
        if([_delegate respondsToSelector:@selector(SubtitleColorChanged:Index: View:)]){
            [_delegate SubtitleColorChanged:_currentColor  Index:_currentColorIndex  View:self];
        }
    }
}

-(id) initWithFrame:(CGRect) frame Colors:(NSArray *) colors  CurrentColor:(UIColor*) currentColor atisDefault:(BOOL) isDefault{
    
    if (self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)]) {
        _isDefault = isDefault;
        _currentColor = currentColor;
        self.userInteractionEnabled = YES;
        [self setBackgroundColor: [UIColor clearColor] ];
        _colorsArr = [[NSMutableArray alloc] initWithArray:colors];
        
        float width = (self.frame.size.width-8)/_colorsArr.count;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(4, (self.frame.size.height - (width + 4))/2.0, self.frame.size.width - 8, width + 4)];
        
        view.layer.cornerRadius = 1;
        view.layer.masksToBounds = YES;
        view.layer.borderColor = UIColorFromRGB(0x888888).CGColor;
        view.layer.borderWidth = 1;
        
        [self addSubview:view];

        [_colorsArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            UIColor * color = (UIColor *)obj;
            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake((width) * idx, 0, width, width + 4)];
            label.backgroundColor = color;
            [view addSubview:label];
        }];
        
        ImageSlider = [[UIImageView alloc] initWithFrame:CGRectMake( 0 , (self.frame.size.height - (width + 8))/2.0, width + 8, width + 8)];
        ImageSlider.userInteractionEnabled = YES;
        UIPanGestureRecognizer *gest = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(ItemSelected:)];
        ImageSlider.backgroundColor = UIColorFromRGB(0x000000);
        ImageSlider.layer.cornerRadius =  (width + 8)/2.0;
        ImageSlider.layer.masksToBounds = YES;
        ImageSlider.layer.borderColor = UIColorFromRGB(0x888888).CGColor;
        ImageSlider.layer.borderWidth = 1;
        [ImageSlider addGestureRecognizer:gest];
        [self addSubview:ImageSlider];
        
//        [self performSelector:@selector(Value) withObject:nil afterDelay:0.2];
    }
    return self;
}

-(void)Value
{
    [self setValue:_currentColor];
}

-(void)setValue:(UIColor *) color
{
    BOOL isCurrent = true;
    if( _isDefault &&  color == nil )
    {
        color = UIColorFromRGB(0x000000);
        isCurrent = false;
    }
    
    int index = 0;
    CGFloat red1,red2,green1,green2,blue1,blue2,alpha1,alpha2;
    //取出color1的背景颜色的RGBA值
    [color getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
    
    for ( int i = 0; i<((_colorsArr.count-1)); i++) {
        [_colorsArr[i] getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
        if ((red1 == red2)&&(green1 == green2)&&(blue1 == blue2)&&(alpha1 == alpha2)) {
            
            index = i;
            
            break;
        }
    }
    
    float width = (self.frame.size.width-8)/_colorsArr.count;
    CGRect Rect = ImageSlider.frame;
    Rect.origin.x = index*(width);
    [ImageSlider setFrame:Rect];
    
    if( !_isDefault && index == 0 )
        ImageSlider.backgroundColor = UIColorFromRGB(0x000000);
    else
    {
        ImageSlider.backgroundColor = _colorsArr[index];
    }
    
    if( isCurrent )
        _currentColor = color;
    _currentColorIndex = index;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
