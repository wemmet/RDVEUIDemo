//
//  RDLOTAnimationView
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//  Dream Big.

#import <Foundation/Foundation.h>
#import "RDLOTAnimationView_Compat.h"
#import "RDLOTComposition.h"
#import "RDLOTKeypath.h"
#import "RDLOTValueDelegate.h"
#import "RDLOTAnimatedSourceInfo.h"

@protocol RDLOTChangeImageDelegate <NSObject>

- (void)changeLayerImage:(CALayer *)layer layerName:(NSString *)layerName;

@end

typedef void (^RDLOTAnimationCompletionBlock)(BOOL animationFinished);

@interface RDLOTAnimationView : RDLOTView

/// Load animation by name from the default bundle, Images are also loaded from the bundle
+ (nonnull instancetype)animationNamed:(nonnull NSString *)animationName NS_SWIFT_NAME(init(name:));

/// Loads animation by name from specified bundle, Images are also loaded from the bundle
+ (nonnull instancetype)animationNamed:(nonnull NSString *)animationName inBundle:(nonnull NSBundle *)bundle NS_SWIFT_NAME(init(name:bundle:));

/// Creates an animation from the deserialized JSON Dictionary
+ (nonnull instancetype)animationFromJSON:(nonnull NSDictionary *)animationJSON NS_SWIFT_NAME(init(json:));

/// Loads an animation from a specific file path. WARNING Do not use a web URL for file path.
+ (nonnull instancetype)animationWithFilePath:(nonnull NSString *)filePath NS_SWIFT_NAME(init(filePath:));
+ (nonnull instancetype)animationWithFilePath:(nonnull NSString *)filePath rootDirectory:(nullable NSString *)rootDirectory version:(float)version  NS_SWIFT_NAME(init(filePath:rootDirectory:version:));

/// Creates an animation from the deserialized JSON Dictionary, images are loaded from the specified bundle
+ (nonnull instancetype)animationFromJSON:(nullable NSDictionary *)animationJSON inBundle:(nullable NSBundle *)bundle NS_SWIFT_NAME(init(json:bundle:));

+ (nonnull instancetype)animationFromJSON:(nullable NSDictionary *)animationJSON rootDirectory:(nullable NSString *)rootDirectory version:(float)version  NS_SWIFT_NAME(init(json:rootDirectory:version:));

/// Creates an animation from the RDLOTComposition, images are loaded from the specified bundle
- (nonnull instancetype)initWithModel:(nullable RDLOTComposition *)model inBundle:(nullable NSBundle *)bundle;

/// Loads animation asynchronously from the specified URL
- (nonnull instancetype)initWithContentsOfURL:(nonnull NSURL *)url;

/// Set animation name from Interface Builder
@property (nonatomic, strong) IBInspectable NSString * _Nullable animation;

/// Load animation by name from the default bundle. Use when loading RDLOTAnimationView via Interface Builder.
- (void)setAnimationNamed:(nonnull NSString *)animationName NS_SWIFT_NAME(setAnimation(named:));

/// Load animation from a JSON dictionary
- (void)setAnimationFromJSON:(nonnull NSDictionary *)animationJSON NS_SWIFT_NAME(setAnimation(json:));

/// Flag is YES when the animation is playing
@property (nonatomic, readonly) BOOL isAnimationPlaying;

/// Tells the animation to loop indefinitely. Defaults to NO.
@property (nonatomic, assign) BOOL loopAnimation;

/// The animation will play forward and then backwards if loopAnimation is also YES
@property (nonatomic, assign) BOOL autoReverseAnimation;

/// Sets a progress from 0 - 1 of the animation. If the animation is playing it will stop and the completion block will be called.
/// The current progress of the animation in absolute time.
/// e.g. a value of 0.75 always represents the same point in the animation, regardless of positive
/// or negative speed.
@property (nonatomic, assign) CGFloat animationProgress;

/// Sets the speed of the animation. Accepts a negative value for reversing animation.
@property (nonatomic, assign) CGFloat animationSpeed;

