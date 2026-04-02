#import "NoPopNavigationController.h"

@interface NoPopNavigationController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@end

@implementation NoPopNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.hidden = YES;
    self.delegate = self;

    // 禁用系统自带的边缘滑动返回手势
    self.interactivePopGestureRecognizer.enabled = NO;
    self.interactivePopGestureRecognizer.delegate = self;
    [self.interactivePopGestureRecognizer removeTarget:nil action:nil];

    // 遍历 view 上所有手势识别器，移除系统的边缘滑动手势
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
            gesture.enabled = NO;
            [gesture removeTarget:nil action:nil];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 每次 push/pop 后重新禁用，防止系统恢复
    self.interactivePopGestureRecognizer.enabled = NO;
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        if ([gesture isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
            gesture.enabled = NO;
        }
    }
}

@end
