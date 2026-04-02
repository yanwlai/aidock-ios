//
//  ConnectViewController.m
//  AIDOCK
//

#import "ConnectViewController.h"
#import "CLHaloLabel.h"
#import "Common.h"
#import "AgoraTokenBuilder.h"
#import <AVFoundation/AVFoundation.h>
#import <AgoraRtcKit/AgoraRtcKit.h>
#import <AgoraRtmKit/AgoraRtmKit.h>

static NSString *const kAgoraAppID   = @"96e0903db2204c4486497833ef3c4667";
static NSString *const kAgoraCert    = @"895d9c4ff1a04ab4ade5695850de0e42";
static const uint32_t  kTokenExpire  = 3600; // token 有效期 1 小时

// Android MotionEvent action constants
static const int kActionDown        = 0;
static const int kActionUp          = 1;
static const int kActionMove        = 2;
static const int kActionCancel      = 3;
static const int kActionPointerDown = 5;
static const int kActionPointerUp   = 6;

// Android KeyEvent action constants
static const int kKeyActionDown = 0;
static const int kKeyActionUp   = 1;

// Android KEYCODE constants
static const int kKeycodeHome      = 3;
static const int kKeycodeBack      = 4;
static const int kKeycodeEnter     = 66;
static const int kKeycodeDel       = 67;
static const int kKeycodeAppSwitch = 187;

#pragma mark - Hidden Input Field (captures delete key)

@interface _HiddenInputField : UITextField
@property (nonatomic, copy) void (^onDeleteBackward)(void);
@end

@implementation _HiddenInputField
- (void)deleteBackward {
    if (self.onDeleteBackward) self.onDeleteBackward();
    [super deleteBackward];
}
@end

#pragma mark -

@interface ConnectViewController () <AgoraRtcEngineDelegate, AgoraRtmClientDelegate, UITextFieldDelegate>

// UI
@property (nonatomic, strong) AVQueuePlayer    *queuePlayer;
@property (nonatomic, strong) AVPlayerLooper   *playerLooper;
@property (nonatomic, strong) AVPlayerLayer    *playerLayer;
@property (nonatomic, strong) UIView           *videoView;
@property (nonatomic, strong) UILabel          *progressLab;
@property (nonatomic, assign) NSInteger         startValue;
@property (nonatomic, assign) NSInteger         endValue;
@property (nonatomic, assign) CFTimeInterval    startTime;
@property (nonatomic, assign) NSTimeInterval    duration;
@property (nonatomic, strong) CADisplayLink    *progressLink;
@property (nonatomic, weak)   CLHaloLabel      *haloLabel;

// Remote control UI
@property (nonatomic, strong) UIView             *touchOverlay;
@property (nonatomic, strong) _HiddenInputField  *hiddenTextField;

// 悬浮球
@property (nonatomic, strong) UIView             *floatingBall;
@property (nonatomic, strong) UIView             *floatingMenu;
@property (nonatomic, assign) BOOL                floatingMenuVisible;
@property (nonatomic, assign) BOOL                localMediaEnabled;

// Agora
@property (nonatomic, strong) AgoraRtcEngineKit *rtcEngine;
@property (nonatomic, strong) AgoraRtmClientKit  *rtmClientKit;
@property (nonatomic, copy)   NSString          *channelName;
@property (nonatomic, assign) NSInteger          dataStreamId;

// 延迟显示
@property (nonatomic, strong) UILabel            *latencyLabel;

// Remote control state
@property (nonatomic, assign) BOOL               remoteConnected;
@property (nonatomic, assign) NSUInteger          remoteUid;
@property (nonatomic, strong) NSMapTable<UITouch *, NSNumber *> *touchIdMap;
@property (nonatomic, assign) int                 nextPointerId;
@property (nonatomic, assign) CFTimeInterval      lastMoveTime;

@end

