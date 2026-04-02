//
//  KeybordButtonView.h
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KeybordTapDelegate <NSObject>
- (void)keybordTapDelegate:(NSNumber*)number;
@end

@interface KeybordCell : UICollectionViewCell
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) NSNumber *number;
@property(nonatomic, weak) id<KeybordTapDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
