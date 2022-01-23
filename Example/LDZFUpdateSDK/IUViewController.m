//
//  IUViewController.m
//  IU_UpdateSDK
//
//  Created by zhuyuhui434@gmail.com on 06/11/2021.
//  Copyright (c) 2021 zhuyuhui434@gmail.com. All rights reserved.
//

#import "IUViewController.h"
#import <LDZFUpdateSDK/LDZFUpdateSDK.h>

#define RSA_KEY @""

#define kAppVersion        @"1.0.0"
#define kAPPID @"100121"
#define kHOST  @"http://192.168.103.110"



@interface IUViewController ()

@end

@implementation IUViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[self class] checkAppUpdateWithCompletion:^(BOOL isUpdate, NSString * _Nullable tipsMsg, NSString * _Nullable errMsg) {
        
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//版本更新
+ (void)checkAppUpdateWithCompletion:(void(^) (BOOL isUpdate,NSString *_Nullable tipsMsg,NSString *_Nullable errMsg))completion{
    
    NSString *appId = kAPPID;
    NSString *appVersion = kAppVersion;
    NSString *encryptRsaKey = [self base64EncodeString:RSA_KEY];
    NSString *puuid = [UIDevice currentDevice].identifierForVendor.UUIDString;
    LdzfAppUpdateConfig *config = [[LdzfAppUpdateConfig alloc] initWithAppId:appId appVersion:appVersion encryptRsaKey:encryptRsaKey deviceId:puuid host:kHOST];
        
    [[LdzfAppUpdateManager sharedManager] checkAppUpdate:config success:^(LdzfAppUpdateResponseModel * _Nonnull response) {
        BOOL isUpdate =NO;
        if (response.code == 20) {
            //客户端版本已最新，无需更新
            
        }else if (response.code == 30){
            isUpdate = YES;
            //有更新
            
        }
        if (completion) {
            completion(isUpdate,response.msg,nil);
        }
    } failture:^(LdzfAppUpdateResponseModel * _Nonnull response) {
        if (completion) {
            completion(NO,nil,response.errMsg);
        }
    }];
}



+ (NSString *)base64EncodeString:(NSString *)string
{
    NSString * str = [self getBinaryByHex:string];
    NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

+ (NSString *)getBinaryByHex:(NSString *)hex
{
    NSMutableDictionary *hexDic = [[NSMutableDictionary alloc] initWithCapacity:16];
    [hexDic setObject:@"0000" forKey:@"0"];
    [hexDic setObject:@"0001" forKey:@"1"];
    [hexDic setObject:@"0010" forKey:@"2"];
    [hexDic setObject:@"0011" forKey:@"3"];
    [hexDic setObject:@"0100" forKey:@"4"];
    [hexDic setObject:@"0101" forKey:@"5"];
    [hexDic setObject:@"0110" forKey:@"6"];
    [hexDic setObject:@"0111" forKey:@"7"];
    [hexDic setObject:@"1000" forKey:@"8"];
    [hexDic setObject:@"1001" forKey:@"9"];
    [hexDic setObject:@"1010" forKey:@"A"];
    [hexDic setObject:@"1011" forKey:@"B"];
    [hexDic setObject:@"1100" forKey:@"C"];
    [hexDic setObject:@"1101" forKey:@"D"];
    [hexDic setObject:@"1110" forKey:@"E"];
    [hexDic setObject:@"1111" forKey:@"F"];
    
    NSString *binary = @"";
    for (int i=0; i<[hex length]; i++)
    {
        NSString *key = [hex substringWithRange:NSMakeRange(i, 1)];
        NSString *value = [hexDic objectForKey:key.uppercaseString];
        if (value)
        {
            binary = [binary stringByAppendingString:value];
        }
    }
    return binary;
}

@end
