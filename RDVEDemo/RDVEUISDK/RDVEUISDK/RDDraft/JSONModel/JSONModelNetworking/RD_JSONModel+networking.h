//
//  JSONModel+networking.h
//  JSONModel
//

#import "RD_JSONModel.h"
#import "RD_JSONHTTPClient.h"

typedef void (^RD_JSONModelBlock)(id model, RD_JSONModelError *err) DEPRECATED_ATTRIBUTE;

@interface RD_JSONModel (Networking)

@property (assign, nonatomic) BOOL isLoading DEPRECATED_ATTRIBUTE;
- (instancetype)initFromURLWithString:(NSString *)urlString completion:(RD_JSONModelBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)getModelFromURLWithString:(NSString *)urlString completion:(RD_JSONModelBlock)completeBlock DEPRECATED_ATTRIBUTE;
+ (void)postModel:(RD_JSONModel *)post toURLWithString:(NSString *)urlString completion:(RD_JSONModelBlock)completeBlock DEPRECATED_ATTRIBUTE;

@end
