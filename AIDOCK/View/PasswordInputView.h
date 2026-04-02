//
//  PasswordInputView.h
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/20.
//

#import <UIKit/UIKit.h>
#import "PasswordDotView.h"
NS_ASSUME_NONNULL_BEGIN

@interface PasswordInputView : UIView
/// 更新输入长度（比如输入 3 位，就显示 3 个实心点，其余空心）
- (void)updateInputCount:(NSInteger)count;
@end

NS_ASSUME_NONNULL_END
