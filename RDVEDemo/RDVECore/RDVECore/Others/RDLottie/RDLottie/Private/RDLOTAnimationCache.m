//
//  RDLOTAnimationCache.m
//  RDLottie
//
//  Created by Brandon Withrow on 1/9/17.
//  Copyright © 2017 Brandon Withrow. All rights reserved.
//

#import "RDLOTAnimationCache.h"

const NSInteger kRDLOTCacheSize = 50;

@implementation RDLOTAnimationCache {
  NSMutableDictionary *animationsCache_;
  NSMutableArray *lruOrderArray_;
}

+ (instancetype)sharedCache {
  static RDLOTAnimationCache *sharedCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedCache = [[self alloc] init];
  });
  return sharedCache;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    animationsCache_ = [[NSMutableDictionary alloc] init];
    lruOrderArray_ = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)addAnimation:(RDLOTComposition *)animation forKey:(NSString *)key {
  if (lruOrderArray_.count >= kRDLOTCacheSize) {
    NSString *oldKey = lruOrderArray_[0];
    [animationsCache_ removeObjectForKey:oldKey];
    [lruOrderArray_ removeObject:oldKey];
  }
  [lruOrderArray_ removeObject:key];
  [lruOrderArray_ addObject:key];
  [animationsCache_ setObject:animation forKey:key];
}

- (RDLOTComposition *)animationForKey:(NSString *)key {
  if (!key) {
    return nil;
  }
  RDLOTComposition *animation = [animationsCache_ objectForKey:key];
  [lruOrderArray_ removeObject:key];
  [lruOrderArray_ addObject:key];
  return animation;
}

- (void)clearCache {
  [animationsCache_ removeAllObjects];
  [lruOrderArray_ removeAllObjects];
}

- (void)removeAnimationForKey:(NSString *)key {
  [lruOrderArray_ removeObject:key];
  [animationsCache_ removeObjectForKey:key];
}

- (void)disableCaching {
  [self clearCache];
  animationsCache_ = nil;
  lruOrderArray_ = nil;
}

@end