@implementation ConnectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    // Touch tracking
    self.touchIdMap = [NSMapTable strongToStrongObjectsMapTable];
    self.nextPointerId = 0;

    [self.view addSubview:self.videoView];
    [self.view addSubview:self.progressLab];

    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.height.mas_equalTo(424);
        make.width.equalTo(self.view);
    }];

    [self.progressLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(29);
    }];

    // Transparent touch overlay (on top of video, captures touch events)
    self.touchOverlay = [[UIView alloc] init];
    self.touchOverlay.backgroundColor = [UIColor clearColor];
    self.touchOverlay.multipleTouchEnabled = YES;
    self.touchOverlay.hidden = YES;
    [self.view addSubview:self.touchOverlay];
    [self.touchOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.videoView);
    }];

    // 悬浮球
    [self setupFloatingBall];

    // Hidden text field for keyboard input
    [self setupHiddenTextField];

    // Background animation video
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    if (path) {
        NSURL *url = [NSURL fileURLWithPath:path];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        self.queuePlayer = [AVQueuePlayer playerWithPlayerItem:item];
        self.playerLooper = [AVPlayerLooper playerLooperWithPlayer:self.queuePlayer templateItem:item];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.queuePlayer];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.videoView.layer addSublayer:self.playerLayer];
        [self.queuePlayer play];
    }

    // 频道名：设备号 + "2ai0do2ck6" 后取 MD5（小写）
    NSString *deviceId = UDGetObject(DEVICEID) ?: @"";
    NSString *raw = [deviceId stringByAppendingString:@"2ai0do2ck6"];
    self.channelName = [raw md5String];
    NSLog(@"[Agora] deviceId=%@, channelName(md5)=%@", deviceId, self.channelName);

    // 监听 App 进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    // 先登录 RTM 发送 "join"，成功后再加入 RTC
    [self loginRTM];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self animateProgressLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = self.videoView.bounds;
    [self setHaloLabel];
}

- (BOOL)prefersStatusBarHidden {
    return self.remoteConnected;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return self.remoteConnected ? UIRectEdgeAll : UIRectEdgeNone;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.progressLink invalidate];
    [self.rtcEngine leaveChannel:nil];
    [AgoraRtcEngineKit destroy];
    [self.rtmClientKit logout:nil];
    self.rtmClientKit = nil;
}

#pragma mark - Agora RTC

- (void)initRTC {
    NSLog(@"[RTC] 1. 初始化 RTC SDK, appId=%@", kAgoraAppID);
    AgoraRtcEngineConfig *config = [[AgoraRtcEngineConfig alloc] init];
    config.appId = kAgoraAppID;
    self.rtcEngine = [AgoraRtcEngineKit sharedEngineWithConfig:config delegate:self];

    [self.rtcEngine enableVideo];
    [self.rtcEngine enableAudio];
    [self.rtcEngine setDefaultAudioRouteToSpeakerphone:YES];

    // 默认关闭本地采集设备（摄像头和麦克风）
    [self.rtcEngine enableLocalVideo:NO];
    [self.rtcEngine enableLocalAudio:NO];

    // 视频编码配置，和 Android Demo 保持一致
    AgoraVideoEncoderConfiguration *videoConfig = [[AgoraVideoEncoderConfiguration alloc]
        initWithSize:CGSizeMake(640, 360)
           frameRate:AgoraVideoFrameRateFps15
             bitrate:AgoraVideoBitrateStandard
     orientationMode:AgoraVideoOutputOrientationModeAdaptative
          mirrorMode:AgoraVideoMirrorModeAuto];
    videoConfig.codecType = AgoraVideoCodecTypeH264;
    [self.rtcEngine setVideoEncoderConfiguration:videoConfig];
    NSLog(@"[RTC] 2. 已启用音视频, 640x360@15fps H264, 扬声器播放");

    AgoraRtcChannelMediaOptions *options = [[AgoraRtcChannelMediaOptions alloc] init];
    options.channelProfile         = AgoraChannelProfileLiveBroadcasting;
    options.clientRoleType         = AgoraClientRoleBroadcaster;
    options.autoSubscribeVideo     = YES;
    options.autoSubscribeAudio     = YES;
    options.publishCameraTrack     = NO;
    options.publishMicrophoneTrack = NO;

    NSUInteger rtcUid = [UDGetObject(USERID) integerValue];
    NSLog(@"[RTC] 3. 请求 RTC token, channelName=%@, uid=%lu", self.channelName, (unsigned long)rtcUid);
    [AgoraTokenBuilder genRtcTokenWithAppId:kAgoraAppID
                             appCertificate:kAgoraCert
                                channelName:self.channelName
                                        uid:rtcUid
                                     expire:kTokenExpire
                                 completion:^(NSString *rtcToken) {
        if (!rtcToken) {
            NSLog(@"[RTC] 4. token 请求失败, 使用空 token 加入");
            rtcToken = @"";
        } else {
            NSLog(@"[RTC] 4. token 获取成功: %@", rtcToken);
        }
        NSLog(@"[RTC] 5. 开始加入频道: %@, uid=%lu", self.channelName, (unsigned long)rtcUid);
        [self.rtcEngine joinChannelByToken:rtcToken
                                 channelId:self.channelName
                                       uid:rtcUid
                              mediaOptions:options
                               joinSuccess:nil];
    }];
}

