//
//  LoginViewController.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/19.
//

#import "LoginViewController.h"
#import "BindViewController.h"
#import "Common.h"
#import "ConnectViewController.h"
#import "CustomKeybordView.h"
#import "NetworkManager.h"
#import "PasswordInputView.h"
#import "AIDOCK-Swift.h"
@interface LoginViewController () <CustomKeybordViewDelegate>
@property(nonatomic, strong) UIImageView *login_Left;
@property(nonatomic, strong) UIImageView *login_right;
//@property(nonatomic, strong) UIImageView *login_Title;
//@property(nonatomic, strong) UILabel *titleLab;
@property(nonatomic, strong) UIImageView *lockImage;
@property(nonatomic, strong) UIView *effectView;
@property(nonatomic, strong) UILabel *inputAlertLab;
@property(nonatomic, strong) PasswordInputView *passwordInputView;
@property(nonatomic, strong) UILabel *infoAlertLab;
@property(nonatomic, strong) CustomKeybordView *keybordView;
@property(nonatomic, strong) NSMutableArray *passwordArray;
@end

@implementation LoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.passwordArray = [[NSMutableArray alloc] init];
  [self.view addSubview:self.login_Left];
  [self.view addSubview:self.login_right];
  //    [self.view addSubview:self.login_Title];
  //    [self.view addSubview:self.titleLab];
  [self.view addSubview:self.effectView];

  [self.effectView addSubview:self.lockImage];
  [self.effectView addSubview:self.inputAlertLab];
  [self.effectView addSubview:self.passwordInputView];
  [self.effectView addSubview:self.infoAlertLab];
  [self.effectView addSubview:self.keybordView];

  //    [self.login_Left mas_makeConstraints:^(MASConstraintMaker *make) {
  //        make.right.equalTo(self.view.mas_left);
  //        make.top.equalTo(self.view.mas_top).offset(160);
  //        make.height.mas_equalTo(267);
  //        make.width.mas_equalTo(102);
  //    }];
  //
  //    [self.login_right mas_makeConstraints:^(MASConstraintMaker *make) {
  //        make.left.equalTo(self.view.mas_right);
  //        make.top.equalTo(self.view.mas_top).offset(160);
  //        make.height.mas_equalTo(267);
  //        make.width.mas_equalTo(102);
  //    }];

  //    [self.login_Title mas_makeConstraints:^(MASConstraintMaker *make) {
  //        make.centerX.equalTo(self.view);
  //        make.top.equalTo(self.view.mas_top).offset(81);
  //        make.height.mas_equalTo(21);
  //        make.width.mas_equalTo(106);
  //    }];
  //
  //    [self.titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
  //        make.centerX.equalTo(self.view);
  //        make.top.equalTo(self.login_Title.mas_bottom).offset(14);
  //        make.height.mas_equalTo(22);
  ////        make.width.mas_equalTo(139);
  //    }];

  [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.left.bottom.right.equalTo(self.view);
    //        make.top.equalTo(self.view).offset(205);
    make.edges.equalTo(self.view);
  }];

  [self.lockImage mas_makeConstraints:^(MASConstraintMaker *make) {
    make.height.width.mas_equalTo(16);
    make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(10);
    make.centerX.equalTo(self.view);
  }];

  [self.inputAlertLab mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.effectView);
    make.top.equalTo(self.lockImage.mas_bottom).offset(52);
    make.height.mas_equalTo(22);
    make.width.mas_equalTo(96);
  }];

  [self.passwordInputView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.effectView);
    make.top.equalTo(self.inputAlertLab.mas_bottom).offset(33);
    make.height.mas_equalTo(60);
  }];

  [self.infoAlertLab mas_makeConstraints:^(MASConstraintMaker *make) {
    make.height.mas_equalTo(20);
    make.centerX.equalTo(self.view);
    make.top.equalTo(self.passwordInputView.mas_bottom).offset(52);
  }];

  [self.keybordView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
    make.left.right.equalTo(self.effectView);
    make.height.mas_equalTo(317);
  }];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.login_Left.frame =
      CGRectMake(-self.login_Left.width, 160, self.login_Left.width,
                 self.login_Left.height);
  self.login_right.frame =
      CGRectMake(self.view.width + self.login_right.width, 160,
                 self.login_right.width, self.login_right.height);
  [self.login_Left mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.view.mas_left);
    make.top.equalTo(self.view.mas_top).offset(160);
    make.height.mas_equalTo(267);
    make.width.mas_equalTo(102);
  }];

  [self.login_right mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.view.mas_right);
    make.top.equalTo(self.view.mas_top).offset(160);
    make.height.mas_equalTo(267);
    make.width.mas_equalTo(102);
  }];
  self.effectView.alpha = 0.0;
  //    self.login_Title.alpha = 0.0;
  //    self.titleLab.alpha = 0.0;

  // 从操控页面返回时清空密码
  [self clearPassword];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.7
                         animations:^{
                           self.effectView.alpha = 1.0;
                         }];

        //        [UIView animateWithDuration:0.5 delay:0.7
        //        options:(UIViewAnimationOptionCurveLinear) animations:^{
        //            self.login_Title.alpha = 1.0;
        //            self.titleLab.alpha = 1.0;
        //        } completion:nil];

        CGFloat topY = self.view.safeAreaInsets.top + 10;
        [UIView animateWithDuration:0.5
            delay:1.0
            options:(UIViewAnimationOptionCurveEaseInOut)animations:^{
              self.login_Left.frame = CGRectMake(0, topY, self.login_Left.width,
                                                 self.login_Left.height);
              self.login_right.frame =
                  CGRectMake(self.view.width - self.login_right.width, topY,
                             self.login_right.width, self.login_right.height);
            }
            completion:^(BOOL finished) {
              [self.login_Left
                  mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(self.view);
                    make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(10);
                    make.height.mas_equalTo(267);
                    make.width.mas_equalTo(102);
                  }];
              [self.login_right
                  mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(self.view);
                    make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(10);
                    make.height.mas_equalTo(267);
                    make.width.mas_equalTo(102);
                  }];
            }];
      });
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (UIImageView *)login_Left {
  if (!_login_Left) {
    _login_Left = [[UIImageView alloc] init];

    _login_Left.image = [UIImage imageNamed:@"Bind_Left"];
  }
  return _login_Left;
}