/// Read only of the duration in seconds of the animation at speed of 1
@property (nonatomic, readonly) CGFloat animationDuration;

/// Enables or disables caching of the backing animation model. Defaults to YES
@property (nonatomic, assign) BOOL cacheEnable;

/// Sets a completion block to call when the animation has completed
@property (nonatomic, copy, nullable) RDLOTAnimationCompletionBlock completionBlock;

/// Set the animation data
@property (nonatomic, strong, nullable) RDLOTComposition *sceneModel;

@property (nonatomic, assign) float configVer;//20191105 配置文件版本号

@property (nonatomic, assign) NSInteger imagesCount;//20180622 wuxiaoxia

/** 图片播放时长
 */
@property (nonatomic, readonly) float imagesDuration;//20180622 wuxiaoxia

/** 结尾开始播放时间
 */
@property (nonatomic, readonly) float endStartTime;//20180622 wuxiaoxia

/** json有片尾的，在播放片尾时是否还要播放其它图片
 */
@property (nonatomic, readonly) BOOL hasEndImage;//20180622 wuxiaoxia

/** 结尾播放时长
 */
@property (nonatomic, readonly) float endDuration;//20180622 wuxiaoxia

/** 最后一个可替换图片
*/
@property (nonatomic, strong) RDLOTAnimatedSourceInfo *lastReplacableInfo;


/** 开始播放时间
 */
@property (nonatomic, assign) float startTime;//20180622 emmet
@property (nonatomic, assign) BOOL  isRepeat;//20180622 emmet
@property (nonatomic, assign) BOOL  ispiantou;//20180622 emmet
@property (nonatomic, assign) BOOL  ispianwei;//20180622 emmet
@property (nonatomic, assign) float spanValue;//20180622 emmet

/** 所有图片(模板特定图片及选中图片)的信息
 *  包含图片名称，文件夹名称、长、宽等
 */
@property (nonatomic, readonly) NSMutableArray <RDLOTAnimatedSourceInfo*>*imageItems;//20180622 wuxiaoxia
@property (nonatomic, readonly) NSMutableArray <RDLOTAnimatedSourceInfo*> *sourceInfoArray;

/** 除模板特定图片之外的图片信息
 *  包含图片名称，文件夹名称、长、宽等
 */
@property (nonatomic, readonly) NSMutableArray <RDLOTAnimatedSourceInfo*>*variableImageItems;//20180622 wuxiaoxia
@property (nonatomic, readonly) NSMutableArray <RDLOTAnimatedSourceInfo*> *variableSourceInfoArray;
@property (nonatomic, readonly) NSMutableArray <RDLOTAnimatedSourceInfo*> *textSourceInfoArray;

/** 所有文字的信息
 *  包含文字名称，文件夹名称、长、宽等
 */
@property (nonatomic, readonly) NSMutableArray <RDLOTAnimatedSourceInfo*>*textItems;//20180622 wuxiaoxia

/** 不可替换的图片的信息
 *  包含图片名称，文件夹名称、长、宽等
 */
@property (nonatomic, readonly) NSMutableArray <RDLOTAnimatedSourceInfo*>*notReplaceableItems;//20180622 wuxiaoxia

@property (nonatomic, assign) BOOL isBlackVideo;  //背景视频是黑视频
@property (nonatomic, assign) int animationPlayCount;

/// Sets sholdRasterize to YES on the animation layer to improve compositioning performance when not animating.
/// Defaults to YES
@property (nonatomic, assign) BOOL shouldRasterizeWhenIdle;

@property (nonatomic, weak) id<RDLOTChangeImageDelegate>delegate;
- (void)refreshLayerContents:(NSString *)layerName;
- (void)refreshLayerContents;
- (void)refreshLayerInOutFrame:(NSMutableArray <RDLOTAnimatedSourceInfo*>*)inOutFrames;
- (void)refreshOldInFrame:(int)oldInFrame prevInFrame:(int)prevInFrame nextInFrame:(int)nextInFrame newInFrame:(int)newInFrame newOutFrame:(int)newOutFrame;

