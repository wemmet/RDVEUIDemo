//
//  RDLOTScene.m
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "RDLOTComposition.h"
#import "RDLOTLayer.h"
#import "RDLOTAssetGroup.h"
#import "RDLOTLayerGroup.h"
#import "RDLOTAnimationCache.h"

@implementation RDLOTComposition

# pragma mark - Convenience Initializers

+ (nullable instancetype)animationNamed:(nonnull NSString *)animationName {
  return [self animationNamed:animationName inBundle:[NSBundle mainBundle]];
}

+ (nullable instancetype)animationNamed:(nonnull NSString *)animationName inBundle:(nonnull NSBundle *)bundle {
  NSArray *components = [animationName componentsSeparatedByString:@"."];
  animationName = components.firstObject;
  
  RDLOTComposition *comp = [[RDLOTAnimationCache sharedCache] animationForKey:animationName];
  if (comp) {
    return comp;
  }
  
  NSError *error;
  NSString *filePath = [bundle pathForResource:animationName ofType:@"json"];
  NSData *jsonData = [[NSData alloc] initWithContentsOfFile:filePath];
  
  if (@available(iOS 9.0, *)) {
    if (!jsonData) {
      jsonData = [[NSDataAsset alloc] initWithName:animationName].data;
    }
  }
  
  NSDictionary  *JSONObject = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData
                                                                         options:0 error:&error] : nil;
    jsonData = nil;
  if (JSONObject && !error) {
    RDLOTComposition *laScene = [[self alloc] initWithJSON:JSONObject withAssetBundle:bundle];
    [[RDLOTAnimationCache sharedCache] addAnimation:laScene forKey:animationName];
    laScene.cacheKey = animationName;
    return laScene;
  }
  NSLog(@"%s: Animation Not Found", __PRETTY_FUNCTION__);
  return nil;
}

+ (nullable instancetype)animationWithFilePath:(nonnull NSString *)filePath {
  NSString *animationName = filePath;
  
  RDLOTComposition *comp = [[RDLOTAnimationCache sharedCache] animationForKey:animationName];
  if (comp) {
    return comp;
  }
  
  NSError *error;
  NSData *jsonData = [[NSData alloc] initWithContentsOfFile:filePath];
  NSDictionary  *JSONObject = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData
                                                                         options:0 error:&error] : nil;
    if (!JSONObject) {
        //20190821 有的json文件中含有乱码，需要处理一下才能解析
        error = nil;
        NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSASCIIStringEncoding];
        NSData *utf8Data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        
        JSONObject = [NSJSONSerialization JSONObjectWithData:utf8Data options:NSJSONReadingMutableContainers error:&error];
        utf8Data = nil;
    }
    jsonData = nil;
  if (JSONObject && !error) {
    RDLOTComposition *laScene = [[self alloc] initWithJSON:JSONObject withAssetBundle:[NSBundle mainBundle]];
    laScene.rootDirectory = [filePath stringByDeletingLastPathComponent];
    [[RDLOTAnimationCache sharedCache] addAnimation:laScene forKey:animationName];
    laScene.cacheKey = animationName;
    return laScene;
  }
  
  NSLog(@"%s: Animation Not Found", __PRETTY_FUNCTION__);
  return nil;
}

+ (nonnull instancetype)animationFromJSON:(nonnull NSDictionary *)animationJSON {
  return [self animationFromJSON:animationJSON inBundle:[NSBundle mainBundle]];
}

+ (nonnull instancetype)animationFromJSON:(nullable NSDictionary *)animationJSON inBundle:(nullable NSBundle *)bundle {
  return [[self alloc] initWithJSON:animationJSON withAssetBundle:bundle];
}

#pragma mark - Initializer

- (instancetype _Nonnull)initWithJSON:(NSDictionary * _Nullable)jsonDictionary
                      withAssetBundle:(NSBundle * _Nullable)bundle {
  self = [super init];
  if (self) {
    if (jsonDictionary) {
      [self _mapFromJSON:jsonDictionary withAssetBundle:bundle];
    }
  }
  return self;
}

#pragma mark - Internal Methods

- (void)_mapFromJSON:(NSDictionary *)jsonDictionary
     withAssetBundle:(NSBundle *)bundle {
  NSNumber *width = jsonDictionary[@"w"];
  NSNumber *height = jsonDictionary[@"h"];
  if (width && height) {
    CGRect bounds = CGRectMake(0, 0, width.floatValue, height.floatValue);
    _compBounds = bounds;
  }
  
  _startFrame = [jsonDictionary[@"ip"] copy];
  _endFrame = [jsonDictionary[@"op"] copy];
    //帧率四舍五入
    _framerate = [NSNumber numberWithFloat:roundf([[jsonDictionary[@"fr"] copy] doubleValue])];//[jsonDictionary[@"fr"] copy];
    if ([_framerate intValue] == 0) {
        _framerate = [NSNumber numberWithInt:25];
    }
  
  if (_startFrame && _endFrame && _framerate) {
    NSInteger frameDuration = (_endFrame.integerValue - _startFrame.integerValue) - 1;
    NSTimeInterval timeDuration = frameDuration / _framerate.floatValue;
    _timeDuration = timeDuration;
  }
  
  NSArray *assetArray = jsonDictionary[@"assets"];
  if (assetArray.count) {
    _assetGroup = [[RDLOTAssetGroup alloc] initWithJSON:assetArray withAssetBundle:bundle withFramerate:_framerate];
  }
  
  NSArray *layersJSON = jsonDictionary[@"layers"];
  if (layersJSON) {
    _layerGroup = [[RDLOTLayerGroup alloc] initWithLayerJSON:layersJSON
                                            withAssetGroup:_assetGroup
                                               withFramerate:_framerate
                                               withFrameSize:CGSizeMake(width.floatValue, height.floatValue)];
  }
  
  [_assetGroup finalizeInitializationWithFramerate:_framerate];
}
  
- (void)setRootDirectory:(NSString *)rootDirectory {
    _rootDirectory = rootDirectory;
    self.assetGroup.rootDirectory = rootDirectory;
}

- (void)refreshEndFrame:(NSNumber *)endFrame {
    _endFrame = endFrame;
}
  
@end
