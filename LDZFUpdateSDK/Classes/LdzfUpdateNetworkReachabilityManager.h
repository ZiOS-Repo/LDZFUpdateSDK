//
//  LdzfUpdateNetworkReachabilityManager.h
//  IU_UpdateSDK
//
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>

#ifndef NS_DESIGNATED_INITIALIZER
#if __has_attribute(objc_designated_initializer)
#define NS_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#else
#define NS_DESIGNATED_INITIALIZER
#endif
#endif

typedef NS_ENUM(NSInteger, LdzfUpdateNetworkReachabilityStatus) {
    LdzfUpdateNetworkReachabilityStatusUnknown          = -1,
    LdzfUpdateNetworkReachabilityStatusNotReachable     = 0,
    LdzfUpdateNetworkReachabilityStatusReachableViaWWAN = 1,
    LdzfUpdateNetworkReachabilityStatusReachableViaWiFi = 2,
};

NS_ASSUME_NONNULL_BEGIN

@interface LdzfUpdateNetworkReachabilityManager : NSObject

/**
 The current network reachability status.
 */
@property (readonly, nonatomic, assign) LdzfUpdateNetworkReachabilityStatus networkReachabilityStatus;

/**
 Whether or not the network is currently reachable.
 */
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/**
 Whether or not the network is currently reachable via WWAN.
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/**
 Whether or not the network is currently reachable via WiFi.
 */
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

///---------------------
/// @name Initialization
///---------------------

/**
 Returns the shared network reachability manager.
 */
+ (instancetype)sharedManager;


///--------------------------------------------------
/// @name Starting & Stopping Reachability Monitoring
///--------------------------------------------------

/**
 Starts monitoring for changes in network reachability status.
 */
- (void)startMonitoring;

/**
 Stops monitoring for changes in network reachability status.
 */
- (void)stopMonitoring;

@end


FOUNDATION_EXPORT NSString * const LdzfUpdateNetworkReachabilityDidChangeNotification;


NS_ASSUME_NONNULL_END
#endif
