//
//  IUAppUpdateManager.h
//  IU_UpdateSDK
//
//

#import <Foundation/Foundation.h>

@class IUAppUpdateConfig;
@class IUAppUpdateResponseModel;

typedef void (^AppUpdateCallback)(IUAppUpdateResponseModel * _Nonnull response);

NS_ASSUME_NONNULL_BEGIN

@interface IUAppUpdateManager : NSObject

+ (instancetype)sharedManager;

- (void)checkAppUpdate:(IUAppUpdateConfig *)config;

- (void)checkAppUpdate:(IUAppUpdateConfig *)config
               success:(AppUpdateCallback _Nullable)successCallback
              failture:(AppUpdateCallback _Nullable)failtureCallback;

@end

NS_ASSUME_NONNULL_END
