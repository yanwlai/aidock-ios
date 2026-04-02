//
//  GestureView.h
//  AIDOCK
//
//  Created by 曾自立 on 2025/9/23.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ScrcpyTouchAction) {
  ACTION_DOWN = 0,
  ACTION_UP = 1,
  ACTION_MOVE = 2,
  ACTION_CANCEL = 3,
  ACTION_OUTSIDE = 4,
  ACTION_POINTER_DOWN = 5,
  ACTION_POINTER_UP = 6,
};

@class GestureView;

@protocol GestureViewDelegate <NSObject>

- (void)gestureView:(GestureView *)gestureView
    didSendTouchEventWithAction:(ScrcpyTouchAction)action
                          point:(CGPoint)point
                      pointerId:(NSInteger)pointerId;

@end

NS_ASSUME_NONNULL_BEGIN

@interface GestureView : UIView
@property(nonatomic, weak) id<GestureViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