#pragma mark - Agora RTM

- (void)loginRTM {
    NSString *userId = UDGetObject(USERID) ?: [[NSUUID UUID] UUIDString];
    NSLog(@"[RTM] 1. 初始化 RTM v2, appId=%@, userId=%@", kAgoraAppID, userId);

    // RTM v2: 使用 AgoraRtmClientConfig 初始化
    AgoraRtmClientConfig *rtmConfig = [[AgoraRtmClientConfig alloc] initWithAppId:kAgoraAppID userId:userId];
    NSError *initError = nil;
    self.rtmClientKit = [[AgoraRtmClientKit alloc] initWithConfig:rtmConfig delegate:self error:&initError];
    if (initError) {
        NSLog(@"[RTM] 1. 初始化失败: %@, fallback to RTC", initError);
        [self initRTC];
        return;
    }
    NSLog(@"[RTM] 2. 初始化成功, 请求 RTM token");

    [AgoraTokenBuilder genRtmTokenWithAppId:kAgoraAppID
                             appCertificate:kAgoraCert
                                     userId:userId
                                     expire:kTokenExpire
                                 completion:^(NSString *rtmToken) {
        if (!rtmToken) {
            NSLog(@"[RTM] 3. token 请求失败, fallback to RTC");
            [self initRTC];
            return;
        }
        NSLog(@"[RTM] 3. token 获取成功: %@", rtmToken);
        NSLog(@"[RTM] 4. 开始登录");

        // RTM v2: login 只需 token
        [self.rtmClientKit loginByToken:rtmToken completion:^(AgoraRtmCommonResponse * _Nullable response, AgoraRtmErrorInfo * _Nullable errorInfo) {
            if (errorInfo && errorInfo.errorCode != AgoraRtmErrorOk) {
                NSLog(@"[RTM] 5. 登录失败: code=%ld, reason=%@", (long)errorInfo.errorCode, errorInfo.reason);
                [self initRTC];
            } else {
                NSLog(@"[RTM] 5. 登录成功");
                [self subscribeAndPublish];
            }
        }];
    }];
}

- (void)subscribeAndPublish {
    NSLog(@"[RTM] 6. 订阅频道: %@", self.channelName);

    // RTM v2: subscribe 替代 createChannel + join
    AgoraRtmSubscribeOptions *options = [[AgoraRtmSubscribeOptions alloc] init];
    options.features = AgoraRtmSubscribeChannelFeatureMessage;
    [self.rtmClientKit subscribeWithChannel:self.channelName option:options completion:^(AgoraRtmCommonResponse * _Nullable response, AgoraRtmErrorInfo * _Nullable errorInfo) {
        if (errorInfo && errorInfo.errorCode != AgoraRtmErrorOk) {
            NSLog(@"[RTM] 7. 订阅频道失败: code=%ld, reason=%@", (long)errorInfo.errorCode, errorInfo.reason);
            [self initRTC];
            return;
        }
        NSLog(@"[RTM] 7. 订阅频道成功, 发送 'join' 消息");

        // RTM v2: publish 替代 channel sendMessage
        AgoraRtmPublishOptions *pubOptions = [[AgoraRtmPublishOptions alloc] init];
        [self.rtmClientKit publish:self.channelName message:@"join" option:pubOptions completion:^(AgoraRtmCommonResponse * _Nullable response, AgoraRtmErrorInfo * _Nullable errorInfo) {
            if (errorInfo && errorInfo.errorCode != AgoraRtmErrorOk) {
                NSLog(@"[RTM] 8. publish 失败: code=%ld, reason=%@", (long)errorInfo.errorCode, errorInfo.reason);
            } else {
                NSLog(@"[RTM] 8. publish 'join' 成功");
            }
            // RTM 完成，加入 RTC
            [self initRTC];
        }];
    }];
}

#pragma mark - AgoraRtcEngineDelegate