- (UIImageView *)login_right {
  if (!_login_right) {
    _login_right = [[UIImageView alloc] init];

    _login_right.image = [UIImage imageNamed:@"Bind_Right"];
  }
  return _login_right;
}

//- (UIImageView *)login_Title {
//    if(!_login_Title){
//        _login_Title = [[UIImageView alloc]init];
//
//        _login_Title.image = [UIImage imageNamed:@"Login_Title"];
//        _login_Title.alpha = 0.0;
//    }
//    return _login_Title;
//}
//
//- (UILabel *)titleLab {
//    if(!_titleLab){
//        _titleLab = [[UILabel alloc]init];
//        NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
//        initWithString:@"随身云端  智慧无限" attributes:
//        @{NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular"
//        size: 16],NSForegroundColorAttributeName: [UIColor
//        colorWithRed:178/255.0 green:179/255.0 blue:188/255.0 alpha:1]}];
//        _titleLab.attributedText = string;
//        _titleLab.textAlignment = NSTextAlignmentCenter;
//        _titleLab.alpha = 0.0;
//    }
//    return _titleLab;
//}

- (UIImageView *)lockImage {
  if (!_lockImage) {
    _lockImage = [[UIImageView alloc] init];
    _lockImage.image = [UIImage imageNamed:@"Login_Unlock"];
    _lockImage.highlightedImage = [UIImage imageNamed:@"Login_Lock"];
    _lockImage.highlighted = NO;
  }
  return _lockImage;
}

- (UIView *)effectView {
  if (!_effectView) {
    _effectView =
        [[UIView alloc] initWithFrame:CGRectMake(0, 205, self.view.width,
                                                 self.view.height - 205)];
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView =
        [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.frame = _effectView.bounds;
    blurView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_effectView addSubview:blurView];
    _effectView.alpha = 0.0;
  }
  return _effectView;
}

- (UILabel *)inputAlertLab {
  if (!_inputAlertLab) {
    _inputAlertLab = [[UILabel alloc] init];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
        initWithString:@"输入设备密码"
            attributes:@{
              NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Semibold"
                                                    size:16],
              NSForegroundColorAttributeName : [UIColor whiteColor]
            }];
    _inputAlertLab.attributedText = string;
    _inputAlertLab.textAlignment = NSTextAlignmentCenter;
  }
  return _inputAlertLab;
}

- (PasswordInputView *)passwordInputView {
  if (!_passwordInputView) {
    _passwordInputView = [[PasswordInputView alloc] init];
  }
  return _passwordInputView;
}

- (UILabel *)infoAlertLab {
  if (!_infoAlertLab) {
    _infoAlertLab = [[UILabel alloc] init];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
        initWithString:@"已锁定，请30分钟后重试"
            attributes:@{
              NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Regular"
                                                    size:14],
              NSForegroundColorAttributeName : [UIColor colorWithRed:251 / 255.0
                                                               green:92 / 255.0
                                                                blue:92 / 255.0
                                                               alpha:1]
            }];
    _infoAlertLab.attributedText = string;
    _infoAlertLab.textAlignment = NSTextAlignmentCenter;
    _infoAlertLab.hidden = YES;
  }
  return _infoAlertLab;
}

- (CustomKeybordView *)keybordView {
  if (!_keybordView) {
    _keybordView = [[CustomKeybordView alloc] init];
    _keybordView.delegate = self;
  }
  return _keybordView;
}

