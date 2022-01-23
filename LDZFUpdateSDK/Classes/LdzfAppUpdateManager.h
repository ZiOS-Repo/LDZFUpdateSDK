//
//  LdzfAppUpdateManager.h
//  IU_UpdateSDK
//
//

#import <Foundation/Foundation.h>

@class LdzfAppUpdateConfig;
@class LdzfAppUpdateResponseModel;

typedef void (^AppUpdateCallback)(LdzfAppUpdateResponseModel * _Nonnull response);

NS_ASSUME_NONNULL_BEGIN

@interface LdzfAppUpdateManager : NSObject

+ (instancetype)sharedManager;

- (void)checkAppUpdate:(LdzfAppUpdateConfig *)config;

- (void)checkAppUpdate:(LdzfAppUpdateConfig *)config
               success:(AppUpdateCallback _Nullable)successCallback
              failture:(AppUpdateCallback _Nullable)failtureCallback;

@end

NS_ASSUME_NONNULL_END
