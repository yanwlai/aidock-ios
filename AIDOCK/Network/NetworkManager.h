//
//  NetworkManager.h
//  AIDOCK
//
//  Created by AIDOCK on 2026/02/11.
//

#import <AFNetworking/AFNetworking.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NetworkSuccess)(id responseObject);
typedef void (^NetworkFailure)(NSError *error);

@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

/**
 *  Post Request
 *
 *  @param url      The URL for the request
 *  @param params   The parameters for the request
 *  @param headers  The headers for the request
 *  @param success  Success completion block
 *  @param failure  Failure completion block
 */
- (void)POST:(NSString *)url
    parameters:(nullable id)params
       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
       success:(nullable NetworkSuccess)success
       failure:(nullable NetworkFailure)failure;

/**
 *  Get Request
 *
 *  @param url      The URL for the request
 *  @param params   The parameters for the request
 *  @param headers  The headers for the request
 *  @param success  Success completion block
 *  @param failure  Failure completion block
 */
- (void)GET:(NSString *)url
    parameters:(nullable id)params
       headers:(nullable NSDictionary<NSString *, NSString *> *)headers
       success:(nullable NetworkSuccess)success
       failure:(nullable NetworkFailure)failure;

@end

NS_ASSUME_NONNULL_END
