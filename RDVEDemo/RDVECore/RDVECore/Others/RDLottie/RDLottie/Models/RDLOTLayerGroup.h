//
//  RDLOTLayerGroup.h
//  Pods
//
//  Created by Brandon Withrow on 2/16/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class RDLOTLayer;
@class RDLOTAssetGroup;

@interface RDLOTLayerGroup : NSObject

- (instancetype)initWithLayerJSON:(NSArray *)layersJSON
                   withAssetGroup:(RDLOTAssetGroup * _Nullable)assetGroup
                    withFramerate:(NSNumber *)framerate
                    withFrameSize:(CGSize) frameSize;
@property (nonatomic, readonly) NSDictionary *referenceIDMap;//20180803 wuxiaoxia lottie
@property (nonatomic, readonly) NSArray <RDLOTLayer *> *layers;

- (RDLOTLayer *)layerModelForID:(NSNumber *)layerID;
- (RDLOTLayer *)layerForReferenceID:(NSString *)referenceID;

@end

NS_ASSUME_NONNULL_END
