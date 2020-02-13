//
//  PPMovieManager.m
//  RD
//
//  Created by Tuo on 2/3/15.
//  Copyright (c) 2015 Brad Larson. All rights reserved.
//
//#import "RDPlayer.h"
#import "PPMovieManager.h"

@implementation PPMovieManager

+ (PPMovieManager *)shared {
    static PPMovieManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[PPMovieManager alloc] init];
        // Do any other initialisation stuff here
    });
    return shared;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupQueues];
    }

    return self;
}

- (void)setupQueues {
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];

    // Create the main serialization queue.
    self.mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], DISPATCH_QUEUE_SERIAL);
    
    NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw audio serialization queue", self];
    // Create the serialization queue to use for reading and writing the audio data.
    self.rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], DISPATCH_QUEUE_SERIAL);
    
    NSString *rwVideoSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw video serialization queue", self];
    // Create the serialization queue to use for reading and writing the video data.
    self.rwVideoSerializationQueue = dispatch_queue_create([rwVideoSerializationQueueDescription UTF8String], DISPATCH_QUEUE_SERIAL);

    self.readingAllReadyDispatchGroup = dispatch_group_create();
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
