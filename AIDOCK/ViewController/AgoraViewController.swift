import UIKit
import AVFoundation
import AgoraRtcKit

// TODO: 替换为你的声网 App ID
private let kAgoraAppID = "affc86ea95464161b4de63b02bb18f04"
private let kAgoraToken = "007eJxTYHj8oF47p+eHA4eEy5Q+c43KRfGt21jXiWusba+qTjioxKfAkJiWlmxhlppoaWpiZmJoZphkkpJqZpxkYJSUZGiRZmDy0HBnZkMgI8NC4QomRgYIBPHZGAyNjE1MzRgYAP6uHRQ="

@objc class AgoraViewController: UIViewController {

    private var agoraKit: AgoraRtcEngineKit?
    private let channelId: String

    private let localView = UIView()
    private let leaveBtn = UIButton(type: .custom)
    private let channelLabel = UILabel()

    @objc init(channelId: String) {
        self.channelId = channelId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        requestPermissions { [weak self] granted in
            DispatchQueue.main.async {
                granted ? self?.initAgora() : self?.showPermissionAlert()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        agoraKit?.stopPreview()
        agoraKit?.leaveChannel()
        AgoraRtcEngineKit.destroy()
        agoraKit = nil
    }

    // MARK: - UI

    private func setupUI() {
        // 本地视频全屏
        localView.backgroundColor = .black
        localView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(localView)

        // 房间标签
        channelLabel.text = "房间：\(channelId)"
        channelLabel.textColor = .white
        channelLabel.font = .systemFont(ofSize: 14)
        channelLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(channelLabel)

        // 离开按钮
        leaveBtn.setTitle("离开", for: .normal)
        leaveBtn.setTitleColor(.white, for: .normal)
        leaveBtn.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
        leaveBtn.layer.cornerRadius = 25
        leaveBtn.clipsToBounds = true
        leaveBtn.translatesAutoresizingMaskIntoConstraints = false
        leaveBtn.addTarget(self, action: #selector(leaveTapped), for: .touchUpInside)
        view.addSubview(leaveBtn)

        NSLayoutConstraint.activate([
            localView.topAnchor.constraint(equalTo: view.topAnchor),
            localView.leftAnchor.constraint(equalTo: view.leftAnchor),
            localView.rightAnchor.constraint(equalTo: view.rightAnchor),
            localView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            channelLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            channelLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),

            leaveBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            leaveBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            leaveBtn.widthAnchor.constraint(equalToConstant: 100),
            leaveBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Agora

    private func initAgora() {
        let config = AgoraRtcEngineConfig()
        config.appId = kAgoraAppID
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)

        // 视频编码：H264 / 30fps / 宽 480
        let encoderConfig = AgoraVideoEncoderConfiguration()
        encoderConfig.dimensions = CGSize(width: 480, height: 640)
        encoderConfig.frameRate = AgoraVideoFrameRate.fps30.rawValue
        encoderConfig.codecType = .H264
        encoderConfig.orientationMode = .adaptative
        agoraKit?.setVideoEncoderConfiguration(encoderConfig)

        agoraKit?.enableVideo()
        agoraKit?.enableAudio()

        // 本地预览
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = 0
        canvas.view = localView
        canvas.renderMode = .hidden
        agoraKit?.setupLocalVideo(canvas)
        agoraKit?.startPreview()

        // 加入频道（主播角色，发布摄像头 + 麦克风）
        let options = AgoraRtcChannelMediaOptions()
        options.channelProfile = .liveBroadcasting
        options.clientRoleType = .broadcaster
        options.publishCameraTrack = true
        options.publishMicrophoneTrack = true
        options.autoSubscribeVideo = true
        options.autoSubscribeAudio = true

        let ret = agoraKit?.joinChannel(byToken: kAgoraToken,
                                        channelId: channelId,
                                        uid: 0,
                                        mediaOptions: options)
        if let ret, ret != 0 {
            print("joinChannel failed: \(ret)")
        }
    }

    // MARK: - Permissions

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { videoOK in
            AVCaptureDevice.requestAccess(for: .audio) { audioOK in
                completion(videoOK && audioOK)
            }
        }
    }

    private func showPermissionAlert() {
        let alert = UIAlertController(title: "需要权限",
                                      message: "请在「设置」中开启相机和麦克风权限",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func leaveTapped() {
        agoraKit?.stopPreview()
        agoraKit?.leaveChannel()
        AgoraRtcEngineKit.destroy()
        agoraKit = nil
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - AgoraRtcEngineDelegate

extension AgoraViewController: @preconcurrency AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        print("[Agora] 本地已加入房间 \(channel)，uid=\(uid)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinedOfUid uid: UInt,
                   elapsed: Int) {
        print("[Agora] 远端用户 \(uid) 加入")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOfflineOfUid uid: UInt,
                   reason: AgoraUserOfflineReason) {
        print("[Agora] 远端用户 \(uid) 离线")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOccurError errorCode: AgoraErrorCode) {
        print("[Agora] 错误码: \(errorCode.rawValue)")
    }
}