/* 
 * Plays the animation from its current position to a specific progress.
 * The animation will start from its current position.
 * If loopAnimation is YES the animation will loop from start position to toProgress indefinitely.
 * If loopAnimation is NO the animation will stop and the completion block will be called.
 */
- (void)playToProgress:(CGFloat)toProgress
        withCompletion:(nullable RDLOTAnimationCompletionBlock)completion;

/*
 * Plays the animation from specific progress to a specific progress
 * The animation will start from its current position..
 * If loopAnimation is YES the animation will loop from the startProgress to the endProgress indefinitely
 * If loopAnimation is NO the animation will stop and the completion block will be called.
 */
- (void)playFromProgress:(CGFloat)fromStartProgress
              toProgress:(CGFloat)toEndProgress
          withCompletion:(nullable RDLOTAnimationCompletionBlock)completion;

/*
 * Plays the animation from its current position to a specific frame.
 * The animation will start from its current position.
 * If loopAnimation is YES the animation will loop from beginning to toFrame indefinitely.
 * If loopAnimation is NO the animation will stop and the completion block will be called.
 */
- (void)playToFrame:(nonnull NSNumber *)toFrame
     withCompletion:(nullable RDLOTAnimationCompletionBlock)completion;

/*
 * Plays the animation from specific frame to a specific frame.
 * The animation will start from its current position.
 * If loopAnimation is YES the animation will loop start frame to end frame indefinitely.
 * If loopAnimation is NO the animation will stop and the completion block will be called.
 */
- (void)playFromFrame:(nonnull NSNumber *)fromStartFrame
              toFrame:(nonnull NSNumber *)toEndFrame
       withCompletion:(nullable RDLOTAnimationCompletionBlock)completion;


/**
 * Plays the animation from its current position to the end of the animation.
 * The animation will start from its current position.
 * If loopAnimation is YES the animation will loop from beginning to end indefinitely.
 * If loopAnimation is NO the animation will stop and the completion block will be called.
 **/
- (void)playWithCompletion:(nullable RDLOTAnimationCompletionBlock)completion;

/// Plays the animation
- (void)play;

/// Stops the animation at the current frame. The completion block will be called.
- (void)pause;

/// Stops the animation and rewinds to the beginning. The completion block will be called.
- (void)stop;

/// Sets progress of animation to a specific frame. If the animation is playing it will stop and the completion block will be called.
- (void)setProgressWithFrame:(nonnull NSNumber *)currentFrame;

/// Forces a layout and drawing update for the current frame.
- (void)forceDrawingUpdate;

/// Logs all child keypaths
- (void)logHierarchyKeypaths;

/*!
 @brief Sets a RDLOTValueDelegate for each animation property returned from the RDLOTKeypath search. RDLOTKeypath matches views inside of RDLOTAnimationView to their After Effects counterparts. The RDLOTValueDelegate is called every frame as the animation plays to override animation values. A delegate can be any object that conforms to the RDLOTValueDelegate protocol, or one of the prebuilt delegate classes found in RDLOTBlockCallback, RDLOTInterpolatorCallback, and RDLOTValueCallback.

 @discussion
 Example that sets an animated stroke to Red using a RDLOTColorValueCallback.
 @code
 RDLOTKeypath *keypath = [RDLOTKeypath keypathWithKeys:@"Layer 1", @"Ellipse 1", @"Stroke 1", @"Color", nil];
 RDLOTColorValueCallback *colorCallback = [RDLOTColorBlockCallback withColor:[UIColor redColor]];
 [animationView setValueCallback:colorCallback forKeypath:keypath];
 @endcode

 See the documentation for RDLOTValueDelegate to see how to create RDLOTValueCallbacks. A delegate can be any object that conforms to the RDLOTValueDelegate protocol, or one of the prebuilt delegate classes found in RDLOTBlockCallback, RDLOTInterpolatorCallback, and RDLOTValueCallback.

 See the documentation for RDLOTKeypath to learn more about how to create keypaths.

 NOTE: The delegate is weakly retained. Be sure that the creator of a delegate is retained.
 Read More at http://airbnb.io/lottie/ios/dynamic.html
 */
