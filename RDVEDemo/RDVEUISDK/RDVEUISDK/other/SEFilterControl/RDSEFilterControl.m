//
//  SEFilterControl.m
//  SEFilterControl_Test
//
//  Created by Shady A. Elyaski on 6/13/12.
//  Copyright (c) 2012 mash, ltd. All rights reserved.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RDSEFilterControl.h"
#define LEFT_OFFSET 20
#define RIGHT_OFFSET 20
#define TITLE_SELECTED_DISTANCE 5
#define TITLE_FADE_ALPHA .5f
#define TITLE_FONT [UIFont fontWithName:@"Optima" size:14]
#define TITLE_SHADOW_COLOR [UIColor lightGrayColor]
#define TITLE_COLOR [UIColor blackColor]

@interface RDSEFilterControl (){
    RDSEFilterKnob *handler;
    CGPoint diffPoint;
    
    float oneSlotSize;
    
    
    
}
@end

@implementation RDSEFilterControl
@synthesize SelectedIndex, progressColor;

-(CGPoint)getCenterPointForIndex:(int) i{
    return CGPointMake((i/(float)(_titlesArr.count-1)) * (self.frame.size.width-RIGHT_OFFSET-LEFT_OFFSET) + LEFT_OFFSET, i==0?self.frame.size.height-55-TITLE_SELECTED_DISTANCE:self.frame.size.height-55);
}

-(CGPoint)fixFinalPoint:(CGPoint)pnt{
    if (pnt.x < LEFT_OFFSET-(handler.frame.size.width/2.f)) {
        pnt.x = LEFT_OFFSET-(handler.frame.size.width/2.f);
    }else if (pnt.x+(handler.frame.size.width/2.f) > self.frame.size.width-RIGHT_OFFSET){
        pnt.x = self.frame.size.width-RIGHT_OFFSET- (handler.frame.size.width/2.f);
    }
    return pnt;
}

