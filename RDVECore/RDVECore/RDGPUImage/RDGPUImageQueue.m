//
//  RDGPUImageQueue.m
//  RDVECore
//
//  Created by 周晓林 on 2018/1/6.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDGPUImageQueue.h"
#import <UIKit/UIKit.h>
#include <mach/mach.h>
dispatch_queue_attr_t RDGPUImageDefaultQueueAttribute(void)
{
#if TARGET_OS_IPHONE
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    }
#endif
    return nil;
}

void rdRunOnMainQueueWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

void rdRunSynchronouslyOnVideoProcessingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [RDGPUImageContext sharedContextQueue];
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([RDGPUImageContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_sync(videoProcessingQueue, block);
        }
}

void rdRunAsynchronouslyOnVideoProcessingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [RDGPUImageContext sharedContextQueue];
    
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([RDGPUImageContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_async(videoProcessingQueue, block);
        }
}

void rdRunSynchronouslyOnContextQueue(RDGPUImageContext *context, void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [context contextQueue];
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([RDGPUImageContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_sync(videoProcessingQueue, block);
        }
}

void rdRunAsynchronouslyOnContextQueue(RDGPUImageContext *context, void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [context contextQueue];
    
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([RDGPUImageContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_async(videoProcessingQueue, block);
        }
}

void rdReportAvailableMemoryForRDGPUImage(NSString *tag)
{
    if (!tag)
        tag = @"Default";
    
    struct task_basic_info info;
    
    mach_msg_type_number_t size = sizeof(info);
    
    kern_return_t kerr = task_info(mach_task_self(),
                                   
                                   TASK_BASIC_INFO,
                                   
                                   (task_info_t)&info,
                                   
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"%@ - Memory used: %u", tag, (unsigned int)info.resident_size); //in bytes
    } else {
        NSLog(@"%@ - Error: %s", tag, mach_error_string(kerr));
    }
}

