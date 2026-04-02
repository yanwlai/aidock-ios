//
//  WhiteDotView.h
//  AIDOCK
//
//  Created by AI Assistant on 2026/02/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WhiteDotViewDelegate <NSObject>
- (void)didTapHomeButton;
- (void)didTapBackButton;
- (void)didTapDisconnectButton;
@end

@interface WhiteDotView : UIView

@property(nonatomic, weak) id<WhiteDotViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