- (void)rtcEngine:(AgoraRtcEngineKit *)engine
   didJoinChannel:(NSString *)channel
          withUid:(NSUInteger)uid
          elapsed:(NSInteger)elapsed {
    NSLog(@"[RTC] 6. 已加入频道 %@, 本地uid=%lu, 耗时=%ldms", channel, (unsigned long)uid, (long)elapsed);

    // 创建 Data Stream 用于发送控制指令
    AgoraDataStreamConfig *streamConfig = [[AgoraDataStreamConfig alloc] init];
    streamConfig.ordered = YES;
    streamConfig.syncWithAudio = NO;
    NSInteger streamId = 0;
    int ret = [self.rtcEngine createDataStream:&streamId config:streamConfig];
    if (ret == 0) {
        self.dataStreamId = streamId;
        NSLog(@"[RTC] Data stream created, id=%ld", (long)streamId);
    } else {
        NSLog(@"[RTC] Failed to create data stream: %d", ret);
    }
}

/// 切换到操控云机 UI（隐藏加载动画，显示触摸层和导航栏）
- (void)showControlUI {
    self.remoteConnected = YES;

    // 停止背景动画视频
    [self.queuePlayer pause];
    [self.playerLayer removeFromSuperlayer];

    // 隐藏连接中的 UI
    self.progressLab.hidden = YES;
    self.haloLabel.hidden   = YES;
    [self.progressLink invalidate];
    self.progressLink = nil;

    // 扩大 videoView（顶部从安全区开始，左右填满，底部留出安全区供本机上滑操作）
    [self.videoView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];

    // 显示触摸层和悬浮球
    self.touchOverlay.hidden  = NO;
    self.floatingBall.hidden  = NO;

    // 延迟标签（左上角安全区下方）
    self.latencyLabel = [[UILabel alloc] init];
    self.latencyLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.latencyLabel.textColor = [UIColor whiteColor];
    self.latencyLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.latencyLabel.textAlignment = NSTextAlignmentCenter;
    self.latencyLabel.layer.cornerRadius = 4;
    self.latencyLabel.clipsToBounds = YES;
    self.latencyLabel.text = @" 0ms ";
    [self.view addSubview:self.latencyLabel];
    [self.latencyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(8);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(4);
    }];

    [self setNeedsStatusBarAppearanceUpdate];
    [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine
   didJoinedOfUid:(NSUInteger)uid
          elapsed:(NSInteger)elapsed {
    NSLog(@"[RTC] 7. 远端用户 %lu 加入频道, elapsed=%ldms", (unsigned long)uid, (long)elapsed);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.remoteUid = uid;
        NSLog(@"[RTC] 8. 设置远端视频画面, uid=%lu", (unsigned long)uid);

        // 显示远端画面
        AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
        canvas.uid        = uid;
        canvas.view       = self.videoView;
        canvas.renderMode = AgoraVideoRenderModeFit;
        [self.rtcEngine setupRemoteVideo:canvas];

        // 如果还没切换到操控界面，切换
        if (!self.remoteConnected) {
            NSLog(@"[RTC] 9. 切换到操控云机界面");
            [self showControlUI];
        }
    });
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine
  didOfflineOfUid:(NSUInteger)uid
           reason:(AgoraUserOfflineReason)reason {
    NSLog(@"[RTC] 10. 远端用户 %lu 离线, reason=%ld", (unsigned long)uid, (long)reason);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.remoteConnected = NO;
        self.remoteUid = 0;

        // 清除远端画面
        AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
        canvas.uid  = uid;
        canvas.view = nil;
        [self.rtcEngine setupRemoteVideo:canvas];

        // 隐藏控制 UI
        self.touchOverlay.hidden  = YES;
        self.floatingBall.hidden  = YES;
        self.floatingMenu.hidden  = YES;
        self.floatingMenuVisible  = NO;
        [self.latencyLabel removeFromSuperview];
        self.latencyLabel = nil;
        self.progressLab.hidden   = NO;
        self.haloLabel.hidden     = NO;
        [self.hiddenTextField resignFirstResponder];

        // 恢复 videoView 布局
        [self.videoView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.view);
            make.height.mas_equalTo(424);
            make.width.equalTo(self.view);
        }];

        // 恢复背景动画视频
        if (self.playerLayer && !self.playerLayer.superlayer) {
            [self.videoView.layer addSublayer:self.playerLayer];
            self.playerLayer.frame = self.videoView.bounds;
            [self.queuePlayer play];
        }

        // 清除触摸状态
        [self.touchIdMap removeAllObjects];
        self.nextPointerId = 0;

        [self setNeedsStatusBarAppearanceUpdate];
        [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    });
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteVideoStats:(AgoraRtcRemoteVideoStats *)stats {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.latencyLabel) {
            self.latencyLabel.text = [NSString stringWithFormat:@" %lums ", (unsigned long)stats.e2eDelay];
        }
    });
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"[RTC] error: %ld", (long)errorCode);
}