- (void)customKeybordTapDelegate:(NSNumber *)number {
  NSInteger num = number.integerValue;
  if (num == -2) {
    return;
  } else if (num == -1) {
    [self.passwordArray removeLastObject];
  } else {
    if (self.passwordArray.count >= 6)
      return;
    [self.passwordArray addObject:number];
  }
  [self.passwordInputView updateInputCount:self.passwordArray.count];
  if (self.passwordArray.count == 6) {
      NSString *password = [self stringFormPasswordArray:self.passwordArray];
      NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"userLoginToken"] ?: @"";
      [self loginAndUnbindWithPwd:password Token:token];
  }
}

- (NSString *)stringFormPasswordArray:(NSMutableArray *)array {
  if (array.count == 0) {
    return @"";
  }
  NSMutableString *result = [NSMutableString string];
  for (NSNumber *num in array) {
    [result appendFormat:@"%@", num];
  }
  return result;
}

- (void)loginAndUnbindWithPwd:(NSString *)password Token:(NSString *)token {
  NSLog(@"password = %@", password);
  NSString *url = @"/x/user/verify-password";
  NSDictionary *parameters = @{@"password" : password};

  NSDictionary *header = @{@"Token" : token};

  [[NetworkManager sharedManager] POST:url
      parameters:parameters
      headers:header
      success:^(id _Nonnull responseObject) {
        NSLog(@"responseObject = %@", responseObject);
        [self processDataWithObject:responseObject];
      }
      failure:^(NSError *_Nonnull error) {
        NSLog(@"失败: %@", error.localizedDescription);
      }];
}

- (void)processDataWithObject:(id)object {
  NSNumber *code = object[@"code"];
  if (code) {
    switch (code.intValue) {
    case 0: {
      NSDictionary *data = object[@"data"];
      NSString *type = data[@"type"];
      if ([type isEqualToString:@"start"]) {
        NSString *deviceCode = data[@"deviceCode"];
        NSString *deviceId = [self decryptDeviceCode:deviceCode];
        if (deviceId) {
          UDSetObject(deviceId, DEVICEID);
        }
        [QMUITips showSucceed:@"验证成功" inView:self.view];
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
              [self jumpToConnectVC];
              [self clearPassword];
            });
      } else if ([type isEqualToString:@"unbind"]) {
        // 解绑：清空所有登录凭证
        UDRemove(LOGINTOKEN);
        UDRemove(USERID);
        UDRemove(DEVICEID);
        [self clearPassword];
        // 回到扫码界面
        [self.navigationController popToRootViewControllerAnimated:NO];
        ScanViewController *scanVC = [[ScanViewController alloc] init];
        scanVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController.topViewController presentViewController:scanVC animated:YES completion:nil];
      }
      break;
    }

    case 1:
      if (object[@"message"]) {
        [QMUITips showError:object[@"message"] inView:self.view];
          [self clearPassword];
      }
      break;
    case 2:
      [QMUITips showError:@"登录过期" inView:self.view];
      break;
    case 2001:
      [QMUITips showError:@"服务器错误" inView:self.view];
      break;
    case 2014:
      [QMUITips showError:@"请先扫码绑定" inView:self.view];
      break;
    case 2009:
      [QMUITips showError:@"账号被禁用" inView:self.view];
      break;
    case 2017:
      [QMUITips showError:@"密码错误" inView:self.view];
      break;
    default:
      break;
    }
  }

}

- (nullable NSString *)decryptDeviceCode:(NSString *)hexString {
  if (!hexString || hexString.length == 0) return nil;
  NSData *encrypted = [NSData dataWithHexString:hexString];
  if (!encrypted) return nil;
  NSData *key = [@"aidocksocket43et" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *iv  = [@"I Love Go Frame!" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *decrypted = [encrypted aes256DecryptWithkey:key iv:iv];
  if (!decrypted) return nil;
  NSDictionary *json = [decrypted jsonValueDecoded];
  return json[@"content"][@"id"];
}

- (void)clearPassword {
  [self.passwordArray removeAllObjects];
  [self.passwordInputView updateInputCount:self.passwordArray.count];
}

- (void)jumpToConnectVC {
  ConnectViewController *vc = [[ConnectViewController alloc] init];
  // ConnectVC 会从 DEVICEID 读取设备原始 ID 作为频道名
  [self.navigationController pushViewController:vc animated:NO];
}

- (void)jumpToAgoraVCWithRoomId:(NSString *)roomId {
  AgoraViewController *vc = [[AgoraViewController alloc] initWithChannelId:roomId];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)backToBindVC {
  NSArray *viewControllers = self.navigationController.viewControllers;
  for (UIViewController *vc in viewControllers) {
    if ([vc isKindOfClass:[BindViewController class]]) {
      // 已经存在，直接回退
      [self.navigationController popToViewController:vc animated:NO];
      return;
    }
  }
  // 如果不存在，则新建一个
  BindViewController *bindVC = [[BindViewController alloc] init];
  // 先移除当前VC
  NSMutableArray *mutableVCs = [viewControllers mutableCopy];
  [mutableVCs removeLastObject]; // 移除当前的 self
  [mutableVCs addObject:bindVC]; // 添加新的 BindVC
  [self.navigationController setViewControllers:mutableVCs animated:NO];
}

@end
