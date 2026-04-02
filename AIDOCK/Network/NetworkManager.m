//
//  NetworkManager.m
//  AIDOCK
//
//  Created by AIDOCK on 2026/02/11.
//

#import "NetworkManager.h"

@interface NetworkManager ()

@property(nonatomic, strong) AFHTTPSessionManager *manager;

@end

static NSString *const kBaseURL = @"http://35.220.249.211:8004";

@implementation NetworkManager

+ (instancetype)sharedManager {
  static NetworkManager *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NetworkManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSURL *baseURL = [NSURL URLWithString:kBaseURL];
    self.manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    // Request Serializer Configuration
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.manager.requestSerializer.timeoutInterval = 30.f;
    [self.manager.requestSerializer
                  setValue:@"application/x-www-form-urlencoded"
        forHTTPHeaderField:@"Content-Type"];

    // Response Serializer Configuration
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.manager.responseSerializer.acceptableContentTypes = [NSSet
        setWithObjects:@"application/json", @"text/json", @"text/javascript",
                       @"text/html", @"text/plain", nil];
  }
  return self;
}

- (void)POST:(NSString *)url
    parameters:(id)params
       headers:(NSDictionary<NSString *, NSString *> *)headers
       success:(NetworkSuccess)success
       failure:(NetworkFailure)failure {

  [self.manager POST:url
      parameters:params
      headers:headers
      progress:nil
      success:^(NSURLSessionDataTask *_Nonnull task,
                id _Nullable responseObject) {
        if (success) {
          success(responseObject);
        }
      }
      failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (failure) {
          failure(error);
        }
      }];
}

- (void)GET:(NSString *)url
    parameters:(id)params
       headers:(NSDictionary<NSString *, NSString *> *)headers
       success:(NetworkSuccess)success
       failure:(NetworkFailure)failure {

  [self.manager GET:url
      parameters:params
      headers:headers
      progress:nil
      success:^(NSURLSessionDataTask *_Nonnull task,
                id _Nullable responseObject) {
        if (success) {
          success(responseObject);
        }
      }
      failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        if (failure) {
          failure(error);
        }
      }];
}

@end
