//
//  WhiteDotView.m
//  AIDOCK
//
//  Created by AI Assistant on 2026/02/12.
//

#import "WhiteDotView.h"

@interface WhiteDotView ()

@property(nonatomic, strong) UIButton *mainButton;
@property(nonatomic, strong) UIButton *homeButton;
@property(nonatomic, strong) UIButton *backButton;
@property(nonatomic, strong) UIButton *disconnectButton;
@property(nonatomic, assign) BOOL isExpanded;
@property(nonatomic, strong) UIView *buttonsContainer;
@property(nonatomic, strong) UIPanGestureRecognizer *panGesture;

@end

@implementation WhiteDotView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  self.backgroundColor = [UIColor clearColor];

  // Create the container for the 3 action buttons
  self.buttonsContainer = [[UIView alloc] init];
  self.buttonsContainer.alpha = 0.0;
  self.buttonsContainer.hidden = YES;
  [self addSubview:self.buttonsContainer];

  // Create the main "White Dot" button
  self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.mainButton.backgroundColor = [UIColor whiteColor];
  self.mainButton.layer.cornerRadius = 25; // Assuming 50x50 size
  self.mainButton.layer.shadowColor = [UIColor blackColor].CGColor;
  self.mainButton.layer.shadowOpacity = 0.3;
  self.mainButton.layer.shadowOffset = CGSizeMake(0, 2);
  self.mainButton.layer.shadowRadius = 4;
  [self.mainButton addTarget:self
                      action:@selector(mainButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.mainButton];

  // Initialize action buttons
  self.homeButton =
      [self createActionButtonWithImageName:@"house.fill"
                                     action:@selector(homeButtonTapped)];
  self.backButton = [self
      createActionButtonWithImageName:@"arrow.turn.up.left"
                               action:@selector(backButtonTapped
                                          )]; // System image might vary by iOS
                                              // version, using a safe one
  self.disconnectButton =
      [self createActionButtonWithImageName:@"phone.down.fill"
                                     action:@selector(disconnectButtonTapped)];
  self.disconnectButton.tintColor =
      [UIColor systemRedColor]; // Make disconnect button red

  [self.buttonsContainer addSubview:self.homeButton];
  [self.buttonsContainer addSubview:self.backButton];
  [self.buttonsContainer addSubview:self.disconnectButton];

  // Add Pan Gesture
  self.panGesture =
      [[UIPanGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(handlePan:)];
  [self.mainButton addGestureRecognizer:self.panGesture];
}

- (UIButton *)createActionButtonWithImageName:(NSString *)imageName
                                       action:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
  btn.backgroundColor = [UIColor whiteColor];
  btn.layer.cornerRadius = 20; // Slightly smaller than main button
  btn.layer.shadowColor = [UIColor blackColor].CGColor;
  btn.layer.shadowOpacity = 0.2;
  btn.layer.shadowOffset = CGSizeMake(0, 1);
  btn.layer.shadowRadius = 3;

  UIImage *img = [UIImage systemImageNamed:imageName];
  [btn setImage:img forState:UIControlStateNormal];
  [btn addTarget:self
                action:action
      forControlEvents:UIControlEventTouchUpInside];
  return btn;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat width = self.bounds.size.width;
  CGFloat height = self.bounds.size.height;
  CGFloat dotSize = 50;

  // Main button is always at the bottom
  self.mainButton.frame =
      CGRectMake((width - dotSize) / 2, height - dotSize, dotSize, dotSize);
  self.mainButton.layer.cornerRadius = dotSize / 2;

  // Buttons container takes the space above
  CGFloat buttonSize = 40;
  CGFloat gap = 10;
  CGFloat containerHeight = (buttonSize * 3) + (gap * 2);

  self.buttonsContainer.frame =
      CGRectMake((width - buttonSize) / 2,
                 self.mainButton.frame.origin.y - containerHeight - gap,
                 buttonSize, containerHeight);

  // Layout buttons inside container
  self.homeButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
  self.backButton.frame =
      CGRectMake(0, buttonSize + gap, buttonSize, buttonSize);
  self.disconnectButton.frame =
      CGRectMake(0, (buttonSize + gap) * 2, buttonSize, buttonSize);
}

- (void)mainButtonTapped {
  if (self.isExpanded) {
    [self collapseButtons];
  } else {
    [self expandButtons];
  }
}

- (void)expandButtons {
  self.isExpanded = YES;
  self.buttonsContainer.hidden = NO;

  // Animation to show buttons
  [UIView animateWithDuration:0.3
                        delay:0
       usingSpringWithDamping:0.7
        initialSpringVelocity:0.5
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
                     self.buttonsContainer.alpha = 1.0;
                     // Verify frame updates if needed, though layoutSubviews
                     // handles positioning
                   }
                   completion:nil];
}

- (void)collapseButtons {
  self.isExpanded = NO;

  [UIView animateWithDuration:0.2
      animations:^{
        self.buttonsContainer.alpha = 0.0;
      }
      completion:^(BOOL finished) {
        self.buttonsContainer.hidden = YES;
        [self moveToBottomRight];
      }];
}

