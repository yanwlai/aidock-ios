//
//  BindViewController.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/19.
//

#import "BindViewController.h"
#import "AIDOCK-Swift.h"
#import "Common.h"
#import "NetworkManager.h"
// #import "GestureView.h"
@interface BindViewController ()
@property(nonatomic, strong) UIImageView *bind_Left;
@property(nonatomic, strong) UIImageView *bind_right;
@property(nonatomic, strong) UIImageView *bind_Logo;
@property(nonatomic, strong) UIImageView *bind_ScanBorder;
@property(nonatomic, strong) UIImageView *bind_ScanIcon;
@property(nonatomic, strong) UIImageView *bind_Title;
@property(nonatomic, strong) UIView *effectView;
@property(nonatomic, strong) UILabel *titleLab;
@property(nonatomic, strong) UILabel *bindLab;
@property(nonatomic, strong) UIButton *bindBtn;
@property(nonatomic, strong) UILabel *effectTitleLab;
@end

@implementation BindViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  //    self.navigationController.navigationBar.hidden = YES;

  [self.view addSubview:self.bind_Left];
  [self.view addSubview:self.bind_right];
  [self.view addSubview:self.bind_Title];
  [self.view addSubview:self.titleLab];
  [self.view addSubview:self.effectView];

  [self.effectView addSubview:self.bind_ScanBorder];
  [self.effectView addSubview:self.effectTitleLab];
  [self.effectView addSubview:self.bind_ScanIcon];
  [self.effectView addSubview:self.bind_Logo];
  [self.effectView addSubview:self.bindLab];
  [self.effectView addSubview:self.bindBtn];

  //    GestureView* testView = [[GestureView
  //    alloc]initWithFrame:self.view.frame]; [self.view addSubview:testView];
  //

  [self.bind_Left mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(self.view.mas_left);
    make.top.equalTo(self.view.mas_top).offset(160);
    make.height.mas_equalTo(267);
    make.width.mas_equalTo(102);
  }];

  [self.bind_right mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.view.mas_right);
    make.top.equalTo(self.view.mas_top).offset(160);
    make.height.mas_equalTo(267);
    make.width.mas_equalTo(102);
  }];

  [self.bind_Title mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.view);
    make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(10);
    make.height.mas_equalTo(21);
    make.width.mas_equalTo(106);
  }];

  [self.titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.view);
    make.top.equalTo(self.bind_Title.mas_bottom).offset(14);
    make.height.mas_equalTo(22);
  }];

  [self.effectView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.bottom.right.equalTo(self.view);
    make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(140);
  }];

  [self.bind_ScanIcon mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.effectView);
    make.top.equalTo(self.effectView).offset(25);
    make.height.mas_equalTo(44);
    make.width.mas_equalTo(44);
  }];

  [self.effectTitleLab mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.effectView);
    make.top.equalTo(self.bind_ScanIcon.mas_bottom).offset(13);
    make.height.mas_equalTo(22);
    //        make.width.mas_equalTo(96);
  }];

  [self.bind_ScanBorder mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.effectView);
    make.top.equalTo(self.effectTitleLab.mas_bottom).offset(52);
    make.height.mas_equalTo(140);
    make.width.mas_equalTo(140);
  }];

  [self.bind_Logo mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(self.bind_ScanBorder);
    make.height.mas_equalTo(67);
    make.width.mas_equalTo(88);
  }];

  [self.bindLab mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.effectView);
    make.top.equalTo(self.bind_ScanBorder.mas_bottom).offset(71);
    make.height.mas_equalTo(20);
    //        make.width.mas_equalTo(226);
  }];

  [self.bindBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.effectView);
    make.top.equalTo(self.bindLab.mas_bottom).offset(90);
    make.height.mas_equalTo(50);
    make.width.mas_equalTo(290);
  }];

  [[NetworkManager sharedManager] GET:@"https://www.baidu.com"
                           parameters:nil
                              headers:nil
                              success:nil
                              failure:nil];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.bind_Left.frame = CGRectMake(
      -self.bind_Left.width, 160, self.bind_Left.width, self.bind_Left.height);
  self.bind_right.frame =
      CGRectMake(self.view.width + self.bind_right.width, 160,
                 self.bind_right.width, self.bind_right.height);
  self.effectView.alpha = 0.0;
  self.bind_Title.alpha = 0.0;
  self.titleLab.alpha = 0.0;
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

        [UIView
            animateWithDuration:0.5
                          delay:0.7
                        options:(UIViewAnimationOptionCurveLinear)animations:^{
                          self.bind_Title.alpha = 1.0;
                          self.titleLab.alpha = 1.0;
                        }
                     completion:nil];

        CGFloat topY = self.view.safeAreaInsets.top + 10;
        [UIView
            animateWithDuration:0.5
                          delay:1.0
                        options:(UIViewAnimationOptionCurveEaseInOut)animations
                               :^{
                                 self.bind_Left.frame =
                                     CGRectMake(0, topY, self.bind_Left.width,
                                                self.bind_Left.height);
                                 self.bind_right.frame = CGRectMake(
                                     self.view.width - self.bind_right.width,
                                     topY, self.bind_right.width,
                                     self.bind_right.height);
                               }
                     completion:nil];

        self.bind_ScanBorder.transform = CGAffineTransformIdentity;
        [self startBreathAnimation];
      });
}

