/*
 *  ATMHudDelegate.h
 *  ATMHud
 *
 *  Created by Marcel Müller on 2011-03-01.
 *  Copyright (c) 2010-2011, Marcel Müller (atomcraft)
 *  All rights reserved.
 *
 *	https://github.com/atomton/ATMHud
 */

@class RDATMHud;

@protocol RDATMHudDelegate

@optional
- (void)userDidTapHud:(RDATMHud *)_hud;
- (void)hudWillAppear:(RDATMHud *)_hud;
- (void)hudDidAppear:(RDATMHud *)_hud;
- (void)hudWillUpdate:(RDATMHud *)_hud;
- (void)hudDidUpdate:(RDATMHud *)_hud;
- (void)hudWillDisappear:(RDATMHud *)_hud;
- (void)hudDidDisappear:(RDATMHud *)_hud;

@end
