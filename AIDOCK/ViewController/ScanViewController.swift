import UIKit
import AVFoundation
import Vision
import QMUIKit

@objc class ScanViewController: UIViewController {

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlayView = ScannerOverlayView()
    private let topTitle = UILabel()
    private let selectImageBtn = UIButton(type: .custom)
    private var isProcessing = false

    private let LOGINTOKEN = "userLoginToken"
    private let USERID = "userID"

    @objc init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async { self.captureSession?.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - UI

    private func setupBaseUI() {
        view.backgroundColor = .black

        overlayView.isUserInteractionEnabled = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        topTitle.text = "将二维码放入框内，即可自动扫描"
        topTitle.textColor = .white
        topTitle.font = .systemFont(ofSize: 12)
        topTitle.textAlignment = .center
        topTitle.numberOfLines = 0
        topTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topTitle)

        selectImageBtn.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        selectImageBtn.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        selectImageBtn.tintColor = .white
        selectImageBtn.layer.cornerRadius = 35
        selectImageBtn.clipsToBounds = true
        selectImageBtn.addTarget(self, action: #selector(selectImageBtnClick), for: .touchUpInside)
        selectImageBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectImageBtn)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leftAnchor.constraint(equalTo: view.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topTitle.bottomAnchor.constraint(equalTo: selectImageBtn.topAnchor, constant: -40),
            topTitle.widthAnchor.constraint(equalToConstant: 200),
            topTitle.heightAnchor.constraint(equalToConstant: 60),

            selectImageBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectImageBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120),
            selectImageBtn.widthAnchor.constraint(equalToConstant: 70),
            selectImageBtn.heightAnchor.constraint(equalToConstant: 70)
        ])
    }

    // MARK: - Camera (AVFoundation)

    private func setupCamera() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.configureCaptureSession()
                } else {
                    QMUITips.showError("需要相机权限", in: self?.view ?? UIView())
                }
            }
        }
    }

    private func configureCaptureSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        let session = AVCaptureSession()
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        captureSession = session
        DispatchQueue.global(qos: .background).async { session.startRunning() }

        overlayView.startAnimation()
    }

    // MARK: - Actions

    @objc private func selectImageBtnClick() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    // MARK: - Business Logic

    private func handleScanResult(_ result: String) {
        guard !isProcessing else { return }
        isProcessing = true
        captureSession?.stopRunning()
        bindDevice(with: result)
    }

    private func bindDevice(with string: String) {
        NetworkManager.shared().post("/auth/login",
                                    parameters: ["qrcode": string],
                                    headers: nil,
                                    success: { [weak self] response in
            if let dict = response as? [String: Any] {
                self?.processData(with: dict)
            }
        }, failure: { [weak self] error in
            print("失败: \(error.localizedDescription)")
            self?.isProcessing = false
            DispatchQueue.global(qos: .background).async { self?.captureSession?.startRunning() }
        })
    }

    private func processData(with object: [String: Any]) {
        let code = (object["code"] as? NSNumber)?.intValue ?? -1
        let message = object["message"] as? String ?? "未知错误"

        switch code {
        case 0:
            if let data = object["data"] as? [String: Any] {
                let token = data["token"] as? String ?? ""
                let userId = data["user_id"].map { "\($0)" } ?? ""
                UserDefaults.standard.set(token, forKey: LOGINTOKEN)
                UserDefaults.standard.set(userId, forKey: USERID)
                jumpToLoginVC()
            } else {
                QMUITips.showError("数据解析失败")
                isProcessing = false
            }
        default:
            QMUITips.showError(message, in: view)
            isProcessing = false
            DispatchQueue.global(qos: .background).async { self.captureSession?.startRunning() }
        }
    }

    private func jumpToLoginVC() {
        let vc = LoginViewController()
        if let nav = presentingViewController as? UINavigationController {
            dismiss(animated: false) { nav.pushViewController(vc, animated: false) }
        } else {
            dismiss(animated: false)
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension ScanViewController: @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let value = obj.stringValue {
            handleScanResult(value)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage,
              let cgImage = image.cgImage else { return }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectBarcodesRequest { [weak self] req, _ in
            guard let result = (req.results as? [VNBarcodeObservation])?.first?.payloadStringValue else {
                DispatchQueue.main.async {
                    if let v = self?.view { QMUITips.showError("识别失败", in: v) }
                }
                return
            }
            DispatchQueue.main.async { self?.handleScanResult(result) }
        }
        request.symbologies = [.qr]
        try? handler.perform([request])
    }
}

// MARK: - ScannerOverlayView

class ScannerOverlayView: UIView {
    private let scanLine = UIView()
    private var scanRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        scanLine.backgroundColor = .systemBlue
        addSubview(scanLine)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        ctx.fill(rect)

        let size = rect.width * 0.7
        let sr = CGRect(x: (rect.width - size) / 2,
                        y: (rect.height - size) / 2 - 50,
                        width: size, height: size)

        ctx.setBlendMode(.clear)
        ctx.fill(sr)
        ctx.setBlendMode(.normal)

        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(sr)

        let cl: CGFloat = 20
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineWidth(4)
        // 左上
        ctx.move(to: CGPoint(x: sr.minX, y: sr.minY + cl)); ctx.addLine(to: CGPoint(x: sr.minX, y: sr.minY)); ctx.addLine(to: CGPoint(x: sr.minX + cl, y: sr.minY))
        // 右上
        ctx.move(to: CGPoint(x: sr.maxX - cl, y: sr.minY)); ctx.addLine(to: CGPoint(x: sr.maxX, y: sr.minY)); ctx.addLine(to: CGPoint(x: sr.maxX, y: sr.minY + cl))
        // 左下
        ctx.move(to: CGPoint(x: sr.minX, y: sr.maxY - cl)); ctx.addLine(to: CGPoint(x: sr.minX, y: sr.maxY)); ctx.addLine(to: CGPoint(x: sr.minX + cl, y: sr.maxY))
        // 右下
        ctx.move(to: CGPoint(x: sr.maxX - cl, y: sr.maxY)); ctx.addLine(to: CGPoint(x: sr.maxX, y: sr.maxY)); ctx.addLine(to: CGPoint(x: sr.maxX, y: sr.maxY - cl))
        ctx.strokePath()

        scanRect = sr
    }

    func startAnimation() {
        let size = bounds.width * 0.7
        let rect = CGRect(x: (bounds.width - size) / 2,
                          y: (bounds.height - size) / 2 - 50,
                          width: size, height: 2)
        scanLine.frame = rect
        scanLine.alpha = 1
        UIView.animate(withDuration: 2.0, delay: 0,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.scanLine.frame.origin.y = rect.origin.y + size
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
}
