//
//  RDGPUImageQueue.h
//  RDVECore
//
//  Created by 周晓林 on 2018/1/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RDGPUImageContext.h"

dispatch_queue_attr_t RDGPUImageDefaultQueueAttribute(void);
void rdRunOnMainQueueWithoutDeadlocking(void (^block)(void));
void rdRunSynchronouslyOnVideoProcessingQueue(void (^block)(void));
void rdRunAsynchronouslyOnVideoProcessingQueue(void (^block)(void));
void rdRunSynchronouslyOnContextQueue(RDGPUImageContext *context, void (^block)(void));
void rdRunAsynchronouslyOnContextQueue(RDGPUImageContext *context, void (^block)(void));
void rdReportAvailableMemoryForRDGPUImage(NSString *tag);
