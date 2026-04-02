//
//  PasswordInputView.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/20.
//

#import "PasswordInputView.h"
#import "Masonry.h"
@interface PasswordInputView ()
@property (nonatomic, assign) NSInteger passwordLength;
@property (nonatomic, strong) NSMutableArray<PasswordDotView *> *mutableDots;
@end

@implementation PasswordInputView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _passwordLength = 6;
        _mutableDots = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupDots];
}

- (void)setupDots {
    // 避免重复创建
    if (self.mutableDots.count > 0) return;
    
    CGFloat totalWidth = CGRectGetWidth(self.bounds);
    CGFloat totalHeight = CGRectGetHeight(self.bounds);
    CGFloat spacing = 17.0;
    CGFloat squareSize = (totalWidth - spacing * (self.passwordLength + 1)) / self.passwordLength;
    
    for (int i = 0; i < self.passwordLength; i++) {
        // 每个格子
        UIView *square = [[UIView alloc] initWithFrame:CGRectMake(i * squareSize + (i+1) * spacing, (totalHeight - squareSize) / 2, squareSize, squareSize)];
        square.layer.borderWidth = 1.0;
        square.layer.borderColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.15].CGColor;
        square.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.05];
        square.layer.cornerRadius = 8;
        square.clipsToBounds = YES;
        [self addSubview:square];
        
        // Dot 居中
//        CGFloat dotSize = squareSize * 0.3;
        PasswordDotView *dot = [[PasswordDotView alloc] init];
        [square addSubview:dot];
        [dot mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.width.mas_equalTo(10);
            make.center.equalTo(square);
        }];
        dot.filled = NO; // 默认空心
        
        
        [self.mutableDots addObject:dot];
    }
}


- (void)updateInputCount:(NSInteger)count {
    for (NSInteger i = 0; i < self.mutableDots.count; i++) {
        PasswordDotView *dot = self.mutableDots[i];
        dot.filled = (i < count);
    }
}

@end

