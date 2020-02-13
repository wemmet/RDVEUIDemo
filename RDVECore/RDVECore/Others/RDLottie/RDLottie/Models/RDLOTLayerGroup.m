//
//  RDLOTLayerGroup.m
//  Pods
//
//  Created by Brandon Withrow on 2/16/17.
//
//

#import "RDLOTLayerGroup.h"
#import "RDLOTLayer.h"
#import "RDLOTAssetGroup.h"

@implementation RDLOTLayerGroup {
  NSDictionary *_modelMap;
//  NSDictionary *_referenceIDMap;
}

- (instancetype)initWithLayerJSON:(NSArray *)layersJSON
                   withAssetGroup:(RDLOTAssetGroup * _Nullable)assetGroup
                    withFramerate:(NSNumber *)framerate
                    withFrameSize:(CGSize) frameSize {
  self = [super init];
  if (self) {
    [self _mapFromJSON:layersJSON withAssetGroup:assetGroup withFramerate:framerate withFrameSize:frameSize];
  }
  return self;
}

- (void)_mapFromJSON:(NSArray *)layersJSON
      withAssetGroup:(RDLOTAssetGroup * _Nullable)assetGroup
       withFramerate:(NSNumber *)framerate
       withFrameSize:(CGSize) frameSize{
  
  NSMutableArray *layers = [NSMutableArray array];
  NSMutableDictionary *modelMap = [NSMutableDictionary dictionary];
  NSMutableDictionary *referenceMap = [NSMutableDictionary dictionary];
  

  for (NSDictionary *layerJSON in layersJSON) {
    NSString *name_chiled = layerJSON[@"nm"];
    RDLOTLayer *layer = [[RDLOTLayer alloc] initWithJSON:layerJSON
                                      withAssetGroup:assetGroup
                                       withFramerate:framerate
                                        withFrameSize:frameSize];
    [layers addObject:layer];
    modelMap[layer.layerID] = layer;
    if (layer.referenceID) {
      referenceMap[layer.referenceID] = layer;
    }
  }
  
  _referenceIDMap = referenceMap;
  _modelMap = modelMap;
  _layers = layers;
}

- (RDLOTLayer *)layerModelForID:(NSNumber *)layerID {
  return _modelMap[layerID];
}

- (RDLOTLayer *)layerForReferenceID:(NSString *)referenceID {
  return _referenceIDMap[referenceID];
}

@end
