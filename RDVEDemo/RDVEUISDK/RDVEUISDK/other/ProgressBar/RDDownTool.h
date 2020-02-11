//
//  RDDownTool.h
//  RDVEUISDK
//
//  Created by 周晓林 on 2017/3/22.
//  Copyright © 2017年 周晓林. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface RDDownTool : NSObject
@property (nonatomic,copy) void(^Progress) (float);
@property (nonatomic,copy) void(^Finish)(void);

- (instancetype)initWithURLPath:(NSString*)path savePath:(NSString*)savePath;
//- (void) downWithPath:(NSString*) path
//             savePath:(NSString *)savePath
//             progress:(void(^)(float)) progress
//               finish:(void(^)())finish;
- (void) start;
@end
