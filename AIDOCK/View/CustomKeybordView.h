//
//  CustomKeybordView.h
//  AIDOCK
//
//  Created by 曾自立 on 2025/8/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CustomKeybordViewDelegate <NSObject>
- (void)customKeybordTapDelegate:(NSNumber*)number;
@end

@interface CustomKeybordView : UIView
@property(nonatomic, weak) id<CustomKeybordViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