#pragma mark - AgoraRtmClientDelegate

- (void)rtmKit:(AgoraRtmClientKit *)rtmKit didReceiveMessageEvent:(AgoraRtmMessageEvent *)event {
    NSLog(@"[RTM] 收到消息: channel=%@, publisher=%@, message=%@",
          event.channelName, event.publisher, event.message.stringData);
}

- (void)rtmKit:(AgoraRtmClientKit *)kit channel:(NSString *)channelName connectionChangedToState:(AgoraRtmClientConnectionState)state reason:(AgoraRtmClientConnectionChangeReason)reason {
    NSLog(@"[RTM] 连接状态变化: channel=%@, state=%ld, reason=%ld", channelName, (long)state, (long)reason);
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.remoteConnected) return;

    for (UITouch *touch in touches) {
        if (touch.view != self.touchOverlay) continue;

        BOOL isFirst = (self.touchIdMap.count == 0);
        int pid = self.nextPointerId++;
        [self.touchIdMap setObject:@(pid) forKey:touch];

        NSArray *pointers = [self buildPointerArray];
        int action;
        if (isFirst) {
            action = kActionDown;
        } else {
            int newIndex = [self indexOfPointerId:pid inPointers:pointers];
            action = kActionPointerDown | (newIndex << 8);
        }
        [self sendTouchAction:action pointers:pointers];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.remoteConnected) return;

    // 节流：最多 60fps
    CFTimeInterval now = CACurrentMediaTime();
    if (now - self.lastMoveTime < 1.0 / 60.0) return;
    self.lastMoveTime = now;

    BOOL hasTracked = NO;
    for (UITouch *touch in touches) {
        if ([self.touchIdMap objectForKey:touch]) { hasTracked = YES; break; }
    }
    if (!hasTracked) return;

    [self sendTouchAction:kActionMove pointers:[self buildPointerArray]];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.remoteConnected) return;

    for (UITouch *touch in touches) {
        NSNumber *pid = [self.touchIdMap objectForKey:touch];
        if (!pid) continue;

        BOOL isLast = (self.touchIdMap.count == 1);
        NSArray *pointers = [self buildPointerArray];

        int action;
        if (isLast) {
            action = kActionUp;
        } else {
            int idx = [self indexOfPointerId:pid.intValue inPointers:pointers];
            action = kActionPointerUp | (idx << 8);
        }
        [self sendTouchAction:action pointers:pointers];
        [self.touchIdMap removeObjectForKey:touch];
    }

    if (self.touchIdMap.count == 0) {
        self.nextPointerId = 0;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.remoteConnected) return;

    NSArray *pointers = [self buildPointerArray];
    if (pointers.count > 0) {
        [self sendTouchAction:kActionCancel pointers:pointers];
    }
    [self.touchIdMap removeAllObjects];
    self.nextPointerId = 0;
}

/// 构建当前所有触摸点的归一化坐标数组
- (NSArray *)buildPointerArray {
    NSMutableArray *result = [NSMutableArray array];
    CGSize size = self.touchOverlay.bounds.size;
    if (size.width <= 0 || size.height <= 0) return result;

    NSEnumerator *keyEnum = [self.touchIdMap keyEnumerator];
    UITouch *touch;
    while ((touch = [keyEnum nextObject])) {
        NSNumber *pid = [self.touchIdMap objectForKey:touch];
        CGPoint pt = [touch locationInView:self.touchOverlay];
        float nx = MAX(0, MIN(1, (float)(pt.x / size.width)));
        float ny = MAX(0, MIN(1, (float)(pt.y / size.height)));
        [result addObject:@{@"id": pid, @"x": @(nx), @"y": @(ny)}];
    }

    // 按 pointer id 排序，保证顺序一致
    [result sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"id"] compare:b[@"id"]];
    }];
    return result;
}

- (int)indexOfPointerId:(int)pid inPointers:(NSArray *)pointers {
    for (int i = 0; i < (int)pointers.count; i++) {
        if ([pointers[i][@"id"] intValue] == pid) return i;
    }
    return 0;
}

#pragma mark - Input Command Sending

