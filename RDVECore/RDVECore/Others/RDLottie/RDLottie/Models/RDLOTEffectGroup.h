//
//  RDLOTShape.h
//  RDLottieAnimator
//
//  Created by Brandon Withrow on 12/14/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface RDLOTEffectGroup : NSObject

- (instancetype _Nonnull)initWithJSON:(NSDictionary *_Nonnull)jsonDictionary
                        withFrameSize:(CGSize) frameSize;

@property (nonatomic, readonly) NSString *keyname;
@property (nonatomic, readonly) NSArray *items;

+ (id _Nullable)effectItemWithJSON:(NSDictionary * _Nonnull)itemJSON;

@end
