//
//  Common.h
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/28.
//

#ifndef Common_h
#define Common_h

#import "Masonry.h"
#import "QMUIKit.h"
#import "AFNetworking.h"
#import "YYCategories.h"

//登录的Token
#define LOGINTOKEN      @"userLoginToken"
//用户ID
#define USERID         @"userID"
//设备号
#define DEVICEID        @"userDeviceID"

/// 设置对象
#define UDSetObject(obj, key) \
    [[NSUserDefaults standardUserDefaults] setObject:(obj) forKey:(key)]

/// 获取对象
#define UDGetObject(key) \
    [[NSUserDefaults standardUserDefaults] objectForKey:(key)]

///移除对象
#define UDRemove(key) \
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:(key)];


#endif /* Common_h */
