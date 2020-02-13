//
//  RDLOTRenderGroup.h
//  RDLottie
//
//  Created by brandon_withrow on 6/27/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "RDLOTRenderNode.h"

@interface RDLOTRenderGroup : RDLOTRenderNode

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode * _Nullable)inputNode
                                   contents:(NSArray * _Nonnull)contents
                                    keyname:(NSString * _Nullable)keyname;

- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode * _Nullable)inputNode
                                  contents:(NSArray * _Nonnull)contents
                                   keyname:(NSString * _Nullable)keyname
                                     Layer:(CALayer* _Nonnull)layer;

- (void)refreshContents:(CALayer*)layer;

@property (nonatomic, strong, readonly) CALayer * _Nonnull containerLayer;

- (void)clear;

@end