- (void)sendTouchAction:(int)action pointers:(NSArray *)pointers {
    [self sendInputCommand:@{
        @"type"    : @"touch",
        @"action"  : @(action),
        @"pointers": pointers,
        @"ts"      : @([self currentTimestampMs])
    }];
}

/// 发送一次完整的按键事件 (down + up)
- (void)sendKeyEvent:(int)keyCode {
    [self sendInputCommand:@{
        @"type"   : @"key",
        @"keyCode": @(keyCode),
        @"action" : @(kKeyActionDown),
        @"ts"     : @([self currentTimestampMs])
    }];
    [self sendInputCommand:@{
        @"type"   : @"key",
        @"keyCode": @(keyCode),
        @"action" : @(kKeyActionUp),
        @"ts"     : @([self currentTimestampMs])
    }];
}

- (void)sendTextContent:(NSString *)text {
    [self sendInputCommand:@{
        @"type"   : @"text",
        @"content": text ?: @"",
        @"ts"     : @([self currentTimestampMs])
    }];
}

/// 序列化为 JSON 并通过 RTC Data Stream 发送
- (void)sendInputCommand:(NSDictionary *)cmd {
    if (self.dataStreamId <= 0) {
        NSLog(@"[Input] data stream not ready");
        return;
    }
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:cmd options:0 error:&err];
    if (!data) {
        NSLog(@"[Input] JSON serialize error: %@", err);
        return;
    }
    int ret = [self.rtcEngine sendStreamMessage:self.dataStreamId data:data];
    if (ret != 0) {
        NSLog(@"[Input] sendStreamMessage failed: %d", ret);
    }
}

- (long long)currentTimestampMs {
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000);
}

#pragma mark - Floating Ball

- (void)setupFloatingBall {
    // 悬浮球
    CGFloat ballSize = 44;
    self.floatingBall = [[UIView alloc] initWithFrame:CGRectMake(16, 200, ballSize, ballSize)];
    self.floatingBall.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    self.floatingBall.layer.cornerRadius = ballSize / 2;
    self.floatingBall.hidden = YES;
    [self.view addSubview:self.floatingBall];

    UIImageView *ballIcon = [[UIImageView alloc] initWithImage:
        [UIImage systemImageNamed:@"circle.grid.2x2.fill"
                withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:20]]];
    ballIcon.tintColor = [UIColor whiteColor];
    ballIcon.frame = CGRectMake(0, 0, ballSize, ballSize);
    ballIcon.contentMode = UIViewContentModeCenter;
    [self.floatingBall addSubview:ballIcon];

    // 点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFloatingMenu)];
    [self.floatingBall addGestureRecognizer:tap];

    // 拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFloatingBall:)];
    [self.floatingBall addGestureRecognizer:pan];

    // 悬浮菜单
    [self setupFloatingMenu];
}

- (void)setupFloatingMenu {
    self.floatingMenu = [[UIView alloc] init];
    self.floatingMenu.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
    self.floatingMenu.layer.cornerRadius = 12;
    self.floatingMenu.hidden = YES;
    [self.view addSubview:self.floatingMenu];

    NSArray *items = @[
        @{@"icon": @"chevron.backward",     @"title": @"返回",       @"action": NSStringFromSelector(@selector(menuBackAction))},
        @{@"icon": @"house",                 @"title": @"回到首页",   @"action": NSStringFromSelector(@selector(menuHomeAction))},
        @{@"icon": @"clock.arrow.circlepath",@"title": @"最近历史",   @"action": NSStringFromSelector(@selector(menuRecentsAction))},
        @{@"icon": @"video.slash",            @"title": @"已关闭音视频", @"action": NSStringFromSelector(@selector(menuToggleLocalMedia))},
        @{@"icon": @"camera.rotate",         @"title": @"切换摄像头", @"action": NSStringFromSelector(@selector(menuSwitchCamera))},
        @{@"icon": @"xmark.circle",          @"title": @"退出",       @"action": NSStringFromSelector(@selector(menuExitAction))},
    ];

    CGFloat btnHeight = 44;
    CGFloat menuWidth = 150;
    CGFloat menuHeight = btnHeight * items.count;

    for (NSUInteger i = 0; i < items.count; i++) {
        NSDictionary *item = items[i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(0, btnHeight * i, menuWidth, btnHeight);
        btn.tintColor = [UIColor whiteColor];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 0);
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
        btn.tag = 100 + i;

        UIImageSymbolConfiguration *imgConfig = [UIImageSymbolConfiguration configurationWithPointSize:16];
        [btn setImage:[UIImage systemImageNamed:item[@"icon"] withConfiguration:imgConfig] forState:UIControlStateNormal];
        [btn setTitle:item[@"title"] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchUpInside];

        [self.floatingMenu addSubview:btn];
    }

    self.floatingMenu.frame = CGRectMake(0, 0, menuWidth, menuHeight);
    self.localMediaEnabled = NO; // 默认关闭
}

