//
//  SEFilterKnob.m
//  SEFilterControl_Test
//
//  Created by Shady A. Elyaski on 6/15/12.
//  Copyright (c) 2012 mash, ltd. All rights reserved.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "RDSEFilterKnob.h"
@interface RDSEFilterKnob(){

}
@property (nonatomic, strong) NSString *handleTitle;
@end

@implementation RDSEFilterKnob

@synthesize handlerColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setHandlerColor:UIColorFromRGB(0x33333b)];//[UIColor colorWithRed:230/255.f green:230/255.f blue:230/255.f alpha:1]];
        
    }
    return self;
}

-(void) setHandlerColor:(UIColor *)hc{
    handlerColor = nil;
    self.backgroundColor = hc;
    handlerColor = hc;
    
    [self setNeedsDisplay];
}

- (void)changeTitle
{
            if(_selectIndex==0){
                if(_type == kFILEIMAGE || _type == kTEXTTITLE){
                    _handleTitle = _titleArr[0];
                }else{
                    _handleTitle = @"1/4";
                }
            }else if(_selectIndex==1){
                if(_type == kFILEIMAGE || _type == kTEXTTITLE){
                    _handleTitle = _titleArr[1];
                }else{
                    _handleTitle = @"1/2";
                }
            }else if(_selectIndex==2){
                if(_type == kFILEIMAGE || _type == kTEXTTITLE){
                    _handleTitle = _titleArr[2];
                }else{
                    _handleTitle = @"x1";
                }
            }else if(_selectIndex==3){
                if(_type == kFILEIMAGE || _type == kTEXTTITLE){
                    _handleTitle = _titleArr[3];
                }else{
                   _handleTitle = @"x2";
                }
            }else if(_selectIndex==4){
                if(_type == kFILEIMAGE || _type == kTEXTTITLE){
                    _handleTitle = _titleArr[4];
                }else{
                    _handleTitle = @"x4";
                }
            }
    [self setTitle:_handleTitle forState:UIControlStateNormal];
    [self setTitle:_handleTitle forState:UIControlStateHighlighted];
    [self setTitleColor:UIColorFromRGB(0x33333b) forState:UIControlStateNormal];
    [self setTitleColor:UIColorFromRGB(0x33333b) forState:UIControlStateHighlighted];

}

-(void) dealloc{
    NSLog(@"%s",__func__);
}

@end