- (void)startBreathAnimation {
  self.bind_ScanBorder.transform = CGAffineTransformIdentity;
  [UIView animateWithDuration:1
                        delay:2
                      options:UIViewAnimationOptionRepeat |
                              UIViewAnimationOptionAutoreverse |
                              UIViewAnimationOptionAllowUserInteraction
                   animations:^{
                     self.bind_ScanBorder.transform =
                         CGAffineTransformMakeScale(1.1, 1.1);
                   }
                   completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.bind_ScanBorder.layer removeAllAnimations];
}

- (UIImageView *)bind_Left {
  if (!_bind_Left) {
    _bind_Left = [[UIImageView alloc] init];

    _bind_Left.image = [UIImage imageNamed:@"Bind_Left"];
  }
  return _bind_Left;
}

- (UIImageView *)bind_right {
  if (!_bind_right) {
    _bind_right = [[UIImageView alloc] init];

    _bind_right.image = [UIImage imageNamed:@"Bind_Right"];
  }
  return _bind_right;
}

- (UIImageView *)bind_Logo {
  if (!_bind_Logo) {
    _bind_Logo = [[UIImageView alloc] init];

    _bind_Logo.image = [UIImage imageNamed:@"Bind_Logo"];
  }
  return _bind_Logo;
}

- (UIImageView *)bind_ScanBorder {
  if (!_bind_ScanBorder) {
    _bind_ScanBorder = [[UIImageView alloc] init];

    _bind_ScanBorder.image = [UIImage imageNamed:@"Bind_ScanBorder"];
  }
  return _bind_ScanBorder;
}

- (UIImageView *)bind_ScanIcon {
  if (!_bind_ScanIcon) {
    _bind_ScanIcon = [[UIImageView alloc] init];

    _bind_ScanIcon.image = [UIImage imageNamed:@"Bind_ScanIcon"];
  }
  return _bind_ScanIcon;
}

- (UIImageView *)bind_Title {
  if (!_bind_Title) {
    _bind_Title = [[UIImageView alloc] init];

    _bind_Title.image = [UIImage imageNamed:@"Bind_Title"];
    _bind_Title.alpha = 0.0;
  }
  return _bind_Title;
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

- (UILabel *)titleLab {
  if (!_titleLab) {
    _titleLab = [[UILabel alloc] init];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
        initWithString:@"随身云端  智慧无限"
            attributes:@{
              NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Regular"
                                                    size:16],
              NSForegroundColorAttributeName : [UIColor colorWithRed:178 / 255.0
                                                               green:179 / 255.0
                                                                blue:188 / 255.0
                                                               alpha:1]
            }];
    _titleLab.attributedText = string;
    _titleLab.textAlignment = NSTextAlignmentCenter;
    _titleLab.alpha = 0.0;
  }
  return _titleLab;
}

- (UILabel *)effectTitleLab {
  if (!_effectTitleLab) {
    _effectTitleLab = [[UILabel alloc] init];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
        initWithString:@"扫码绑定设备"
            attributes:@{
              NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Semibold"
                                                    size:16],
              NSForegroundColorAttributeName : [UIColor whiteColor]
            }];
    _effectTitleLab.attributedText = string;
    _effectTitleLab.textAlignment = NSTextAlignmentCenter;
  }
  return _effectTitleLab;
}

- (UILabel *)bindLab {
  if (!_bindLab) {
    _bindLab = [[UILabel alloc] init];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
        initWithString:@"点击“扫一扫”，扫描二维码完成绑定"
            attributes:@{
              NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Regular"
                                                    size:16],
              NSForegroundColorAttributeName : [UIColor colorWithRed:178 / 255.0
                                                               green:179 / 255.0
                                                                blue:188 / 255.0
                                                               alpha:1]
            }];
    _bindLab.attributedText = string;
    _bindLab.textAlignment = NSTextAlignmentCenter;
  }
  return _bindLab;
}

- (UIButton *)bindBtn {
  if (!_bindBtn) {
    _bindBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_bindBtn setTitle:@"扫一扫" forState:(UIControlStateNormal)];
    [_bindBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _bindBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [_bindBtn setBackgroundColor:[UIColor colorWithRed:70 / 255.0
                                                 green:109 / 255.0
                                                  blue:248 / 255.0
                                                 alpha:1]];
    _bindBtn.layer.cornerRadius = 10;
    _bindBtn.clipsToBounds = YES;
    [_bindBtn addTarget:self
                  action:@selector(bindBtnClick)
        forControlEvents:(UIControlEventTouchUpInside)];
  }
  return _bindBtn;
}

- (void)bindBtnClick {
  ScanViewController *vc = [[ScanViewController alloc] init];
  vc.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:vc animated:YES completion:nil];
}

@end
