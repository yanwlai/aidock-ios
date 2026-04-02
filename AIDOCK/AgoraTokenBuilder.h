//
//  AgoraTokenBuilder.h
//  AIDOCK
//
//  通过 Agora 云端 API 生成 RTC / RTM Token
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AgoraTokenCallback)(NSString * _Nullable token);

@interface AgoraTokenBuilder : NSObject

/// 生成 RTC Token（type=1）
+ (void)genRtcTokenWithAppId:(NSString *)appId
              appCertificate:(NSString *)appCertificate
                 channelName:(NSString *)channelName
                         uid:(NSUInteger)uid
                      expire:(uint32_t)expireSeconds
                  completion:(AgoraTokenCallback)completion;

/// 生成 RTM Token（type=2）
+ (void)genRtmTokenWithAppId:(NSString *)appId
              appCertificate:(NSString *)appCertificate
                      userId:(NSString *)userId
                      expire:(uint32_t)expireSeconds
                  completion:(AgoraTokenCallback)completion;

@end

NS_ASSUME_NONNULL_END
