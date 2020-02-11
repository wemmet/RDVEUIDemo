//
//  JSONAPI.h
//  JSONModel
//

#import <Foundation/Foundation.h>
#import "RD_JSONHTTPClient.h"

DEPRECATED_ATTRIBUTE
@interface RD_JSONAPI : NSObject

+ (void)setAPIBaseURLWithString:(NSString *)base DEPRECATED_ATTRIBUTE;
+ (void)setContentType:(NSString *)ctype DEPRECATED_ATTRIBUTE;
+ (void)getWithPath:(NSString *)path andParams:(NSDictionary *)params completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)postWithPath:(NSString *)path andParams:(NSDictionary *)params completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)rpcWithMethodName:(NSString *)method andArguments:(NSArray *)args completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)rpc2WithMethodName:(NSString *)method andParams:(id)params completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;

@end
