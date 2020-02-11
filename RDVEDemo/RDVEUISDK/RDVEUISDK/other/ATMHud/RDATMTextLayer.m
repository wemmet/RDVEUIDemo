/*
 *  ATMTextLayer.m
 *  ATMHud
 *
 *  Created by Marcel Müller on 2011-03-01.
 *  Copyright (c) 2010-2011, Marcel Müller (atomcraft)
 *  All rights reserved.
 *
 *	https://github.com/atomton/ATMHud
 */

#import "RDATMTextLayer.h"
#import <UIKit/UIKit.h>
@implementation RDATMTextLayer
@synthesize caption;

- (id)initWithLayer:(id)layer {
	if ((self = [super init])) {
		caption = @"";
	}
	return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
	if ([key isEqualToString:@"caption"]) {
		return YES;
	} else {
		return [super needsDisplayForKey:key];
	}
}

- (void)drawInContext:(CGContextRef)ctx {
	UIGraphicsPushContext(ctx);
	
	CGRect f = self.bounds;
	CGRect s = f;
	s.origin.y -= 1;
	
    NSMutableParagraphStyle *paragraphStylef = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStylef.lineBreakMode = NSLineBreakByCharWrapping;
    paragraphStylef.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributef=@{
                              NSFontAttributeName:[UIFont boldSystemFontOfSize:14],
                              NSParagraphStyleAttributeName:paragraphStylef,
                              NSForegroundColorAttributeName:[UIColor blackColor]
                              };
    [caption drawInRect:f withAttributes:attributef];

    NSMutableParagraphStyle *paragraphStyles = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyles.lineBreakMode = NSLineBreakByCharWrapping;
    paragraphStyles.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes=@{
                              NSFontAttributeName:[UIFont boldSystemFontOfSize:14],
                              NSParagraphStyleAttributeName:paragraphStyles,
                              NSForegroundColorAttributeName:[UIColor whiteColor]
                              };
    [caption drawInRect:s withAttributes:attributes];
	
	UIGraphicsPopContext();
}

- (void)dealloc {
    NSLog(@"%s",__func__);
    caption = nil;
}

@end
