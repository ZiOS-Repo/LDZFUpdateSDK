//
//  IUAppUpdateConfig.h
//  IU_UpdateSDK
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IUAppUpdateConfig : NSObject
@property (nonatomic, copy, readonly) NSString *e_version; // RSA秘钥版本号(如果存在e_model则必填)
@property (nonatomic, copy, readonly) NSString *e_model; // 对敏感信息使用RSA加密后的字符串
@property (nonatomic, copy, readonly) NSString *appId; // 渠道号
@property (nonatomic, copy, readonly) NSString *appVersion; // 手机端当前app产品版本号
@property (nonatomic, copy, readonly) NSString *os; // 手机操作系统类型[android/ios, 或者 1/2]
@property (nonatomic, copy, readonly) NSString *osVersion; // 手机操作系统版本号
@property (nonatomic, copy, readonly) NSString *host; // host地址

+ (instancetype)configWithDict:(NSDictionary *)dictionary;

- (instancetype)initWithAppId:(NSString *)appId
                   appVersion:(NSString *)appVersion
                encryptRsaKey:(NSString *)key;

- (instancetype)initWithAppId:(NSString *)appId
                   appVersion:(NSString *)appVersion
                encryptRsaKey:(NSString *)key
                         host:(NSString *)host;

- (instancetype)initWithAppId:(NSString *)appId
                   appVersion:(NSString *)appVersion
                encryptRsaKey:(NSString *)key
                     deviceId:(NSString *)deviceId
                         host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateEVersionKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateEModelKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateAppIdKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateAppVersionKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateOsKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateOsVersionKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateHostKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateDeviceIdKey;

FOUNDATION_EXPORT NSString * _Nullable const IUAppUpdateEncryptRsaKey;