- (void)setValueDelegate:(id<RDLOTValueDelegate> _Nonnull)delegates
              forKeypath:(RDLOTKeypath * _Nonnull)keypath;

/*!
 @brief returns the string representation of every keypath matching the RDLOTKeypath search.
 */
- (nullable NSArray *)keysForKeyPath:(nonnull RDLOTKeypath *)keypath;

/*!
 @brief Converts a CGPoint from the Animation views top coordinate space into the coordinate space of the specified renderable animation node.
 */
- (CGPoint)convertPoint:(CGPoint)point
         toKeypathLayer:(nonnull RDLOTKeypath *)keypath;

/*!
 @brief Converts a CGRect from the Animation views top coordinate space into the coordinate space of the specified renderable animation node.
 */
- (CGRect)convertRect:(CGRect)rect
       toKeypathLayer:(nonnull RDLOTKeypath *)keypath;

/*!
 @brief Converts a CGPoint to the Animation views top coordinate space from the coordinate space of the specified renderable animation node.
 */
- (CGPoint)convertPoint:(CGPoint)point
       fromKeypathLayer:(nonnull RDLOTKeypath *)keypath;

/*!
 @brief Converts a CGRect to the Animation views top coordinate space from the coordinate space of the specified renderable animation node.
 */
- (CGRect)convertRect:(CGRect)rect
     fromKeypathLayer:(nonnull RDLOTKeypath *)keypath;

/*!
 @brief Adds a UIView, or NSView, to the renderable layer found at the Keypath
 */
- (void)addSubview:(nonnull RDLOTView *)view
    toKeypathLayer:(nonnull RDLOTKeypath *)keypath;

/*!
 @brief Adds a UIView, or NSView, to the parentrenderable layer found at the Keypath and then masks the view with layer found at the keypath.
 */
- (void)maskSubview:(nonnull RDLOTView *)view
     toKeypathLayer:(nonnull RDLOTKeypath *)keypath;

#if !TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
@property (nonatomic) RDLOTViewContentMode contentMode;
#endif

/*!
 @brief Sets the keyframe value for a specific After Effects property at a given time. NOTE: Deprecated. Use setValueDelegate:forKeypath:
 @discussion NOTE: Deprecated and non functioning. Use setValueCallback:forKeypath:
 @param value Value is the color, point, or number object that should be set at given time
 @param keypath NSString . separate keypath The Keypath is a dot separated key path that specifies the location of the key to be set from the After Effects file. This will begin with the Layer Name. EG "Layer 1.Shape 1.Fill 1.Color"
 @param frame The frame is the frame to be set. If the keyframe exists it will be overwritten, if it does not exist a new linearly interpolated keyframe will be added
 */
- (void)setValue:(nonnull id)value
      forKeypath:(nonnull NSString *)keypath
         atFrame:(nullable NSNumber *)frame __deprecated;

/*!
 @brief Adds a custom subview to the animation using a LayerName from After Effect as a reference point.
 @discussion NOTE: Deprecated. Use addSubview:toKeypathLayer: or maskSubview:toKeypathLayer:
 @param view The custom view instance to be added

 @param layer The string name of the After Effects layer to be referenced.

 @param applyTransform If YES the custom view will be animated to move with the specified After Effects layer. If NO the custom view will be masked by the After Effects layer
 */
- (void)addSubview:(nonnull RDLOTView *)view
      toLayerNamed:(nonnull NSString *)layer
    applyTransform:(BOOL)applyTransform __deprecated;

/*!
 @brief Converts the given CGRect from the receiving animation view's coordinate space to the supplied layer's coordinate space If layerName is null then the rect will be converted to the composition coordinate system. This is helpful when adding custom subviews to a RDLOTAnimationView
 @discussion NOTE: Deprecated. Use convertRect:fromKeypathLayer:
 */
- (CGRect)convertRect:(CGRect)rect
         toLayerNamed:(NSString *_Nullable)layerName __deprecated;

@end
