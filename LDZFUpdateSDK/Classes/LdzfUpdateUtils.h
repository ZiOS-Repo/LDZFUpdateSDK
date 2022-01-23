//
//  LdzfUpdateUtils.h
//  IU_UpdateSDK
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LdzfUpdateUtils : NSObject

+ (NSString *)encryptRSAWithString:(NSString *)string publicKey:(NSString *)publicKey;

+ (NSString *)stringWithObject:(id)obj;

+ (NSDictionary *)objectFromJsonString:(NSString *)jsonString;

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

NS_ASSUME_NONNULL_END
