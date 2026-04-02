//
//  StartViewController.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/19.
//

#import "StartViewController.h"
#import "BindViewController.h"
#import "LoginViewController.h"
#import "Common.h"
@interface StartViewController ()
@property(nonatomic, strong) UIImageView *startImage_TopLeft;
@property(nonatomic, strong) UIImageView *startImage_BotRight;
@property(nonatomic, strong) UIImageView *startImage_Center;
@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.startImage_TopLeft];
    [self.view addSubview:self.startImage_BotRight];
    [self.view addSubview:self.startImage_Center];
    
    [self.startImage_TopLeft mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.top.equalTo(self.view.mas_top);
        make.height.mas_equalTo(214);
        make.width.mas_equalTo(117);
    }];
    
    [self.startImage_BotRight mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_bottom);
        make.height.mas_equalTo(214);
        make.width.mas_equalTo(117);
    }];
    
    [self.startImage_Center mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(150);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            self.startImage_TopLeft.frame = CGRectMake(
                            -self.startImage_TopLeft.width,
                            self.startImage_TopLeft.top,
                            self.startImage_TopLeft.width,
                            self.startImage_TopLeft.height);
            self.startImage_BotRight.frame = CGRectMake(
                            self.view.width,
                            self.startImage_BotRight.top,
                            self.startImage_BotRight.width,
                            self.startImage_BotRight.height);
            self.startImage_Center.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self jumpToBindVC];
            }];
    });
}

- (UIImageView *)startImage_TopLeft {
    if(!_startImage_TopLeft){
        _startImage_TopLeft = [[UIImageView alloc]init];
        
        _startImage_TopLeft.image = [UIImage imageNamed:@"Start_TopLeft"];
    }
    return _startImage_TopLeft;
}

- (UIImageView *)startImage_BotRight {
    if(!_startImage_BotRight){
        _startImage_BotRight = [[UIImageView alloc]init];
        
        _startImage_BotRight.image = [UIImage imageNamed:@"Start_BotRight"];
    }
    return _startImage_BotRight;
}

- (UIImageView *)startImage_Center {
    if(!_startImage_Center){
        _startImage_Center = [[UIImageView alloc]init];
        
        _startImage_Center.image = [UIImage imageNamed:@"Start_Center"];
    }
    return _startImage_Center;
}

- (void)jumpToBindVC
{
    NSString* token = [[NSUserDefaults standardUserDefaults]valueForKey:LOGINTOKEN];
    if(token && ![token isEqualToString:@""]){
        // 有登录凭证，跳转到输入密码页面
        LoginViewController *loginVC = [[LoginViewController alloc] init];
        [self.navigationController pushViewController:loginVC animated:NO];
    }else{
        BindViewController* bindVC = [[BindViewController alloc]init];
        [self.navigationController pushViewController:bindVC animated:NO];
    }
}

@end