- (void)handlePan:(UIPanGestureRecognizer *)p {
  if (self.isExpanded)
    return; // Don't drag while expanded? Or allow? Better to lock while
            // expanded to avoid complexity.

  UIView *targetView = self; // We move self, not mainButton
  UIView *superView = self.superview;
  if (!superView)
    return;

  CGPoint translation = [p translationInView:superView];

  if (p.state == UIGestureRecognizerStateBegan ||
      p.state == UIGestureRecognizerStateChanged) {
    CGPoint center = targetView.center;
    targetView.center =
        CGPointMake(center.x + translation.x, center.y + translation.y);
    [p setTranslation:CGPointZero inView:superView];
  } else if (p.state == UIGestureRecognizerStateEnded) {
    // Optional: Snap to edge?
    // Requirement just says "automatically move to screen bottom right" after
    // click-collapse. It doesn't restrict dragging position.

    // Ensure it stays within bounds
    CGRect frame = targetView.frame;
    CGRect superBounds = superView.bounds;
    CGFloat margin = 0; // allow touching edge

    // Keep inside screen
    if (frame.origin.x < margin)
      frame.origin.x = margin;
    if (frame.origin.y < margin)
      frame.origin.y = margin;
    if (CGRectGetMaxX(frame) > superBounds.size.width - margin)
      frame.origin.x = superBounds.size.width - margin - frame.size.width;
    if (CGRectGetMaxY(frame) > superBounds.size.height - margin)
      frame.origin.y = superBounds.size.height - margin - frame.size.height;

    [UIView animateWithDuration:0.2
                     animations:^{
                       targetView.frame = frame;
                     }];
  }
}

- (void)moveToBottomRight {
  if (!self.superview)
    return;

  CGFloat margin = 20;
  CGFloat dotSize = 50;
  // Assuming the view should resize to just the dot and move to bottom right
  // However, if we resize the view, the buttons (which are above) might get
  // clipped or the frame logic needs to change.

  // Strategy: The WhiteDotView frame itself moves.
  // When expanded, the frame is tall. When collapsed, the frame is ideally just
  // the dot size? Or we keep the frame large and just move it? The requirement
  // "automatically move to screen bottom right" implies repositioning.

  CGRect superBounds = self.superview.bounds;
  CGFloat safeBottom = self.superview.safeAreaInsets.bottom;

  // Calculate target frame
  // We want the main button (bottom of our view) to be at bottom-right of
  // screen. Our view height effectively includes the hidden buttons space if we
  // don't resize. To make it simple, let's just move the whole view such that
  // the dot ends up in the corner.

  CGFloat targetX = superBounds.size.width - dotSize - margin;
  CGFloat targetY = superBounds.size.height - dotSize - margin - safeBottom;

  // The mainButton is at (0, height - dotSize) if we resize self, or at (0, 0)
  // if self is small. Let's resize self to be small when collapsed? No, that
  // complicates expansion (need to resize up). Let's keep self distinct.

  // Let's say:
  // Expanded Frame: X, Y_top, Width, Height_total
  // Collapsed Frame: X, Y_bot, Width, Height_dot

  // Let's try to resize and move.

  // Target frame for collapsed state (just the dot)
  CGRect targetFrame = CGRectMake(targetX, targetY, dotSize, dotSize);

  [UIView animateWithDuration:0.3
                   animations:^{
                     self.frame = targetFrame;
                     [self layoutIfNeeded]; // This will trigger layoutSubviews
                   }];
}

// Override hitTest to allow touches through transparent areas
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *hitView = [super hitTest:point withEvent:event];
  if (hitView == self) {
    return nil; // Don't block touches on the transparent container background
  }
  return hitView;
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview) {
    // Set initial position to bottom right
    [self moveToBottomRight];
    // Ensure we have enough height to expand later if we start small?
    // Wait, moveToBottomRight sets frame to small dot size.
    // If we expand, we need to increase height and move Y up.
  }
}

// Handle expansion layout logic
- (void)setIsExpanded:(BOOL)isExpanded {
  _isExpanded = isExpanded;

  if (isExpanded) {
    // Expand frame upwards
    CGFloat buttonSize = 40;
    CGFloat gap = 10;
    CGFloat dotSize = 50;
    CGFloat containerHeight = (buttonSize * 3) + (gap * 2);
    CGFloat totalHeight = dotSize + gap + containerHeight;

    CGRect currentFrame = self.frame;
    CGFloat newY =
        currentFrame.origin.y + currentFrame.size.height - totalHeight;

    self.frame = CGRectMake(currentFrame.origin.x, newY,
                            currentFrame.size.width, totalHeight);
    [self layoutIfNeeded];
  } else {
    // Collapse logic is handled in collapseButtons mostly, but frame resize
    // helps cleanup But collapseButtons calls moveToBottomRight which resets
    // the frame.
  }
}

#pragma mark - Actions

- (void)homeButtonTapped {
  if ([self.delegate respondsToSelector:@selector(didTapHomeButton)]) {
    [self.delegate didTapHomeButton];
  }
}

- (void)backButtonTapped {
  if ([self.delegate respondsToSelector:@selector(didTapBackButton)]) {
    [self.delegate didTapBackButton];
  }
}

- (void)disconnectButtonTapped {
  if ([self.delegate respondsToSelector:@selector(didTapDisconnectButton)]) {
    [self.delegate didTapDisconnectButton];
  }
}

@end
