//
//  PasswordDotsView.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/20.
//

#import "PasswordDotView.h"
#import "Masonry.h"

@interface PasswordDotView ()
@property (nonatomic, assign) CGFloat dotSize;
@property (nonatomic, strong) UIColor *filledColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property(nonatomic, strong) UIView *dotView;
@end

@implementation PasswordDotView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _dotSize = 10.0;
        _filledColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
        _strokeColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
        _lineWidth = 1;
        self.backgroundColor = [UIColor clearColor];
        
        self.dotView = [[UIView alloc]init];
        [self addSubview:_dotView];
        [_dotView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        _dotView.layer.borderWidth = 1.0;
        _dotView.layer.borderColor = _strokeColor.CGColor;
        _dotView.backgroundColor = UIColor.clearColor;
        _dotView.layer.cornerRadius = 5;
        _dotView.clipsToBounds = YES;
        _dotView.layer.masksToBounds = YES;
        
    }
    return self;
}

- (void)setFilled:(BOOL)filled {
    _filled = filled;
    [UIView animateWithDuration:0.2 animations:^{
        self.dotView.backgroundColor = filled ? self->_filledColor : UIColor.clearColor;
    }];
    
}


@end
