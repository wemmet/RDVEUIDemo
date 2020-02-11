/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "RDSDWebImageDownloader.h"
#import "RDSDWebImageDownloaderOperation.h"
#import <ImageIO/ImageIO.h>

NSString *const RDSDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const RDSDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";

static NSString *const kRDProgressCallbackKey = @"progress";
static NSString *const kRDCompletedCallbackKey = @"completed";

@interface RDSDWebImageDownloader ()

@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (weak, nonatomic) NSOperation *lastAddedOperation;
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;
@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;
// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
@property (RDSDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t barrierQueue;

@end

@implementation RDSDWebImageDownloader

+ (void)initialize {
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator")) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:RDSDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:RDSDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:RDSDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:RDSDWebImageDownloadStopNotification object:nil];
    }
}

+ (RDSDWebImageDownloader *)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    if ((self = [super init])) {
        _executionOrder = RDSDWebImageDownloaderFIFOExecutionOrder;
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 2;
        _URLCallbacks = [NSMutableDictionary new];
        _HTTPHeaders = [NSMutableDictionary dictionaryWithObject:@"image/webp,image/*;q=0.8" forKey:@"Accept"];
        _barrierQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;
    }
    return self;
}

- (void)dealloc {
    [self.downloadQueue cancelAllOperations];
    RDSDDispatchQueueRelease(_barrierQueue);
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if (value) {
        self.HTTPHeaders[field] = value;
    }
    else {
        [self.HTTPHeaders removeObjectForKey:field];
    }
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    return self.HTTPHeaders[field];
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSUInteger)currentDownloadCount {
    return _downloadQueue.operationCount;
}

- (NSInteger)maxConcurrentDownloads {
    return _downloadQueue.maxConcurrentOperationCount;
}

- (id <RDSDWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(RDSDWebImageDownloaderOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageDownloaderCompletedBlock)completedBlock {
    __block RDSDWebImageDownloaderOperation *operation;
    __weak RDSDWebImageDownloader *wself = self;

    [self addProgressCallback:progressBlock andCompletedBlock:completedBlock forURL:url createCallback:^{
        NSTimeInterval timeoutInterval = wself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }

        // In order to prevent from potential duplicate caching (NSURLCache + RDSDImageCache) we disable the cache for image requests if told otherwise
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:(options & RDSDWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
        request.HTTPShouldHandleCookies = (options & RDSDWebImageDownloaderHandleCookies);
        request.HTTPShouldUsePipelining = YES;
        if (wself.headersFilter) {
            request.allHTTPHeaderFields = wself.headersFilter(url, [wself.HTTPHeaders copy]);
        }
        else {
            request.allHTTPHeaderFields = wself.HTTPHeaders;
        }
        operation = [[RDSDWebImageDownloaderOperation alloc] initWithRequest:request
                                                                   options:options
                                                                  progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                                      RDSDWebImageDownloader *sself = wself;
                                                                      if (!sself) return;
                                                                      NSArray *callbacksForURL = [sself callbacksForURL:url];
                                                                      for (NSDictionary *callbacks in callbacksForURL) {
                                                                          RDSDWebImageDownloaderProgressBlock callback = callbacks[kRDProgressCallbackKey];
                                                                          if (callback) callback(receivedSize, expectedSize);
                                                                      }
                                                                  }
                                                                 completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                     RDSDWebImageDownloader *sself = wself;
                                                                     if (!sself) return;
                                                                     NSArray *callbacksForURL = [sself callbacksForURL:url];
                                                                     if (finished) {
                                                                         [sself removeCallbacksForURL:url];
                                                                     }
                                                                     for (NSDictionary *callbacks in callbacksForURL) {
                                                                         RDSDWebImageDownloaderCompletedBlock callback = callbacks[kRDCompletedCallbackKey];
                                                                         if (callback) callback(image, data, error, finished);
                                                                     }
                                                                 }
                                                                 cancelled:^{
                                                                     RDSDWebImageDownloader *sself = wself;
                                                                     if (!sself) return;
                                                                     [sself removeCallbacksForURL:url];
                                                                 }];
        
        if (wself.username && wself.password) {
            operation.credential = [NSURLCredential credentialWithUser:wself.username password:wself.password persistence:NSURLCredentialPersistenceForSession];
        }
        
        if (options & RDSDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        } else if (options & RDSDWebImageDownloaderLowPriority) {
            operation.queuePriority = NSOperationQueuePriorityLow;
        }

        [wself.downloadQueue addOperation:operation];
        if (wself.executionOrder == RDSDWebImageDownloaderLIFOExecutionOrder) {
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            [wself.lastAddedOperation addDependency:operation];
            wself.lastAddedOperation = operation;
        }
    }];

    return operation;
}

- (void)addProgressCallback:(RDSDWebImageDownloaderProgressBlock)progressBlock andCompletedBlock:(RDSDWebImageDownloaderCompletedBlock)completedBlock forURL:(NSURL *)url createCallback:(RDSDWebImageNoParamsBlock)createCallback {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, nil, NO);
        }
        return;
    }

    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL first = NO;
        if (!self.URLCallbacks[url]) {
            self.URLCallbacks[url] = [NSMutableArray new];
            first = YES;
        }

        // Handle single download of simultaneous download request for the same URL
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        NSMutableDictionary *callbacks = [NSMutableDictionary new];
        if (progressBlock) callbacks[kRDProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kRDCompletedCallbackKey] = [completedBlock copy];
        [callbacksForURL addObject:callbacks];
        self.URLCallbacks[url] = callbacksForURL;

        if (first) {
            createCallback();
        }
    });
}

- (NSArray *)callbacksForURL:(NSURL *)url {
    __block NSArray *callbacksForURL;
    dispatch_sync(self.barrierQueue, ^{
        callbacksForURL = self.URLCallbacks[url];
    });
    return [callbacksForURL copy];
}

- (void)removeCallbacksForURL:(NSURL *)url {
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.URLCallbacks removeObjectForKey:url];
    });
}

- (void)setSuspended:(BOOL)suspended {
    [self.downloadQueue setSuspended:suspended];
}

@end
