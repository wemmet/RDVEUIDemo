//
//  JSONModelHTTPClient.h
//  JSONModel
//

#import "RD_JSONModel.h"

extern NSString *const kRDHTTPMethodGET DEPRECATED_ATTRIBUTE;
extern NSString *const kRDHTTPMethodPOST DEPRECATED_ATTRIBUTE;
extern NSString *const kRDContentTypeAutomatic DEPRECATED_ATTRIBUTE;
extern NSString *const kRDContentTypeJSON DEPRECATED_ATTRIBUTE;
extern NSString *const kRDContentTypeWWWEncoded DEPRECATED_ATTRIBUTE;

typedef void (^RD_JSONObjectBlock)(id json, RD_JSONModelError *err) DEPRECATED_ATTRIBUTE;

DEPRECATED_ATTRIBUTE
@interface RD_JSONHTTPClient : NSObject

+ (NSMutableDictionary *)requestHeaders DEPRECATED_ATTRIBUTE;
+ (void)setDefaultTextEncoding:(NSStringEncoding)encoding DEPRECATED_ATTRIBUTE;
+ (void)setCachingPolicy:(NSURLRequestCachePolicy)policy DEPRECATED_ATTRIBUTE;
+ (void)setTimeoutInSeconds:(int)seconds DEPRECATED_ATTRIBUTE;
+ (void)setRequestContentType:(NSString *)contentTypeString DEPRECATED_ATTRIBUTE;
+ (void)getJSONFromURLWithString:(NSString *)urlString completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)getJSONFromURLWithString:(NSString *)urlString params:(NSDictionary *)params completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)JSONFromURLWithString:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params orBodyString:(NSString *)bodyString completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)JSONFromURLWithString:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params orBodyString:(NSString *)bodyString headers:(NSDictionary *)headers completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)JSONFromURLWithString:(NSString *)urlString method:(NSString *)method params:(NSDictionary *)params orBodyData:(NSData *)bodyData headers:(NSDictionary *)headers completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)postJSONFromURLWithString:(NSString *)urlString params:(NSDictionary *)params completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)postJSONFromURLWithString:(NSString *)urlString bodyString:(NSString *)bodyString completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)postJSONFromURLWithString:(NSString *)urlString bodyData:(NSData *)bodyData completion:(RD_JSONObjectBlock)completeBlock DEPRECATED_ATTRIBUTE;

@end