-(id) initWithFrame:(CGRect) frame Titles:(NSArray *) titles{

    if (self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)]) {
        [self setBackgroundColor:[UIColor clearColor]];
        _titlesArr = [[NSMutableArray alloc] initWithArray:titles];
        
        [self setProgressColor:[UIColor colorWithRed:57/255.f green:185/255.f blue:238/255.f alpha:0.98]];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(ItemSelected:)];
        [self addGestureRecognizer:gest];
        float width = (self.frame.size.width-4*1)/5;
        
        for(int i=0;i<5;i++){
            UILabel *label = [[UILabel alloc] init];
            label.frame = CGRectMake((width+2)*i, 0, width, 40);
            label.backgroundColor = UIColorFromRGB(0x42424c);
            label.font = [UIFont systemFontOfSize:13];
            label.textColor = UIColorFromRGB(0x888888);
            label.tag = i+1;
            label.textAlignment = NSTextAlignmentCenter;
            
            [self addSubview:label];
        }
        
        handler = [RDSEFilterKnob buttonWithType:UIButtonTypeCustom];
        [handler setFrame:CGRectMake(LEFT_OFFSET, 8,width+4, self.frame.size.height+5)];
        [handler setAdjustsImageWhenHighlighted:NO];
        [handler setHandlerColor:UIColorFromRGB(0xffffff)];
        [handler setCenter:CGPointMake(handler.center.x-(handler.frame.size.width/2.f), self.frame.size.height-19.5f)];
        [handler addTarget:self action:@selector(TouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [handler addTarget:self action:@selector(TouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        [handler addTarget:self action:@selector(TouchMove:withEvent:) forControlEvents: UIControlEventTouchDragOutside | UIControlEventTouchDragInside];
        [self addSubview:handler];
        
        oneSlotSize = 1.f*(self.frame.size.width-LEFT_OFFSET-RIGHT_OFFSET-1)/(_titlesArr.count-1);
        SelectedIndex = 1;
        
        
        
    }
    return self;
}

-(void) setHandlerColor:(UIColor *)color{
    [handler setHandlerColor:color];
}

- (void) TouchDown: (UIButton *) btn withEvent: (UIEvent *) ev{
    CGPoint currPoint = [[[ev allTouches] anyObject] locationInView:self];
    diffPoint = CGPointMake(currPoint.x - btn.frame.origin.x, currPoint.y - btn.frame.origin.y);
    [self sendActionsForControlEvents:UIControlEventTouchDown];
}

-(void) setTitlesColor:(UIColor *)color{
    int i;
    UILabel *lbl;
    for (i = 0; i < _titlesArr.count; i++) {
        lbl = (UILabel *)[self viewWithTag:i+50];
        [lbl setTextColor:color];
    }
}

-(void) setTitlesFont:(UIFont *)font{
    int i;
    UILabel *lbl;
    for (i = 0; i < _titlesArr.count; i++) {
        lbl = (UILabel *)[self viewWithTag:i+50];
        [lbl setFont:font];
    }
}

-(void) animateTitlesToIndex:(int) index{
    int i;
    UILabel *lbl;
    for (i = 0; i < _titlesArr.count; i++) {
        lbl = (UILabel *)[self viewWithTag:i+50];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        if (i == index) {
            [lbl setCenter:CGPointMake(lbl.center.x, self.frame.size.height-55-TITLE_SELECTED_DISTANCE)];
            [lbl setAlpha:1];
        }else{
            [lbl setCenter:CGPointMake(lbl.center.x, self.frame.size.height-55)];
            [lbl setAlpha:TITLE_FADE_ALPHA];
        }
        [UIView commitAnimations];
        
    }
}

-(void) animateHandlerToIndex:(int) index{
    CGPoint toPoint = [self getCenterPointForIndex:index];
    toPoint = CGPointMake(toPoint.x-(handler.frame.size.width/2.f), handler.frame.origin.y);
    toPoint = [self fixFinalPoint:toPoint];
    
    
   // [UIView animateWithDuration:0.1 animations:^{
        [handler setFrame:CGRectMake(toPoint.x, toPoint.y, handler.frame.size.width, handler.frame.size.height)];
   // } completion:^(BOOL finished) {
        UILabel *lab = (UILabel *)[self viewWithTag:SelectedIndex+1];
        [handler setCenter:lab.center];
   // }];
}

-(void) setSelectedIndex:(int)index{
    SelectedIndex = index;
    [self animateTitlesToIndex:index];
    [self animateHandlerToIndex:index];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [handler setSelectIndex:SelectedIndex];
    [handler changeTitle];
    if(_delegate){
        if ([_delegate respondsToSelector:@selector(filterValueChanged:reduction:)]) {
            [_delegate filterValueChanged:self.SelectedIndex reduction:[NSNumber numberWithBool:NO]];
            
            _lastSelectedIndex = SelectedIndex;
        }
    }
}

-(int)getSelectedTitleInPoint:(CGPoint)pnt{
    return round((pnt.x-LEFT_OFFSET)/oneSlotSize);
}

-(void) ItemSelected: (UITapGestureRecognizer *) tap {
   
    SelectedIndex = [self getSelectedTitleInPoint:[tap locationInView:self]];
    
    [self setSelectedIndex:SelectedIndex];
    [handler setSelectIndex:SelectedIndex];
    [handler changeTitle];
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

-(void) TouchUp: (UIButton*) btn{
    
    SelectedIndex = [self getSelectedTitleInPoint:btn.center];
    
   
    [handler setSelectIndex:SelectedIndex];
    [handler changeTitle];
    [self animateHandlerToIndex:SelectedIndex];
    
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    if(_delegate){
        if ([_delegate respondsToSelector:@selector(filterValueChanged:reduction:)]) {
            [_delegate filterValueChanged:self.SelectedIndex reduction:[NSNumber numberWithBool: NO ]];
            _lastSelectedIndex = SelectedIndex;
        }
    }
}

- (void) TouchMove: (UIButton *) btn withEvent: (UIEvent *) ev {
    CGPoint currPoint = [[[ev allTouches] anyObject] locationInView:self];
    CGPoint toPoint = CGPointMake(currPoint.x-diffPoint.x, handler.frame.origin.y);
    
    toPoint = [self fixFinalPoint:toPoint];

    [handler setFrame:CGRectMake(toPoint.x, toPoint.y, handler.frame.size.width, handler.frame.size.height)];
    [handler setSelectIndex:SelectedIndex];
    [handler changeTitle];
    
    int selected = [self getSelectedTitleInPoint:btn.center];
    
    [self animateTitlesToIndex:selected];
    
    [self sendActionsForControlEvents:UIControlEventTouchDragInside];
    
}
- (void)setType:(RDFileType)type{
    
    handler.type = type;
 
}

- (void)setTitlesArr:(NSMutableArray *)titlesArr{
    for (int i=0;i<titlesArr.count;i++) {
        UILabel *label = (UILabel *)[self viewWithTag:i+1];
        label.text = titlesArr[i];
    }
    
    handler.titleArr = titlesArr;
}

- (void)drawRect:(CGRect)rect{
    
}

-(void)dealloc{
    _delegate = nil;
    NSLog(@"%s",__func__);
}
@end
