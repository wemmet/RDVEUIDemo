//
//  RDLOTAnimationCache.h
//  RDLottie
//
//  Created by Brandon Withrow on 1/9/17.
//  Copyright © 2017 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RDLOTComposition;

@interface RDLOTAnimationCache : NSObject

/// Global Cache
+ (instancetype)sharedCache;

/// Adds animation to the cache
- (void)addAnimation:(RDLOTComposition *)animation forKey:(NSString *)key;

/// Returns animation from cache.
- (RDLOTComposition * _Nullable)animationForKey:(NSString *)key;

/// Removes a specific animation from the cache
- (void)removeAnimationForKey:(NSString *)key;

/// Clears Everything from the Cache
- (void)clearCache;

/// Disables Caching Animation Model Objects
- (void)disableCaching;

@end

NS_ASSUME_NONNULL_END
