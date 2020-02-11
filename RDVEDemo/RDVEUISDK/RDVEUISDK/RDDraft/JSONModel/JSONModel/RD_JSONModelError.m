//
//  JSONModelError.m
//  JSONModel
//

#import "RD_JSONModelError.h"

NSString* const RD_JSONModelErrorDomain = @"RD_JSONModelErrorDomain";
NSString* const kRD_JSONModelMissingKeys = @"kRD_JSONModelMissingKeys";
NSString* const kRD_JSONModelTypeMismatch = @"kRD_JSONModelTypeMismatch";
NSString* const kRD_JSONModelKeyPath = @"kRD_JSONModelKeyPath";

@implementation RD_JSONModelError

+(id)errorInvalidDataWithMessage:(NSString*)message
{
    message = [NSString stringWithFormat:@"Invalid JSON data: %@", message];
    return [RD_JSONModelError errorWithDomain:RD_JSONModelErrorDomain
                                      code:kRD_JSONModelErrorInvalidData
                                  userInfo:@{NSLocalizedDescriptionKey:message}];
}

+(id)errorInvalidDataWithMissingKeys:(NSSet *)keys
{
    return [RD_JSONModelError errorWithDomain:RD_JSONModelErrorDomain
                                      code:kRD_JSONModelErrorInvalidData
                                  userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON data. Required JSON keys are missing from the input. Check the error user information.",kRD_JSONModelMissingKeys:[keys allObjects]}];
}

+(id)errorInvalidDataWithTypeMismatch:(NSString*)mismatchDescription
{
    return [RD_JSONModelError errorWithDomain:RD_JSONModelErrorDomain
                                      code:kRD_JSONModelErrorInvalidData
                                  userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON data. The JSON type mismatches the expected type. Check the error user information.",kRD_JSONModelTypeMismatch:mismatchDescription}];
}

+(id)errorBadResponse
{
    return [RD_JSONModelError errorWithDomain:RD_JSONModelErrorDomain
                                      code:kRD_JSONModelErrorBadResponse
                                  userInfo:@{NSLocalizedDescriptionKey:@"Bad network response. Probably the JSON URL is unreachable."}];
}

+(id)errorBadJSON
{
    return [RD_JSONModelError errorWithDomain:RD_JSONModelErrorDomain
                                      code:kRD_JSONModelErrorBadJSON
                                  userInfo:@{NSLocalizedDescriptionKey:@"Malformed JSON. Check the JSONModel data input."}];
}

+(id)errorModelIsInvalid
{
    return [RD_JSONModelError errorWithDomain:RD_JSONModelErrorDomain
                                      code:kRD_JSONModelErrorModelIsInvalid
                                  userInfo:@{NSLocalizedDescriptionKey:@"Model does not validate. The custom validation for the input data failed."}];
}

+(id)errorInputIsNil
{
    return [RD_JSONModelError errorWithDomain:RD_JSONModelErrorDomain
                                      code:kRD_JSONModelErrorNilInput
                                  userInfo:@{NSLocalizedDescriptionKey:@"Initializing model with nil input object."}];
}

- (instancetype)errorByPrependingKeyPathComponent:(NSString*)component
{
    // Create a mutable  copy of the user info so that we can add to it and update it
    NSMutableDictionary* userInfo = [self.userInfo mutableCopy];

    // Create or update the key-path
    NSString* existingPath = userInfo[kRD_JSONModelKeyPath];
    NSString* separator = [existingPath hasPrefix:@"["] ? @"" : @".";
    NSString* updatedPath = (existingPath == nil) ? component : [component stringByAppendingFormat:@"%@%@", separator, existingPath];
    userInfo[kRD_JSONModelKeyPath] = updatedPath;

    // Create the new error
    return [RD_JSONModelError errorWithDomain:self.domain
                                      code:self.code
                                  userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

@end