- (void)toggleFloatingMenu {
    self.floatingMenuVisible = !self.floatingMenuVisible;
    if (self.floatingMenuVisible) {
        // 定位菜单在悬浮球旁边
        CGRect ballFrame = self.floatingBall.frame;
        CGFloat menuX = CGRectGetMaxX(ballFrame) + 8;
        CGFloat menuY = ballFrame.origin.y;
        CGFloat menuH = self.floatingMenu.frame.size.height;

        // 防止超出屏幕底部
        if (menuY + menuH > self.view.bounds.size.height - 20) {
            menuY = self.view.bounds.size.height - menuH - 20;
        }
        // 防止超出屏幕右侧
        if (menuX + self.floatingMenu.frame.size.width > self.view.bounds.size.width - 8) {
            menuX = ballFrame.origin.x - self.floatingMenu.frame.size.width - 8;
        }

        self.floatingMenu.frame = CGRectMake(menuX, menuY,
                                              self.floatingMenu.frame.size.width,
                                              self.floatingMenu.frame.size.height);
        self.floatingMenu.alpha = 0;
        self.floatingMenu.hidden = NO;
        [self.view bringSubviewToFront:self.floatingMenu];
        [UIView animateWithDuration:0.2 animations:^{
            self.floatingMenu.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.floatingMenu.alpha = 0;
        } completion:^(BOOL finished) {
            self.floatingMenu.hidden = YES;
        }];
    }
}

- (void)dragFloatingBall:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.view];
    CGPoint center = self.floatingBall.center;
    center.x += translation.x;
    center.y += translation.y;

    // 限制在屏幕内
    CGFloat halfW = self.floatingBall.frame.size.width / 2;
    CGFloat halfH = self.floatingBall.frame.size.height / 2;
    center.x = MAX(halfW, MIN(self.view.bounds.size.width - halfW, center.x));
    center.y = MAX(self.view.safeAreaInsets.top + halfH, MIN(self.view.bounds.size.height - halfH, center.y));

    self.floatingBall.center = center;
    [pan setTranslation:CGPointZero inView:self.view];

    // 拖拽时隐藏菜单
    if (self.floatingMenuVisible) {
        self.floatingMenu.hidden = YES;
        self.floatingMenuVisible = NO;
    }
}

#pragma mark - Floating Menu Actions

- (void)menuBackAction {
    [self toggleFloatingMenu];
    [self sendKeyEvent:kKeycodeBack];
}

- (void)menuHomeAction {
    [self toggleFloatingMenu];
    [self sendKeyEvent:kKeycodeHome];
}

- (void)menuRecentsAction {
    [self toggleFloatingMenu];
    [self sendKeyEvent:kKeycodeAppSwitch];
}

- (void)menuToggleLocalMedia {
    self.localMediaEnabled = !self.localMediaEnabled;

    // 开启/关闭本地采集设备（摄像头和麦克风）
    [self.rtcEngine enableLocalVideo:self.localMediaEnabled];
    [self.rtcEngine enableLocalAudio:self.localMediaEnabled];
    [self.rtcEngine muteLocalVideoStream:!self.localMediaEnabled];
    [self.rtcEngine muteLocalAudioStream:!self.localMediaEnabled];

    // 更新频道媒体选项，发布/取消发布本地音视频轨道
    AgoraRtcChannelMediaOptions *opts = [[AgoraRtcChannelMediaOptions alloc] init];
    opts.publishCameraTrack     = self.localMediaEnabled;
    opts.publishMicrophoneTrack = self.localMediaEnabled;
    [self.rtcEngine updateChannelWithMediaOptions:opts];
    NSLog(@"[RTC] updateChannelWithMediaOptions: camera=%d, mic=%d", self.localMediaEnabled, self.localMediaEnabled);

    // 更新按钮标题
    UIButton *btn = [self.floatingMenu viewWithTag:103];
    NSString *title = self.localMediaEnabled ? @"传输音视频" : @"已关闭音视频";
    NSString *icon  = self.localMediaEnabled ? @"video" : @"video.slash";
    [btn setTitle:title forState:UIControlStateNormal];
    UIImageSymbolConfiguration *imgConfig = [UIImageSymbolConfiguration configurationWithPointSize:16];
    [btn setImage:[UIImage systemImageNamed:icon withConfiguration:imgConfig] forState:UIControlStateNormal];

    NSLog(@"[RTC] 本地音视频传输: %@", self.localMediaEnabled ? @"开启" : @"关闭");
    [self toggleFloatingMenu];
}

