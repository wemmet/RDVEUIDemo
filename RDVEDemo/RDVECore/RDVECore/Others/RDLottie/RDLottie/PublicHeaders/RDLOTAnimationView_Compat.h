//
//  RDLOTAnimationView_Compat.h
//  RDLottie
//
//  Created by Oleksii Pavlovskyi on 2/2/17.
//  Copyright (c) 2017 Airbnb. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR

#import <UIKit/UIKit.h>
@compatibility_alias RDLOTView UIView;

#else

#import <AppKit/AppKit.h>
@compatibility_alias RDLOTView NSView;

typedef NS_ENUM(NSInteger, RDLOTViewContentMode) {
    RDLOTViewContentModeScaleToFill,
    RDLOTViewContentModeScaleAspectFit,
    RDLOTViewContentModeScaleAspectFill,
    RDLOTViewContentModeRedraw,
    RDLOTViewContentModeCenter,
    RDLOTViewContentModeTop,
    RDLOTViewContentModeBottom,
    RDLOTViewContentModeLeft,
    RDLOTViewContentModeRight,
    RDLOTViewContentModeTopLeft,
    RDLOTViewContentModeTopRight,
    RDLOTViewContentModeBottomLeft,
    RDLOTViewContentModeBottomRight,
};

#endif

