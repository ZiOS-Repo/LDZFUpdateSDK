//
//  LdzfAppUpdateResponseModel.h
//  IU_UpdateSDK
//
//

#import <Foundation/Foundation.h>

@interface LdzfAppUpdateResponseModel : NSObject
///错误信息
@property(strong,nonatomic)NSString *errMsg;

/// 返回代码
@property(assign,nonatomic)NSInteger code;
/// 返回消息
@property(strong,nonatomic)NSString *msg;
//// 0: 静默 1: 建议, 每次启动app都会提示更新 2: 强制 10:建议，可以忽略本次更新,忽略后不再提示更新
@property(strong,nonatomic)NSNumber *priority;
// 文件下载地址
@property(strong,nonatomic)NSString *downloadUrl;
// 文件MD5
@property(strong,nonatomic)NSString *md5;
// 文件大小
@property(strong,nonatomic)NSString *size;
// 版本号
@property(strong,nonatomic)NSString *version;
// 更新提示语
@property(strong,nonatomic)NSString *descMsg;
// 更新logo图片
@property(strong,nonatomic)NSString *logo;

@property(strong,nonatomic)NSString *iospListUrl;

@end