- (void)menuSwitchCamera {
    [self toggleFloatingMenu];
    [self.rtcEngine switchCamera];
    NSLog(@"[RTC] 切换摄像头");
}

- (void)appDidEnterBackground {
    NSLog(@"[App] 进入后台，发送 leave 并退出操控");
    // 向 RTM 频道发送 "leave"
    AgoraRtmPublishOptions *pubOptions = [[AgoraRtmPublishOptions alloc] init];
    [self.rtmClientKit publish:self.channelName message:@"leave" option:pubOptions completion:nil];

    [self.rtcEngine leaveChannel:nil];
    [self.rtmClientKit logout:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];

    // 回到输入密码界面
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)menuExitAction {
    [self toggleFloatingMenu];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                  message:@"确定退出吗？"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        // 向 RTM 频道发送 "leave"，不管是否成功都退出
        AgoraRtmPublishOptions *pubOptions = [[AgoraRtmPublishOptions alloc] init];
        [self.rtmClientKit publish:self.channelName message:@"leave" option:pubOptions completion:nil];

        [self.rtcEngine leaveChannel:nil];
        [self.rtmClientKit logout:nil];

        // 退出到输入密码页面（LoginViewController）
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Keyboard Text Input

- (void)setupHiddenTextField {
    _HiddenInputField *tf = [[_HiddenInputField alloc] initWithFrame:CGRectMake(0, -100, 1, 1)];
    tf.autocorrectionType      = UITextAutocorrectionTypeNo;
    tf.autocapitalizationType  = UITextAutocapitalizationTypeNone;
    tf.spellCheckingType       = UITextSpellCheckingTypeNo;
    tf.delegate = self;

    __weak typeof(self) weakSelf = self;
    tf.onDeleteBackward = ^{
        [weakSelf sendKeyEvent:kKeycodeDel];
    };

    self.hiddenTextField = tf;
    [self.view addSubview:tf];
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
    replacementString:(NSString *)string {
    if (string.length > 0) {
        [self sendTextContent:string];
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendKeyEvent:kKeycodeEnter];
    return NO;
}

#pragma mark - UI (unchanged)

- (UIView *)videoView {
    if (!_videoView) {
        _videoView = [[UIView alloc] init];
        _videoView.backgroundColor = [UIColor blackColor];
    }
    return _videoView;
}

- (UILabel *)progressLab {
    if (!_progressLab) {
        _progressLab = [[UILabel alloc] init];
        _progressLab.text = @"1%";
        _progressLab.font = [UIFont fontWithName:@"PingFangSC-Medium" size:21];
        _progressLab.textColor = UIColor.whiteColor;
    }
    return _progressLab;
}

- (void)setHaloLabel {
    if (self.haloLabel) return;
    CGFloat topY = self.view.safeAreaInsets.top + 56;
    CLHaloLabel *label = [[CLHaloLabel alloc]
                          initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 60, topY, 120, 33)];
    label.text          = @"正在接入中...";
    label.font          = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
    label.textColor     = [UIColor grayColor];
    label.haloColor     = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.haloWidth     = 0.5;
    label.haloDuration  = 3;
    [self.view addSubview:label];
    label.animated  = YES;
    self.haloLabel = label;
}

- (void)animateProgressLabel {
    self.startValue = 1;
    self.endValue   = 99;
    self.duration   = 3.0;
    self.startTime  = CACurrentMediaTime();

    self.progressLink = [CADisplayLink displayLinkWithTarget:self
                                                    selector:@selector(updateProgressLabel)];
    [self.progressLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)updateProgressLabel {
    CFTimeInterval now      = CACurrentMediaTime();
    CGFloat        progress = MIN(1, (now - self.startTime) / self.duration);
    NSInteger      current  = self.startValue + (self.endValue - self.startValue) * progress;
    self.progressLab.text   = [NSString stringWithFormat:@"%ld%%", (long)current];

    if (progress >= 1.0) {
        [self.progressLink invalidate];
        self.progressLink = nil;
    }
}

@end
