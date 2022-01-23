//
//  LdzfUpdateNetworkReachabilityManager.m
//  IU_UpdateSDK
//
//

#import "LdzfUpdateNetworkReachabilityManager.h"
#if !TARGET_OS_WATCH

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const LdzfUpdateNetworkReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";

typedef void (^LdzfUpdateNetworkReachabilityStatusBlock)(LdzfUpdateNetworkReachabilityStatus status);

static LdzfUpdateNetworkReachabilityStatus LdzfUpdateNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));

    LdzfUpdateNetworkReachabilityStatus status = LdzfUpdateNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = LdzfUpdateNetworkReachabilityStatusNotReachable;
    }
#if    TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = LdzfUpdateNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = LdzfUpdateNetworkReachabilityStatusReachableViaWiFi;
    }

    return status;
}

/**
 * Queue a status change notification for the main thread.
 *
 * This is done to ensure that the notifications are received in the same order
 * as they are sent. If notifications are sent directly, it is possible that
 * a queued notification (for an earlier status condition) is processed after
 * the later update, resulting in the listener being left in the wrong state.
 */
static void IUPostReachabilityStatusChange(SCNetworkReachabilityFlags flags, LdzfUpdateNetworkReachabilityStatusBlock block) {
    LdzfUpdateNetworkReachabilityStatus status = LdzfUpdateNetworkReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block(status);
        }
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter postNotificationName:LdzfUpdateNetworkReachabilityDidChangeNotification object:nil userInfo:nil];
    });
}

static void LdzfUpdateNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    IUPostReachabilityStatusChange(flags, (__bridge LdzfUpdateNetworkReachabilityStatusBlock)info);
}

static const void * LdzfUpdateNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void LdzfUpdateNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface LdzfUpdateNetworkReachabilityManager ()
@property (readwrite, nonatomic, strong) id networkReachability;
@property (readwrite, nonatomic, assign) LdzfUpdateNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) LdzfUpdateNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation LdzfUpdateNetworkReachabilityManager

+ (instancetype)sharedManager {
    static LdzfUpdateNetworkReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;

        _sharedManager = [self managerForAddress:&address];
    });

    return _sharedManager;
}

#ifndef __clang_analyzer__
+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    LdzfUpdateNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];

    return manager;
}
#endif

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.networkReachability = CFBridgingRelease(reachability);
    self.networkReachabilityStatus = LdzfUpdateNetworkReachabilityStatusUnknown;

    return self;
}

- (instancetype)init NS_UNAVAILABLE
{
    return nil;
}

- (void)dealloc {
    [self stopMonitoring];
}

#pragma mark -

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.networkReachabilityStatus == LdzfUpdateNetworkReachabilityStatusReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == LdzfUpdateNetworkReachabilityStatusReachableViaWiFi;
}

#pragma mark -

- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self)weakSelf = self;
    LdzfUpdateNetworkReachabilityStatusBlock callback = ^(LdzfUpdateNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }

    };

    id networkReachability = self.networkReachability;
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, LdzfUpdateNetworkReachabilityRetainCallback, LdzfUpdateNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback((__bridge SCNetworkReachabilityRef)networkReachability, LdzfUpdateNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop((__bridge SCNetworkReachabilityRef)networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags((__bridge SCNetworkReachabilityRef)networkReachability, &flags)) {
            IUPostReachabilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }

    SCNetworkReachabilityUnscheduleFromRunLoop((__bridge SCNetworkReachabilityRef)self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}


#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] || [key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }

    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
#endif
