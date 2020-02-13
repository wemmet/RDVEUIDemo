//
//  RDLottie.h
//  Pods
//
//  Created by brandon_withrow on 1/27/17.
//
//  Dream Big.

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#ifndef RDLottie_h
#define RDLottie_h

//! Project version number for RDLottie.
FOUNDATION_EXPORT double RDLottieVersionNumber;

//! Project version string for RDLottie.
FOUNDATION_EXPORT const unsigned char RDLottieVersionString[];

#include <TargetConditionals.h>

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import "RDLOTAnimationTransitionController.h"
#import "RDLOTAnimatedSwitch.h"
#import "RDLOTAnimatedControl.h"
#endif

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import "RDLOTCacheProvider.h"
#endif

#import "RDLOTAnimationView.h"
#import "RDLOTAnimationCache.h"
#import "RDLOTComposition.h"
#import "RDLOTBlockCallback.h"
#import "RDLOTInterpolatorCallback.h"
#import "RDLOTValueCallback.h"
#import "RDLOTValueDelegate.h"

#endif /* RDLottie_h */
