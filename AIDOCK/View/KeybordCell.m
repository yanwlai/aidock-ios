//
//  KeybordButtonView.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/20.
//

#import "KeybordCell.h"
#import "Masonry.h"

@interface KeybordCell ()
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, strong) UILabel *numberLab;
@property(nonatomic, strong) UIView *circleAlertView;
@property(nonatomic, assign) BOOL isAnimating;

@end

@implementation KeybordCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.circleAlertView];
        [self.contentView addSubview:self.numberLab];
        [self.contentView addSubview:self.imageView];
        
        [self.circleAlertView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.height.width.mas_equalTo(66);
        }];
        
        [self.numberLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.height.mas_equalTo(32);
        }];
        
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.height.width.mas_equalTo(23);
        }];
        
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(KebordTaped)];
        tap1.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tap1];
        
//        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleAlert)];
//        tap2.cancelsTouchesInView = NO;
//        [self.circleAlertView addGestureRecognizer:tap2];
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
    self.imageView.hidden = NO;
    self.numberLab.hidden = YES;
}

- (void)setNumber:(NSNumber *)number
{
    _number = number;
    self.numberLab.text = number.stringValue;
    self.imageView.hidden = YES;
    self.numberLab.hidden = NO;
}

- (UIImageView *)imageView {
    if(!_imageView){
        _imageView = [[UIImageView alloc]init];
    }
    return _imageView;
}

- (UILabel *)numberLab {
    if(!_numberLab){
        _numberLab = [[UILabel alloc]init];
        _numberLab.textColor = UIColor.whiteColor;
        _numberLab.font = [UIFont fontWithName:@"PingFangSC-Regular" size:23];
    }
    return _numberLab;
}

- (UIView *)circleAlertView {
    if(!_circleAlertView){
        _circleAlertView = [[UIView alloc]init];
        _circleAlertView.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.35];
        _circleAlertView.layer.cornerRadius = 33;
        _circleAlertView.clipsToBounds = YES;
        _circleAlertView.alpha = 0.00;
    }
    return _circleAlertView;
}

- (void)KebordTaped {
    if([self.delegate respondsToSelector:@selector(keybordTapDelegate:)]){
        [self.delegate keybordTapDelegate:self.number];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.circleAlertView.alpha = 1.0;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [UIView animateWithDuration:0.15 animations:^{
        self.circleAlertView.alpha = 0.0;
    }];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [UIView animateWithDuration:0.15 animations:^{
        self.circleAlertView.alpha = 0.0;
    }];
}

//- (void)circleAlert {
//    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState animations:^{
//        self.circleAlertView.alpha = 1.0;
//    } completion:^(BOOL finished) {
//        self.circleAlertView.alpha = 0.02;
//    }];
//}
@end
