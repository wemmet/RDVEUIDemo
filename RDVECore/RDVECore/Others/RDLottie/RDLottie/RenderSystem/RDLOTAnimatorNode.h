//
//  RDLOTAnimatorNode.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//

#import <Foundation/Foundation.h>
#import "RDLOTPlatformCompat.h"
#import "RDLOTBezierPath.h"
#import "RDLOTKeypath.h"
#import "RDLOTValueDelegate.h"
#import "RDLOTColorInterpolator.h"
#import "RDLOTNumberInterpolator.h"


extern NSInteger rdIndentation_level;


//json映射的相关参数  xiachunlin 2019.10.30
@interface AdbeEffect : NSObject
//匹配json中 “nm”
@property (nonatomic, assign)NSString* _Nullable keyMatchName;
//匹配json中 “k”
@property (nonatomic, assign)NSArray<RDLOTKeyframe *> * _Nullable keyframes;

@end


@interface RDLOTAnimatorNode : NSObject

/// Initializes the node with and optional input node and keyname.
- (instancetype _Nonnull)initWithInputNode:(RDLOTAnimatorNode *_Nullable)inputNode
                                    keyName:(NSString *_Nullable)keyname;

/// A dictionary of the value interpolators this node controls
@property (nonatomic, readonly, strong) NSDictionary * _Nullable valueInterpolators;

/// The keyname of the node. Used for dynamically setting keyframe data.
@property (nonatomic, readonly, strong) NSString * _Nullable keyname;

/// The current time in frames
@property (nonatomic, readonly, strong) NSNumber * _Nullable currentFrame;
/// The upstream animator node
@property (nonatomic, readonly, strong) RDLOTAnimatorNode * _Nullable inputNode;

/// This nodes path in local object space
@property (nonatomic, strong) RDLOTBezierPath * _Nonnull localPath;
/// The sum of all paths in the tree including this node
@property (nonatomic, strong) RDLOTBezierPath * _Nonnull outputPath;


//  保存json中 ”ef“ 对应的数据
@property (nonatomic, strong) NSMutableArray <AdbeEffect*>* _Nonnull effectArray;// xiachunlin 2019.11.06

/// Returns true if this node needs to update its contents for the given frame. To be overwritten by subclasses.
- (BOOL)needsUpdateForFrame:(NSNumber *_Nonnull)frame;

/// Sets the current frame and performs any updates. Returns true if any updates were performed, locally or upstream.
- (BOOL)updateWithFrame:(NSNumber *_Nonnull)frame;
- (BOOL)updateWithFrame:(NSNumber *_Nonnull)frame
      withModifierBlock:(void (^_Nullable)(RDLOTAnimatorNode * _Nonnull inputNode))modifier
       forceLocalUpdate:(BOOL)forceUpdate;

- (void)forceSetCurrentFrame:(NSNumber *_Nonnull)frame;

@property (nonatomic, assign) BOOL pathShouldCacheLengths;
/// Update the local content for the frame.
- (void)performLocalUpdate;

/// Rebuild all outputs for the node. This is called after upstream updates have been performed.
- (void)rebuildOutputs;

- (void)logString:(NSString *_Nonnull)string;

- (void)searchNodesForKeypath:(RDLOTKeypath * _Nonnull)keypath;

- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegate
              forKeypath:(RDLOTKeypath * _Nonnull)keypath;

@end
