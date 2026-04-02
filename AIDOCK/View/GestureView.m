//
//  GestureView.m
//  AIDOCK
//
//  Created by 曾自立 on 2025/9/23.
//

#import "GestureView.h"
#import "YYCategories.h"

@interface MyTouch : NSObject
@property(nonatomic, strong) UITouch *touch;
@property(nonatomic, assign) NSInteger pointerID;
@end

@implementation MyTouch
@end

@interface GestureView ()
@property(nonatomic, assign) CGSize screenSize;
@property(nonatomic, strong) NSMutableArray<MyTouch *> *touchArry;
@property(nonatomic, assign) NSInteger nextPointerID; // 全局自增 ID，保证唯一
@end

@implementation GestureView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.userInteractionEnabled = YES;
    self.backgroundColor = UIColor.clearColor;
    self.multipleTouchEnabled = YES;
    self.screenSize = UIScreen.mainScreen.bounds.size;
    self.touchArry = [[NSMutableArray alloc] init];
    self.nextPointerID = 1; // 从1开始，0为鼠标默认的point_id
  }
  return self;
}

#pragma mark - Touch Handling

// 手指按下
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    CGPoint point = [touch locationInView:self];
    //        NSLog(@"👉 手指按下: id=%p, 坐标=%@", touch,
    //        NSStringFromCGPoint(point));

    // 分配一个唯一 ID
    NSInteger pid = self.nextPointerID++;
    MyTouch *mytouch = [[MyTouch alloc] init];
    mytouch.touch = touch;
    mytouch.pointerID = pid;
    [self.touchArry addObject:mytouch];

    if (self.touchArry.count == 1) {
      // 第一个手指
      [self sendTouchEvent:ACTION_DOWN point:point pointerId:pid];
    } else {
      // 额外手指
      [self sendTouchEvent:ACTION_POINTER_DOWN point:point pointerId:pid];
    }
  }
}

// 手指移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    CGPoint point = [touch locationInView:self];
    //        NSLog(@"✋ 手指移动: id=%p, 坐标=%@", touch,
    //        NSStringFromCGPoint(point));
    for (MyTouch *mytouch in self.touchArry) {
      if (touch == mytouch.touch) {
        [self sendTouchEvent:ACTION_MOVE
                       point:point
                   pointerId:mytouch.pointerID];
        break;
      }
    }
  }
}

// 手指松开
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  NSMutableArray *toRemove = [NSMutableArray array];
  for (UITouch *touch in touches) {
    CGPoint point = [touch locationInView:self];
    //        NSLog(@"👋 手指松开: id=%p, 坐标=%@", touch,
    //        NSStringFromCGPoint(point));
    for (MyTouch *mytouch in self.touchArry) {
      if (touch == mytouch.touch) {
        if (self.touchArry.count == 1) {
          // 最后一个手指
          [self sendTouchEvent:ACTION_UP
                         point:point
                     pointerId:mytouch.pointerID];
        } else {
          [self sendTouchEvent:ACTION_POINTER_UP
                         point:point
                     pointerId:mytouch.pointerID];
        }
        [toRemove addObject:mytouch];
        break;
      }
    }
  }
  [self.touchArry removeObjectsInArray:toRemove];
}

// 系统中断（电话、通知等）
- (void)touchesCancelled:(NSSet<UITouch *> *)touches
               withEvent:(UIEvent *)event {
  NSMutableArray *toRemove = [NSMutableArray array];
  for (UITouch *touch in touches) {
    CGPoint point = [touch locationInView:self];
    //        NSLog(@"⚠️ 手指取消: id=%p, 坐标=%@", touch,
    //        NSStringFromCGPoint(point));
    for (MyTouch *mytouch in self.touchArry) {
      if (touch == mytouch.touch) {
        [self sendTouchEvent:ACTION_CANCEL
                       point:point
                   pointerId:mytouch.pointerID];
        [toRemove addObject:mytouch];
        break;
      }
    }
  }
  [self.touchArry removeObjectsInArray:toRemove];
}

#pragma mark - Helper

- (void)sendTouchEvent:(ScrcpyTouchAction)action
                 point:(CGPoint)point
             pointerId:(NSInteger)pointerId {
  if (self.delegate &&
      [self.delegate respondsToSelector:@selector
                     (gestureView:
                         didSendTouchEventWithAction:point:pointerId:)]) {
    [self.delegate gestureView:self
        didSendTouchEventWithAction:action
                              point:point
                          pointerId:pointerId];
  }
}

@end
