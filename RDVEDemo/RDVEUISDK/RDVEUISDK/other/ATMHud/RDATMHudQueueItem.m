/*
 *  ATMHudQueueItem.m
 *  ATMHud
 *
 *  Created by Marcel Müller on 2011-03-01.
 *  Copyright (c) 2010-2011, Marcel Müller (atomcraft)
 *  All rights reserved.
 *
 *	https://github.com/atomton/ATMHud
 */

#import "RDATMHudQueueItem.h"

@implementation RDATMHudQueueItem
@synthesize caption, image, showActivity, accessoryPosition, activityStyle;

- (id)init {
	if ((self = [super init])) {
		caption = @"";
		image = nil;
		showActivity = NO;
		accessoryPosition = ATMHudAccessoryPositionBottom;
		activityStyle = UIActivityIndicatorViewStyleWhite;
	}
	return self;
}

- (void)dealloc {
    NSLog(@"%s",__func__);
    caption = nil;
    image = nil;
    
}

@end
