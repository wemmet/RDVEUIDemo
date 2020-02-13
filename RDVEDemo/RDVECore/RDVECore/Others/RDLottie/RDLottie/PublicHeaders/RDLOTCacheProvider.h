//
//  RDLOTCacheProvider.h
//  RDLottie
//
//  Created by punmy on 2017/7/8.
//
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR

#import <UIKit/UIKit.h>
@compatibility_alias RDLOTImage UIImage;

@protocol RDLOTImageCache;

#pragma mark - RDLOTCacheProvider

@interface RDLOTCacheProvider : NSObject

+ (id<RDLOTImageCache>)imageCache;
+ (void)setImageCache:(id<RDLOTImageCache>)cache;

@end

#pragma mark - RDLOTImageCache

/**
 This protocol represent the interface of a image cache which lottie can use.
 */
@protocol RDLOTImageCache <NSObject>

@required
- (RDLOTImage *)imageForKey:(NSString *)key;
- (void)setImage:(RDLOTImage *)image forKey:(NSString *)key;

@end

#endif
