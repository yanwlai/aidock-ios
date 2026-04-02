//
//  CustomKeybordView.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/20.
//

#import "CustomKeybordView.h"
#import "Masonry.h"
#import "KeybordCell.h"
#import "YYCategories.h"

@interface CustomKeybordView ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,KeybordTapDelegate>
@property(nonatomic, strong) UICollectionView *keybordView;
@property(nonatomic, strong) UIImageView *line1_horz;
@property(nonatomic, strong) UIImageView *line2_horz;
@property(nonatomic, strong) UIImageView *line3_horz;
@property(nonatomic, strong) UIImageView *line1_vert;
@property(nonatomic, strong) UIImageView *line2_vert;
@end

@implementation CustomKeybordView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.keybordView];
        [self addSubview:self.line1_horz];
        [self addSubview:self.line2_horz];
        [self addSubview:self.line3_horz];
        [self addSubview:self.line1_vert];
        [self addSubview:self.line2_vert];
        [self.keybordView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [self.line1_horz mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self).offset(-100);
            make.height.mas_equalTo(1);
            make.centerX.equalTo(self);
            make.centerY.equalTo(self).multipliedBy(0.5);
        }];
        [self.line2_horz mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self).offset(-100);
            make.height.mas_equalTo(1);
            make.centerX.equalTo(self);
            make.centerY.equalTo(self);
        }];
        [self.line3_horz mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self).offset(-100);
            make.height.mas_equalTo(1);
            make.centerX.equalTo(self);
            make.centerY.equalTo(self).multipliedBy(1.5);
        }];
        [self.line1_vert mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(1);
            make.height.equalTo(self);
            make.centerY.equalTo(self);
            make.centerX.equalTo(self).multipliedBy(0.333 / 0.5);
        }];
        [self.line2_vert mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(1);
            make.height.equalTo(self);
            make.centerY.equalTo(self);
            make.centerX.equalTo(self).multipliedBy(0.666 / 0.5);
        }];

    }
    return self;
}

- (UICollectionView *)keybordView {
    if(!_keybordView){
        UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _keybordView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _keybordView.delegate = self;
        _keybordView.dataSource = self;
        [_keybordView registerClass:[KeybordCell class] forCellWithReuseIdentifier:@"cell"];
        _keybordView.backgroundColor = UIColor.clearColor;
    }
    return _keybordView;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 12;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KeybordCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    if(indexPath.row < 9){
        cell.number = @(indexPath.row + 1);
    }else if (indexPath.row == 9){
        cell.number = @(-2);
        cell.image = [UIImage imageNamed:@"Login_Face"];
    }else if (indexPath.row == 10){
        cell.number = @(0);
    }else if (indexPath.row == 11){
        cell.number = @(-1);
        cell.image = [UIImage imageNamed:@"Login_Delete"];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize cellSize = CGSizeMake(collectionView.bounds.size.width / 3, collectionView.bounds.size.height / 4);
    return cellSize;
}

// cell的行间距（竖直方向）
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

// cell的列间距（水平方向）
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (void)keybordTapDelegate:(NSNumber*)number {
    if([self.delegate respondsToSelector:@selector(customKeybordTapDelegate:)]){
        [self.delegate customKeybordTapDelegate:number];
    }
}

- (UIImageView *)line1_horz {
    if(!_line1_horz){
        _line1_horz = [[UIImageView alloc]init];
        _line1_horz.image = [UIImage imageNamed:@"Login_HorzLine"];
    }
    return _line1_horz;
}

- (UIImageView *)line2_horz {
    if(!_line2_horz){
        _line2_horz = [[UIImageView alloc]init];
        _line2_horz.image = [UIImage imageNamed:@"Login_HorzLine"];
    }
    return _line2_horz;
}

- (UIImageView *)line3_horz {
    if(!_line3_horz){
        _line3_horz = [[UIImageView alloc]init];
        _line3_horz.image = [UIImage imageNamed:@"Login_HorzLine"];
    }
    return _line3_horz;
}

- (UIImageView *)line1_vert {
    if(!_line1_vert){
        _line1_vert = [[UIImageView alloc]init];
        _line1_vert.image = [UIImage imageNamed:@"Login_VertLine"];
    }
    return _line1_vert;
}

- (UIImageView *)line2_vert {
    if(!_line2_vert){
        _line2_vert = [[UIImageView alloc]init];
        _line2_vert.image = [UIImage imageNamed:@"Login_VertLine"];
    }
    return _line2_vert;
}

@end
