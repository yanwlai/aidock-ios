//
//  AgoraTokenBuilder.m
//  AIDOCK
//
//  通过 Agora 云端 API 生成 Token
//  参考 Android TokenUtils.java 实现
//

#import "AgoraTokenBuilder.h"

static NSString *const kTokenURL = @"https://service.agora.io/toolbox-global/v1/token/generate";

@implementation AgoraTokenBuilder

+ (void)genRtcTokenWithAppId:(NSString *)appId
              appCertificate:(NSString *)appCertificate
                 channelName:(NSString *)channelName
                         uid:(NSUInteger)uid
                      expire:(uint32_t)expireSeconds
                  completion:(AgoraTokenCallback)completion {
    NSDictionary *body = @{
        @"appId": appId,
        @"appCertificate": appCertificate,
        @"channelName": channelName ?: @"",
        @"expire": @(expireSeconds),
        @"src": @"iOS",
        @"ts": [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)],
        @"type": @1,
        @"uid": [NSString stringWithFormat:@"%lu", (unsigned long)uid],
    };
    [self requestTokenWithBody:body tag:@"RTC" completion:completion];
}

+ (void)genRtmTokenWithAppId:(NSString *)appId
              appCertificate:(NSString *)appCertificate
                      userId:(NSString *)userId
                      expire:(uint32_t)expireSeconds
                  completion:(AgoraTokenCallback)completion {
    NSDictionary *body = @{
        @"appId": appId,
        @"appCertificate": appCertificate,
        @"channelName": @"",
        @"expire": @(expireSeconds),
        @"src": @"iOS",
        @"ts": [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)],
        @"type": @2,
        @"uid": userId ?: @"",
    };
    [self requestTokenWithBody:body tag:@"RTM" completion:completion];
}

+ (void)requestTokenWithBody:(NSDictionary *)body
                         tag:(NSString *)tag
                  completion:(AgoraTokenCallback)completion {
    NSError *jsonErr;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonErr];
    if (jsonErr) {
        NSLog(@"[TokenBuilder] %@ JSON error: %@", tag, jsonErr);
        if (completion) completion(nil);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kTokenURL]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = jsonData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"[TokenBuilder] %@ request failed: %@", tag, error.localizedDescription);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(nil);
                });
                return;
            }
            NSError *parseErr;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
            if (parseErr) {
                NSLog(@"[TokenBuilder] %@ parse error: %@", tag, parseErr);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(nil);
                });
                return;
            }
            NSString *token = json[@"data"][@"token"];
            NSLog(@"[TokenBuilder] %@ token: %@", tag, token);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(token);
            });
        }];
    [task resume];
}

@end
